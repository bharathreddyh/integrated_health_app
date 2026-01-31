// lib/screens/model_viewer_screen.dart
// Displays a 3D .glb model using Google's <model-viewer> web component
// via webview_flutter. No android_intent_plus dependency.

import 'dart:convert';
import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _loadModel();
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
        _initWebView(path);
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

  void _initWebView(String modelPath) {
    final fileUri = Uri.file(modelPath).toString();

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>
  <style>
    body { margin: 0; padding: 0; overflow: hidden; background: #f0f0f0; }
    model-viewer {
      width: 100vw;
      height: 100vh;
      --poster-color: transparent;
    }
  </style>
</head>
<body>
  <model-viewer
    src="$fileUri"
    alt="${widget.title}"
    auto-rotate
    camera-controls
    shadow-intensity="1"
    touch-action="pan-y"
    style="width:100%;height:100%;">
  </model-viewer>
</body>
</html>
''';

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF0F0F0))
      ..loadRequest(Uri.dataFromString(
        html,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ));
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
    return WebViewWidget(controller: _webController!);
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
