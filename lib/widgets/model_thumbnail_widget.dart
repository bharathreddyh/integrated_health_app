// lib/widgets/model_thumbnail_widget.dart
// Widget that displays a 3D model thumbnail preview
// Shows live WebView preview if model is downloaded, otherwise placeholder

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/model_thumbnail_service.dart';

class ModelThumbnailWidget extends StatefulWidget {
  final String modelId;
  final Color accentColor;
  final double size;

  const ModelThumbnailWidget({
    super.key,
    required this.modelId,
    required this.accentColor,
    this.size = 80,
  });

  @override
  State<ModelThumbnailWidget> createState() => _ModelThumbnailWidgetState();
}

class _ModelThumbnailWidgetState extends State<ModelThumbnailWidget> {
  final _thumbnailService = ModelThumbnailService.instance;

  bool _isLoading = true;
  bool _isModelAvailable = false;
  String? _modelPath;
  WebViewController? _controller;
  HttpServer? _server;

  @override
  void initState() {
    super.initState();
    _checkModelAvailability();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  Future<void> _checkModelAvailability() async {
    final isDownloaded = await _thumbnailService.isModelDownloaded(widget.modelId);

    if (isDownloaded) {
      final path = await _thumbnailService.getModelPath(widget.modelId);
      if (mounted) {
        setState(() {
          _isModelAvailable = true;
          _modelPath = path;
          _isLoading = false;
        });
        if (path != null) {
          _initPreview(path);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isModelAvailable = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initPreview(String modelPath) async {
    _server?.close(force: true);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    final port = server.port;

    server.listen((request) async {
      if (request.uri.path == '/model.glb') {
        final file = File(modelPath);
        if (await file.exists()) {
          request.response.headers.set('Content-Type', 'model/gltf-binary');
          request.response.headers.set('Access-Control-Allow-Origin', '*');
          await request.response.addStream(file.openRead());
          await request.response.close();
        } else {
          request.response.statusCode = 404;
          await request.response.close();
        }
      } else if (request.uri.path == '/') {
        request.response.headers.set('Content-Type', 'text/html');
        request.response.write(_buildPreviewHtml(port));
        await request.response.close();
      } else {
        request.response.statusCode = 404;
        await request.response.close();
      }
    });

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E293B))
      ..loadRequest(Uri.parse('http://127.0.0.1:$port/'));

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  String _buildPreviewHtml(int port) {
    // Minimal HTML for thumbnail preview - no controls, just auto-rotate
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>
  <style>
    * { margin: 0; padding: 0; }
    html, body {
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: transparent;
    }
    model-viewer {
      width: 100%;
      height: 100%;
      --poster-color: transparent;
      background: transparent;
    }
  </style>
</head>
<body>
  <model-viewer
    src="http://127.0.0.1:$port/model.glb"
    auto-rotate
    rotation-per-second="30deg"
    disable-zoom
    disable-pan
    disable-tap
    interaction-prompt="none"
    camera-orbit="45deg 55deg 105%"
    style="width:100%;height:100%;pointer-events:none;">
  </model-viewer>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder(showLoading: true);
    }

    if (!_isModelAvailable || _controller == null) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IgnorePointer(
          child: WebViewWidget(
            controller: _controller!,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{},
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder({bool showLoading = false}) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: showLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(widget.accentColor.withOpacity(0.5)),
                ),
              )
            : Icon(
                Icons.view_in_ar_rounded,
                size: widget.size * 0.5,
                color: widget.accentColor,
              ),
      ),
    );
  }
}
