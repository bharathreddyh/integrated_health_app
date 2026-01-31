// lib/screens/model_viewer_screen.dart
// Displays a 3D .glb model downloaded from Firebase Storage.
// Shows a progress bar on first download; loads from cache afterwards.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
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
                await _service.clearCache(widget.modelName);
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
    // model_viewer_plus accepts a file:// URI for local files
    final fileUri = 'file://$_localPath';

    return ModelViewer(
      src: fileUri,
      alt: widget.title,
      autoRotate: true,
      cameraControls: true,
      disableZoom: false,
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
