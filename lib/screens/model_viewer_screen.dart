// lib/screens/model_viewer_screen.dart
// Displays a 3D .glb model using Google's <model-viewer> web component
// via webview_flutter with a local HTTP server to serve the file.
// Includes a drawing overlay for annotation on the 3D model.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/model_3d_service.dart';

class ModelViewerScreen extends StatefulWidget {
  final String modelName;
  final String title;
  final String systemId;

  const ModelViewerScreen({
    super.key,
    required this.modelName,
    required this.title,
    this.systemId = 'general',
  });

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  final _service = Model3DService.instance;
  final _repaintKey = GlobalKey();
  final _captureKey = GlobalKey();

  _LoadState _state = _LoadState.loading;
  double _progress = 0.0;
  String? _localPath;
  String? _error;
  WebViewController? _webController;
  HttpServer? _server;

  // Drawing state
  bool _drawMode = false;
  Color _drawColor = Colors.red;
  double _strokeWidth = 3.0;
  List<_DrawingStroke> _strokes = [];
  _DrawingStroke? _currentStroke;

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
      setState(() => _webController = controller);
    }
  }

  void _toggleDrawMode() {
    setState(() {
      _drawMode = !_drawMode;
    });
    // Disable/enable camera-controls and auto-rotate in WebView
    if (_drawMode) {
      _webController?.runJavaScript(
        "var mv = document.querySelector('model-viewer');"
        "mv.removeAttribute('camera-controls');"
        "mv.removeAttribute('auto-rotate');",
      );
    } else {
      _webController?.runJavaScript(
        "var mv = document.querySelector('model-viewer');"
        "mv.setAttribute('camera-controls', '');"
        "mv.setAttribute('auto-rotate', '');",
      );
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
    }
  }

  void _clearDrawings() {
    if (_strokes.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Drawings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _strokes.clear());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveScreenshot() async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      if (!mounted) return;

      // Ask user for a name
      final nameController = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save Annotation'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Fibroid anterior wall',
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (val) => Navigator.pop(ctx, val.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      nameController.dispose();

      if (name == null) return; // cancelled

      final baseDir = await _service.getCacheDirectory();
      final systemDir = Directory('$baseDir/annotations/${widget.systemId}');
      if (!await systemDir.exists()) {
        await systemDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = name.isEmpty
          ? '3d_annotation_$timestamp'
          : '${name.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_')}_$timestamp';
      final file = File('${systemDir.path}/$safeName.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: ${name.isEmpty ? 'annotation' : name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewSavedImages() async {
    final baseDir = await _service.getCacheDirectory();
    final dir = Directory('$baseDir/annotations/${widget.systemId}');
    if (!await dir.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved images yet')),
        );
      }
      return;
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // newest first

    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved images yet')),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.photo_library, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Saved Annotations (${files.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  final name = file.path.split('/').last;
                  return GestureDetector(
                    onTap: () => _showFullImage(ctx, file),
                    onLongPress: () => _confirmDeleteImage(ctx, file),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(file, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Tap to view  |  Long press to delete',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext parentCtx, File file) {
    showDialog(
      context: parentCtx,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Annotation', style: TextStyle(fontSize: 16)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.file(file),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteImage(BuildContext parentCtx, File file) {
    showDialog(
      context: parentCtx,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // close confirm dialog
              Navigator.pop(parentCtx); // close gallery
              await file.delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Image deleted'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
          if (_state == _LoadState.ready) ...[
            // Draw mode toggle
            IconButton(
              icon: Icon(
                _drawMode ? Icons.draw : Icons.draw_outlined,
                color: _drawMode ? Colors.blue : null,
              ),
              tooltip: _drawMode ? 'Exit draw mode' : 'Draw on model',
              onPressed: _toggleDrawMode,
            ),
            if (_drawMode) ...[
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: _strokes.isNotEmpty ? _undo : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear all',
                onPressed: _strokes.isNotEmpty ? _clearDrawings : null,
              ),
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save screenshot',
                onPressed: _saveScreenshot,
              ),
            ],
            if (!_drawMode) ...[
              IconButton(
                icon: const Icon(Icons.photo_library_outlined),
                tooltip: 'Saved images',
                onPressed: _viewSavedImages,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Re-download model',
                onPressed: () async {
                  await _service.clearAssetCache(widget.modelName);
                  _loadModel();
                },
              ),
            ],
          ],
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _drawMode ? _buildDrawToolbar() : null,
    );
  }

  Widget _buildDrawToolbar() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.white,
      Colors.black,
    ];
    final widths = [2.0, 3.0, 5.0, 8.0];

    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Color picker
            const Text('Color', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(width: 8),
            ...colors.map((c) => GestureDetector(
                  onTap: () => setState(() => _drawColor = c),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _drawColor == c ? Colors.white : Colors.white30,
                        width: _drawColor == c ? 2.5 : 1,
                      ),
                    ),
                  ),
                )),
            const SizedBox(width: 20),
            // Stroke width
            const Text('Size', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(width: 8),
            ...widths.map((w) => GestureDetector(
                  onTap: () => setState(() => _strokeWidth = w),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _strokeWidth == w ? Colors.white24 : Colors.transparent,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Center(
                      child: Container(
                        width: w + 2,
                        height: w + 2,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
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
            Text('Downloading 3D Model...', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            const SizedBox(height: 8),
            Text(
              _progress > 0 ? '${(_progress * 100).toStringAsFixed(0)}%' : 'Connecting...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _zoomIn() {
    _webController?.runJavaScript('''
      var mv = document.querySelector('model-viewer');
      var orbit = mv.getCameraOrbit();
      orbit.radius = Math.max(orbit.radius * 0.8, 0.5);
      mv.cameraOrbit = orbit.toString();
    ''');
  }

  void _zoomOut() {
    _webController?.runJavaScript('''
      var mv = document.querySelector('model-viewer');
      var orbit = mv.getCameraOrbit();
      orbit.radius = Math.min(orbit.radius * 1.25, 20);
      mv.cameraOrbit = orbit.toString();
    ''');
  }

  void _resetView() {
    _webController?.runJavaScript('''
      var mv = document.querySelector('model-viewer');
      mv.cameraOrbit = 'auto auto auto';
      mv.cameraTarget = 'auto auto auto';
      mv.fieldOfView = 'auto';
    ''');
  }

  Widget _buildViewer() {
    if (_webController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RepaintBoundary(
      key: _captureKey,
      child: Stack(
        children: [
          // 3D WebView
          WebViewWidget(
            controller: _webController!,
            gestureRecognizers: _drawMode
                ? {} // No gestures pass to WebView in draw mode
                : <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                  },
          ),
          // Drawing overlay
          if (_drawMode)
            Positioned.fill(
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentStroke = _DrawingStroke(
                      color: _drawColor,
                      width: _strokeWidth,
                      points: [details.localPosition],
                    );
                  });
                },
                onPanUpdate: (details) {
                  if (_currentStroke != null) {
                    setState(() {
                      _currentStroke!.points.add(details.localPosition);
                    });
                  }
                },
                onPanEnd: (_) {
                  if (_currentStroke != null) {
                    setState(() {
                      _strokes.add(_currentStroke!);
                      _currentStroke = null;
                    });
                  }
                },
                child: CustomPaint(
                  painter: _DrawingPainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          // Draw mode indicator - tappable to exit
          if (_drawMode)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _toggleDrawMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Drawing Mode ON',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '| Tap to unlock camera',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Existing drawings shown even when not in draw mode
          if (!_drawMode && _strokes.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DrawingPainter(strokes: _strokes),
                  size: Size.infinite,
                ),
              ),
            ),
          // Zoom controls - only show when not in draw mode
          if (!_drawMode)
            Positioned(
              right: 16,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom In
                  _buildZoomButton(
                    icon: Icons.add,
                    onPressed: _zoomIn,
                    tooltip: 'Zoom in',
                  ),
                  const SizedBox(height: 8),
                  // Reset View
                  _buildZoomButton(
                    icon: Icons.crop_free,
                    onPressed: _resetView,
                    tooltip: 'Reset view',
                    isSmall: true,
                  ),
                  const SizedBox(height: 8),
                  // Zoom Out
                  _buildZoomButton(
                    icon: Icons.remove,
                    onPressed: _zoomOut,
                    tooltip: 'Zoom out',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isSmall = false,
  }) {
    final size = isSmall ? 40.0 : 48.0;
    final iconSize = isSmall ? 20.0 : 24.0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
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
            Text('Failed to load model', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red[700]),
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

class _DrawingStroke {
  final Color color;
  final double width;
  final List<Offset> points;

  _DrawingStroke({
    required this.color,
    required this.width,
    required this.points,
  });
}

class _DrawingPainter extends CustomPainter {
  final List<_DrawingStroke> strokes;
  final _DrawingStroke? currentStroke;

  _DrawingPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }
  }

  void _paintStroke(Canvas canvas, _DrawingStroke stroke) {
    if (stroke.points.length < 2) return;
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
