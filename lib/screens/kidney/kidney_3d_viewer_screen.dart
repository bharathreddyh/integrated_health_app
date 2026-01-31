import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Kidney3DViewerScreen extends StatelessWidget {
  const Kidney3DViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Kidney Model'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: ModelViewer(
        src: 'assets/models/kidney.glb',
        alt: '3D model of a kidney',
        ar: true,
        autoRotate: true,
        autoRotateDelay: 0,
        rotationPerSecond: '30deg',
        cameraControls: true,
        disableZoom: false,
        backgroundColor: const Color(0xFFF0F0F0),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('3D Kidney Model'),
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
