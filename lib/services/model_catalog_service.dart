// lib/services/model_catalog_service.dart
// Checks Firestore for newly uploaded 3D models so users get new content
// without an app update. Shows a prompt to download now or later.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model_3d_service.dart';

/// A model entry from the remote Firestore catalog.
class RemoteModelEntry {
  final String id;
  final String name;
  final String categoryId;
  final String subcategory;
  final String description;
  final String modelFileName;
  final String downloadUrl;
  final int sizeBytes;
  final List<String> tags;
  final bool isAnatomy;
  final DateTime addedAt;

  RemoteModelEntry({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.subcategory,
    required this.description,
    required this.modelFileName,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.tags,
    required this.isAnatomy,
    required this.addedAt,
  });

  factory RemoteModelEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RemoteModelEntry(
      id: doc.id,
      name: data['name'] ?? '',
      categoryId: data['categoryId'] ?? '',
      subcategory: data['subcategory'] ?? '',
      description: data['description'] ?? '',
      modelFileName: data['modelFileName'] ?? '',
      downloadUrl: data['downloadUrl'] ?? '',
      sizeBytes: data['sizeBytes'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      isAnatomy: data['isAnatomy'] ?? false,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'subcategory': subcategory,
    'description': description,
    'modelFileName': modelFileName,
    'downloadUrl': downloadUrl,
    'sizeBytes': sizeBytes,
    'tags': tags,
    'isAnatomy': isAnatomy,
    'addedAt': addedAt.toIso8601String(),
  };

  factory RemoteModelEntry.fromJson(Map<String, dynamic> json) {
    return RemoteModelEntry(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      categoryId: json['categoryId'] ?? '',
      subcategory: json['subcategory'] ?? '',
      description: json['description'] ?? '',
      modelFileName: json['modelFileName'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      sizeBytes: json['sizeBytes'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      isAnatomy: json['isAnatomy'] ?? false,
      addedAt: DateTime.tryParse(json['addedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convert to AssetInfo for downloading via Model3DService.
  AssetInfo toAssetInfo() => AssetInfo(
    id: modelFileName,
    name: name,
    systemId: categoryId,
    url: downloadUrl,
    sizeBytes: sizeBytes,
  );

  String get formattedSize {
    final mb = sizeBytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    final kb = sizeBytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }
}

class ModelCatalogService {
  static final ModelCatalogService instance = ModelCatalogService._();
  ModelCatalogService._();

  static const _prefKnownModelIds = 'known_remote_model_ids';
  static const _prefDismissedModelIds = 'dismissed_remote_model_ids';
  static const _prefRemoteCatalogCache = 'remote_catalog_cache';

  /// Fetch the full model catalog from Firestore.
  Future<List<RemoteModelEntry>> fetchRemoteCatalog() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('model_catalog')
          .orderBy('addedAt', descending: true)
          .get();

      final models = snapshot.docs
          .map((doc) => RemoteModelEntry.fromFirestore(doc))
          .toList();

      // Cache locally for offline access
      await _cacheCatalog(models);

      return models;
    } catch (e) {
      print('Failed to fetch remote catalog: $e');
      // Fall back to cached catalog
      return _getCachedCatalog();
    }
  }

  /// Check for new models that the user hasn't seen yet.
  /// Returns only the NEW models (not previously known or dismissed).
  Future<List<RemoteModelEntry>> checkForNewModels() async {
    final remoteModels = await fetchRemoteCatalog();
    if (remoteModels.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final knownIds = prefs.getStringList(_prefKnownModelIds) ?? [];
    final dismissedIds = prefs.getStringList(_prefDismissedModelIds) ?? [];
    final seenIds = {...knownIds, ...dismissedIds};

    final newModels = remoteModels
        .where((m) => !seenIds.contains(m.id))
        .toList();

    return newModels;
  }

  /// Mark models as "known" (user has seen the prompt).
  /// Called after user taps "Download Now" or "Later".
  Future<void> markModelsAsKnown(List<RemoteModelEntry> models) async {
    final prefs = await SharedPreferences.getInstance();
    final knownIds = prefs.getStringList(_prefKnownModelIds) ?? [];
    knownIds.addAll(models.map((m) => m.id));
    await prefs.setStringList(_prefKnownModelIds, knownIds.toSet().toList());
  }

  /// Mark models as dismissed (user chose "Later").
  Future<void> dismissModels(List<RemoteModelEntry> models) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedIds = prefs.getStringList(_prefDismissedModelIds) ?? [];
    dismissedIds.addAll(models.map((m) => m.id));
    await prefs.setStringList(_prefDismissedModelIds, dismissedIds.toSet().toList());
  }

  /// Get all remote models (cached), useful for merging with static config.
  Future<List<RemoteModelEntry>> getAllRemoteModels() async {
    return _getCachedCatalog();
  }

  // ─── Cache helpers ──────────────────────────────────────────────

  Future<void> _cacheCatalog(List<RemoteModelEntry> models) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = models.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_prefRemoteCatalogCache, jsonList);
  }

  Future<List<RemoteModelEntry>> _getCachedCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefRemoteCatalogCache) ?? [];
    return jsonList
        .map((s) => RemoteModelEntry.fromJson(jsonDecode(s)))
        .toList();
  }
}
