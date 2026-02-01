// lib/screens/model_viewer_screen.dart
// Displays a 3D .glb model using Google's <model-viewer> web component
// via webview_flutter with a local HTTP server to serve the file.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/model_3d_service.dart';

class ModelViewerScreen extends StatefulWidget {
  final String modelName;
  final String title;

  const ModelViewerScreen({
    super.key,
    required this.modelName,
    required this.title,
  });

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  final _service = Model3DService.instance;

  _LoadState _state = _LoadState.loading;
  double _progress = 0.0;
  String? _localPath;
  String? _error;
  WebViewController? _webController;
  HttpServer? _server;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  Future<void> _loadModel() async {
    setState(() {
      _state = _LoadState.loading;
      _progress = 0.0;
      _error = null;
    });

    try {
      final path = await _service.downloadModel(
        widget.modelName,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) {
        setState(() {
          _localPath = path;
          _state = _LoadState.ready;
        });
        await _initWebView(path);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _state = _LoadState.error;
        });
      }
    }
  }

  Future<void> _initWebView(String modelPath) async {
    // Start a local HTTP server to serve the .glb file
    // WebView can't access file:// URIs directly on Android
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
        request.response.write(_buildHtml(port));
        await request.response.close();
      } else {
        request.response.statusCode = 404;
        await request.response.close();
      }
    });

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF0F0F0))
      ..loadRequest(Uri.parse('http://127.0.0.1:$port/'));

    if (mounted) {
      setState(() {
        _webController = controller;
      });
    }
  }

  String _buildHtml(int port) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>
  <style>
    * { margin: 0; padding: 0; touch-action: none; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: #f0f0f0; }
    model-viewer {
      width: 100%;
      height: 100%;
      touch-action: none;
      --poster-color: transparent;
    }
    #loading {
      position: absolute;
      top: 50%; left: 50%;
      transform: translate(-50%, -50%);
      font-family: sans-serif;
      color: #666;
      font-size: 16px;
      z-index: 10;
    }
  </style>
</head>
<body>
  <div id="loading">Loading 3D model...</div>
  <model-viewer
    src="http://127.0.0.1:$port/model.glb"
    alt="${widget.title}"
    auto-rotate
    camera-controls
    disable-zoom="false"
    shadow-intensity="1"
    touch-action="none"
    interaction-prompt="auto"
    style="width:100%;height:100%;"
    loading="eager">
  </model-viewer>
  <script>
    document.querySelector('model-viewer').addEventListener('load', function() {
      document.getElementById('loading').style.display = 'none';
    });
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_state == _LoadState.ready)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Re-download model',
              onPressed: () async {
                await _service.clearAssetCache(widget.modelName);
                _loadModel();
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _LoadState.loading:
        return _buildLoading();
      case _LoadState.ready:
        return _buildViewer();
      case _LoadState.error:
        return _buildError();
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Downloading 3D Model...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            const SizedBox(height: 8),
            Text(
              _progress > 0
                  ? '${(_progress * 100).toStringAsFixed(0)}%'
                  : 'Connecting...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer() {
    if (_webController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return WebViewWidget(
      controller: _webController!,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load model',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadModel,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LoadState { loading, ready, error }
