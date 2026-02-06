// lib/services/model_3d_service.dart
// Downloads 3D models and assets from Firebase Storage via plain HTTP.
// Caches to app-scoped directory (auto-deleted on uninstall).
// No Firebase SDK required.

import 'package:flutter/material.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Metadata for a single downloadable asset.
class AssetInfo {
  final String id;
  final String name;
  final String systemId;
  final String url;
  final int sizeBytes; // approximate size in bytes
  final String fileExtension;

  const AssetInfo({
    required this.id,
    required this.name,
    required this.systemId,
    required this.url,
    required this.sizeBytes,
    this.fileExtension = 'glb',
  });
}

/// A medical system with its downloadable assets.
class SystemAssetGroup {
  final String systemId;
  final String name;
  final String description;
  final int colorValue;
  final IconData icon;
  final List<AssetInfo> assets;

  const SystemAssetGroup({
    required this.systemId,
    required this.name,
    required this.description,
    required this.colorValue,
    required this.icon,
    required this.assets,
  });

  /// Total download size for this system in bytes.
  int get totalSizeBytes => assets.fold(0, (sum, a) => sum + a.sizeBytes);

  /// Human-readable size string.
  String get formattedSize {
    final mb = totalSizeBytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    final kb = totalSizeBytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }
}

class Model3DService {
  static final Model3DService instance = Model3DService._();
  Model3DService._();

  static const _prefKeySetupDone = 'asset_download_setup_done';

  // ─── Asset Registry ────────────────────────────────────────────────
  // Add new assets here. Sizes are approximate (used for UI display).
  // After uploading a file to Firebase Storage > models/ folder,
  // paste the download URL below.

