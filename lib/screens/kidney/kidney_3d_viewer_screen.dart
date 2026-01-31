import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../services/model_3d_service.dart';

class Uterus3DViewerScreen extends StatefulWidget {
  const Uterus3DViewerScreen({super.key});

  @override
  State<Uterus3DViewerScreen> createState() => _Uterus3DViewerScreenState();
}

class _Uterus3DViewerScreenState extends State<Uterus3DViewerScreen> {
  String? _modelPath;
  bool _loading = true;
  double _progress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() {
      _loading = true;
      _progress = 0.0;
      _error = null;
    });

    final path = await Model3DService.instance.downloadModelWithProgress(
      'uterus',
      onProgress: (progress) {
        if (mounted) {
          setState(() => _progress = progress);
        }
      },
    );

    if (mounted) {
      setState(() {
        _modelPath = path;
        _loading = false;
        if (path == null) {
          _error = 'Failed to load 3D model.\nCheck your Firebase URL in model_3d_service.dart';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Uterus Model'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.view_in_ar, size: 64, color: Colors.teal),
              const SizedBox(height: 24),
              const Text(
                'Downloading 3D Model...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: Colors.grey.shade200,
                color: Colors.teal,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _modelPath == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Model not available',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadModel,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ModelViewer(
      src: 'file://$_modelPath',
      alt: '3D model of a uterus',
      ar: true,
      autoRotate: true,
      autoRotateDelay: 0,
      rotationPerSecond: '30deg',
      cameraControls: true,
      disableZoom: false,
      backgroundColor: const Color(0xFFF0F0F0),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('3D Uterus Model'),
        content: const Text(
          'Use gestures to interact with the model:\n\n'
          '- Drag to rotate\n'
          '- Pinch to zoom\n'
          '- Two-finger drag to pan\n\n'
          'The model auto-rotates when idle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
