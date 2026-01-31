// lib/services/model_3d_service.dart
// Downloads 3D models from Firebase Storage via plain HTTP and caches locally.
// No Firebase SDK required.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class Model3DService {
  static final Model3DService instance = Model3DService._();
  Model3DService._();

  /// Firebase Storage download URLs for each model.
  /// Replace with your actual Firebase Storage URLs after uploading.
  static const Map<String, String> modelUrls = {
    'uterus':
        'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_models_1.glb?alt=media&token=fcf140dd-c35d-4bde-9ade-4cf743b10653',
  };

  /// Returns the local cache directory for 3D models.
  Future<Directory> get _cacheDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/models_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns the local file path for a cached model.
  Future<File> _localFile(String modelName) async {
    final dir = await _cacheDir;
    return File('${dir.path}/$modelName.glb');
  }

  /// Check if a model is already cached locally.
  Future<bool> isCached(String modelName) async {
    final file = await _localFile(modelName);
    return file.exists();
  }

  /// Get the local file path for a model. Returns null if not cached.
  Future<String?> getCachedModelPath(String modelName) async {
    final file = await _localFile(modelName);
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  /// Download a model from Firebase Storage with progress reporting.
  ///
  /// [onProgress] receives values from 0.0 to 1.0.
  /// Returns the local file path on success, or throws on failure.
  Future<String> downloadModel(
    String modelName, {
    ValueChanged<double>? onProgress,
  }) async {
    final url = modelUrls[modelName];
    if (url == null) {
      throw Exception('No download URL configured for model: $modelName');
    }

    // Check cache first
    final cachedPath = await getCachedModelPath(modelName);
    if (cachedPath != null) {
      onProgress?.call(1.0);
      return cachedPath;
    }

    // Download via plain HTTP
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download model "$modelName": HTTP ${response.statusCode}',
      );
    }

    final contentLength = response.contentLength ?? 0;
    final file = await _localFile(modelName);
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
  }

  /// Delete a cached model.
  Future<void> clearCache(String modelName) async {
    final file = await _localFile(modelName);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Delete all cached models.
  Future<void> clearAllCache() async {
    final dir = await _cacheDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
