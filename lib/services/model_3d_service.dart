import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Model3DService {
  static final Model3DService instance = Model3DService._();
  Model3DService._();

  // ============================================================
  // CONFIGURE YOUR FIREBASE STORAGE URLs HERE
  // After uploading .glb files to Firebase Storage, paste the
  // download URLs below.
  // ============================================================
  static const Map<String, String> modelUrls = {
    'uterus': 'YOUR_FIREBASE_DOWNLOAD_URL_HERE',
    // Add more models as needed:
    // 'kidney': 'https://firebasestorage.googleapis.com/...',
  };

  /// Returns the local file path for a cached model.
  /// Downloads from Firebase on first access, serves from cache after that.
  Future<String?> getModelPath(String modelName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/models/$modelName.glb');

    if (await file.exists()) {
      return file.path;
    }

    final url = modelUrls[modelName];
    if (url == null || url == 'YOUR_FIREBASE_DOWNLOAD_URL_HERE') {
      return null;
    }

    return await _downloadModel(url, file);
  }

  /// Downloads a .glb file from the given URL and saves it locally.
  Future<String?> _downloadModel(String url, File file) async {
    try {
      await file.parent.create(recursive: true);

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await _consolidateResponse(response);
        await file.writeAsBytes(bytes);
        httpClient.close();
        return file.path;
      }

      httpClient.close();
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<int>> _consolidateResponse(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  /// Downloads with progress reporting.
  /// [onProgress] receives a value between 0.0 and 1.0.
  Future<String?> downloadModelWithProgress(
    String modelName, {
    required void Function(double progress) onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/models/$modelName.glb');

    if (await file.exists()) {
      onProgress(1.0);
      return file.path;
    }

    final url = modelUrls[modelName];
    if (url == null || url == 'YOUR_FIREBASE_DOWNLOAD_URL_HERE') {
      return null;
    }

    try {
      await file.parent.create(recursive: true);

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        httpClient.close();
        return null;
      }

      final totalBytes = response.contentLength;
      final bytes = <int>[];
      var receivedBytes = 0;

      await for (final chunk in response) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await file.writeAsBytes(bytes);
      httpClient.close();
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Check if a model is already cached locally.
  Future<bool> isModelCached(String modelName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/models/$modelName.glb');
    return file.exists();
  }

  /// Delete a cached model to free space.
  Future<void> deleteCache(String modelName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/models/$modelName.glb');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