  static const List<SystemAssetGroup> systemAssets = [
    SystemAssetGroup(
      systemId: 'gynaecology',
      name: 'Gynaecology',
      description: '3D models: Uterus, Fibroids, Ovarian cysts, PCOS',
      colorValue: 0xFFEC4899,
      icon: Icons.favorite,
      assets: [
        AssetInfo(
          id: 'uterus',
          name: '3D Uterus (Normal)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_models_1.glb?alt=media&token=fcf140dd-c35d-4bde-9ade-4cf743b10653',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        // More models will be added here as they become available:
        // fibroid_intramural, fibroid_submucosal, fibroid_subserosal, etc.
      ],
    ),
    SystemAssetGroup(
      systemId: 'endocrine',
      name: 'Endocrine System',
      description: '3D models: Thyroid, Pituitary, Adrenal',
      colorValue: 0xFFEC4899,
      icon: Icons.science,
      assets: [
        // Add assets here when available
        // AssetInfo(id: 'thyroid', name: '3D Thyroid', ...),
      ],
    ),
    SystemAssetGroup(
      systemId: 'renal',
      name: 'Renal System',
      description: '3D models: Kidney, Nephron',
      colorValue: 0xFF3B82F6,
      icon: Icons.water_drop,
      assets: [
        // Add assets here when available
      ],
    ),
    SystemAssetGroup(
      systemId: 'cardiovascular',
      name: 'Cardiovascular System',
      description: '3D models: Heart, Vessels',
      colorValue: 0xFFEF4444,
      icon: Icons.favorite,
      assets: [
        // Add assets here when available
      ],
    ),
    SystemAssetGroup(
      systemId: 'respiratory',
      name: 'Respiratory System',
      description: '3D models: Lungs, Airways',
      colorValue: 0xFF10B981,
      icon: Icons.air,
      assets: [
        // Add assets here when available
      ],
    ),
    SystemAssetGroup(
      systemId: 'hepatobiliary',
      name: 'Hepatobiliary System',
      description: '3D models: Liver, Gallbladder',
      colorValue: 0xFFF59E0B,
      icon: Icons.local_hospital,
      assets: [
        // Add assets here when available
      ],
    ),
    SystemAssetGroup(
      systemId: 'neurological',
      name: 'Neurological System',
      description: '3D models: Brain, Nerves',
      colorValue: 0xFF6366F1,
      icon: Icons.psychology,
      assets: [
        // Add assets here when available
      ],
    ),
    SystemAssetGroup(
      systemId: 'musculoskeletal',
      name: 'Musculoskeletal System',
      description: '3D models: Bones, Joints',
      colorValue: 0xFFA855F7,
      icon: Icons.accessibility_new,
      assets: [
        // Add assets here when available
      ],
    ),
  ];

  /// Systems that actually have assets to download.
  static List<SystemAssetGroup> get availableSystems =>
      systemAssets.where((s) => s.assets.isNotEmpty).toList();

  /// All downloadable assets across all systems.
  static List<AssetInfo> get allAssets =>
      systemAssets.expand((s) => s.assets).toList();

  // ─── First-launch check ────────────────────────────────────────────

  /// Returns true if the user has already been through the download setup.
  static Future<bool> isSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeySetupDone) ?? false;
  }

  /// Mark the download setup as completed (user can skip or finish).
  static Future<void> markSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeySetupDone, true);
  }

  // ─── Cache directory (app-scoped, deleted on uninstall) ────────────

  Future<String> getCacheDirectory() async {
    final dir = await _cacheDir;
    return dir.path;
  }

  Future<Directory> get _cacheDir async {
    // getApplicationSupportDirectory is app-scoped on both Android & iOS
    // and is automatically deleted when the app is uninstalled.
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory('${appDir.path}/models_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _localFile(String assetId, String extension) async {
    final dir = await _cacheDir;
    return File('${dir.path}/$assetId.$extension');
  }

  // ─── Cache queries ─────────────────────────────────────────────────

  Future<bool> isCached(String assetId, {String ext = 'glb'}) async {
    final file = await _localFile(assetId, ext);
    return file.exists();
  }

  Future<String?> getCachedPath(String assetId, {String ext = 'glb'}) async {
    final file = await _localFile(assetId, ext);
    if (await file.exists()) return file.path;
    return null;
  }

  /// Check which assets in a system are already downloaded.
  Future<Map<String, bool>> getSystemCacheStatus(String systemId) async {
    final group = systemAssets.firstWhere((s) => s.systemId == systemId);
    final result = <String, bool>{};
    for (final asset in group.assets) {
      result[asset.id] = await isCached(asset.id, ext: asset.fileExtension);
    }
    return result;
  }

  /// Total cached size on disk (in bytes).
  Future<int> getCachedSizeBytes() async {
    final dir = await _cacheDir;
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  // ─── Download ──────────────────────────────────────────────────────

  /// Download a single asset with progress reporting.
  /// [onProgress] receives values from 0.0 to 1.0.
  Future<String> downloadAsset(
    AssetInfo asset, {
    ValueChanged<double>? onProgress,
  }) async {
    // Check cache first
    final cached = await getCachedPath(asset.id, ext: asset.fileExtension);
    if (cached != null) {
      onProgress?.call(1.0);
      return cached;
    }

    final request = http.Request('GET', Uri.parse(asset.url));
    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'Download failed for "${asset.name}": HTTP ${response.statusCode}',
        );
      }

      final contentLength = response.contentLength ?? 0;
      final file = await _localFile(asset.id, asset.fileExtension);
      final sink = file.openWrite();

      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress?.call(received / contentLength);
        }
      }

      await sink.close();
      return file.path;
    } finally {
      client.close();
    }
  }

  /// Download all assets for a given system.
  /// [onProgress] receives overall progress 0.0 to 1.0.
  Future<void> downloadSystem(
    String systemId, {
    ValueChanged<double>? onProgress,
  }) async {
    final group = systemAssets.firstWhere((s) => s.systemId == systemId);
    if (group.assets.isEmpty) return;

    for (int i = 0; i < group.assets.length; i++) {
      await downloadAsset(
        group.assets[i],
        onProgress: (p) {
          final overall = (i + p) / group.assets.length;
          onProgress?.call(overall);
        },
      );
    }
    onProgress?.call(1.0);
  }

  // ─── Legacy helper (for ModelViewerScreen compatibility) ───────────

  /// Download a model by name. Falls back to 'uterus' if model not found.
  Future<String> downloadModel(
    String modelName, {
    ValueChanged<double>? onProgress,
  }) async {
    AssetInfo? asset;
    try {
      asset = allAssets.firstWhere((a) => a.id == modelName);
    } catch (_) {
      // Model not registered - fallback to uterus as placeholder
      asset = allAssets.firstWhere(
        (a) => a.id == 'uterus',
        orElse: () => throw Exception('No fallback model available'),
      );
    }
    return downloadAsset(asset, onProgress: onProgress);
  }

  // ─── Cache management ──────────────────────────────────────────────

  Future<void> clearAssetCache(String assetId, {String ext = 'glb'}) async {
    final file = await _localFile(assetId, ext);
    if (await file.exists()) await file.delete();
  }

  Future<void> clearSystemCache(String systemId) async {
    final group = systemAssets.firstWhere((s) => s.systemId == systemId);
    for (final asset in group.assets) {
      await clearAssetCache(asset.id, ext: asset.fileExtension);
    }
  }

  Future<void> clearAllCache() async {
    final dir = await _cacheDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
