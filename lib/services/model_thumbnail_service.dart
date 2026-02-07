// lib/services/model_thumbnail_service.dart
// Service for generating and caching 3D model thumbnail images

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'model_3d_service.dart';

class ModelThumbnailService {
  static final ModelThumbnailService instance = ModelThumbnailService._();
  ModelThumbnailService._();

  // Cache directory for thumbnails
  Future<Directory> get _thumbnailDir async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory('${appDir.path}/model_thumbnails');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Get thumbnail file for a model
  Future<File> _thumbnailFile(String modelId) async {
    final dir = await _thumbnailDir;
    return File('${dir.path}/$modelId.png');
  }

  /// Check if a thumbnail exists for a model
  Future<bool> hasThumbnail(String modelId) async {
    final file = await _thumbnailFile(modelId);
    return file.exists();
  }

  /// Get the cached thumbnail path if it exists
  Future<String?> getThumbnailPath(String modelId) async {
    final file = await _thumbnailFile(modelId);
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  /// Check if the model file is downloaded (can show preview)
  Future<bool> isModelDownloaded(String modelId) async {
    return await Model3DService.instance.isCached(modelId);
  }

  /// Get the model file path if downloaded
  Future<String?> getModelPath(String modelId) async {
    return await Model3DService.instance.getCachedPath(modelId);
  }

  /// Save a thumbnail image for a model
  Future<void> saveThumbnail(String modelId, Uint8List imageBytes) async {
    final file = await _thumbnailFile(modelId);
    await file.writeAsBytes(imageBytes);
  }

  /// Delete thumbnail for a model
  Future<void> deleteThumbnail(String modelId) async {
    final file = await _thumbnailFile(modelId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clear all thumbnails
  Future<void> clearAllThumbnails() async {
    final dir = await _thumbnailDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
