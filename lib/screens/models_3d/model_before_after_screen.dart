// lib/screens/models_3d/model_before_after_screen.dart
// Side-by-side before/after 3D model comparison screen
// Shows progression/growth of pathology (e.g., fibroid compression effects)

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/model_3d_config.dart';
import '../../services/model_3d_service.dart';

class ModelBeforeAfterScreen extends StatefulWidget {
  final Model3DItem model;
  final String systemId;

  const ModelBeforeAfterScreen({
    super.key,
    required this.model,
    required this.systemId,
  });

  @override
  State<ModelBeforeAfterScreen> createState() => _ModelBeforeAfterScreenState();
}

class _ModelBeforeAfterScreenState extends State<ModelBeforeAfterScreen> {
  final _service = Model3DService.instance;

  // Before model state
  _LoadState _beforeState = _LoadState.loading;
  double _beforeProgress = 0.0;
  WebViewController? _beforeController;
  HttpServer? _beforeServer;

  // After model state
  _LoadState _afterState = _LoadState.loading;
  double _afterProgress = 0.0;
  WebViewController? _afterController;
  HttpServer? _afterServer;

  // UI controls
  bool _showLabels = true;

  // Video support
  bool get _hasVideo => widget.model.videoFileName != null;

  // Fullscreen state
  bool _isFullscreen = false;
  bool _fullscreenIsBefore = true; // Which model is shown in fullscreen
  bool _autoRotate = true;

  // Drawing state for fullscreen
  bool _drawMode = false;
  Color _drawColor = Colors.red;
  double _strokeWidth = 3.0;
  List<_DrawingStroke> _strokes = [];
  _DrawingStroke? _currentStroke;
  bool _showDrawings = true;

  // Screenshot capture
  final _captureKey = GlobalKey();
  bool _hideUIForCapture = false;

  @override
  void initState() {
    super.initState();
    // Enter immersive mode to hide status bar and force landscape
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadBothModels();
  }

  @override
  void dispose() {
    // Restore normal system UI mode and orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _beforeServer?.close(force: true);
    _afterServer?.close(force: true);
    super.dispose();
  }

  Future<void> _loadBothModels() async {
    if (_hasVideo) {
      // Video mode: load 3D model on left, video on right
      await _loadModel(isBefore: true);
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadVideo();
    } else {
      // Standard comparison: load both 3D models
      await _loadModel(isBefore: true);
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadModel(isBefore: false);
    }
  }

  Future<void> _loadModel({required bool isBefore}) async {
    final modelFileName = _hasVideo && isBefore
        ? widget.model.modelFileName
        : (isBefore
            ? widget.model.beforeModelFileName
            : widget.model.afterModelFileName);

    if (modelFileName == null) {
      setState(() {
        if (isBefore) {
          _beforeState = _LoadState.error;
        } else {
          _afterState = _LoadState.error;
        }
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      if (isBefore) {
        _beforeState = _LoadState.loading;
        _beforeProgress = 0.0;
      } else {
        _afterState = _LoadState.loading;
        _afterProgress = 0.0;
      }
    });

    try {
      final path = await _service.downloadModel(
        modelFileName,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              if (isBefore) {
                _beforeProgress = p;
              } else {
                _afterProgress = p;
              }
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        if (isBefore) {
          _beforeState = _LoadState.ready;
        } else {
          _afterState = _LoadState.ready;
        }
      });

      await _initWebView(path, isBefore: isBefore);
    } catch (e) {
      debugPrint('Error loading model $modelFileName: $e');
      if (mounted) {
        setState(() {
          if (isBefore) {
            _beforeState = _LoadState.error;
          } else {
            _afterState = _LoadState.error;
          }
        });
      }
    }
  }

  Future<void> _loadVideo() async {
    final videoFileName = widget.model.videoFileName;
    if (videoFileName == null) return;

    if (!mounted) return;
    setState(() {
      _afterState = _LoadState.loading;
      _afterProgress = 0.0;
    });

    try {
      final path = await _service.downloadModel(
        videoFileName,
        onProgress: (p) {
          if (mounted) {
            setState(() => _afterProgress = p);
          }
        },
      );

      if (!mounted) return;
      setState(() => _afterState = _LoadState.ready);
      await _initVideoWebView(path);
    } catch (e) {
      debugPrint('Error loading video $videoFileName: $e');
      if (mounted) {
        setState(() => _afterState = _LoadState.error);
      }
    }
  }

  Future<void> _initWebView(String modelPath, {required bool isBefore}) async {
    try {
      if (isBefore) {
        _beforeServer?.close(force: true);
      } else {
        _afterServer?.close(force: true);
      }

      // Ensure model-viewer JS is cached locally for offline use
      String? modelViewerJsPath;
      try {
        modelViewerJsPath = await _service.getModelViewerJsPath();
      } catch (e) {
        debugPrint('Warning: Could not cache model-viewer.js: $e');
      }

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      if (isBefore) {
        _beforeServer = server;
      } else {
        _afterServer = server;
      }
      final port = server.port;
      final label = isBefore
          ? (widget.model.beforeLabel ?? 'Before')
          : (widget.model.afterLabel ?? 'After');

      server.listen((request) async {
        try {
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
          } else if (request.uri.path == '/model-viewer.min.js') {
            if (modelViewerJsPath != null) {
              final file = File(modelViewerJsPath);
              if (await file.exists()) {
                request.response.headers.set('Content-Type', 'application/javascript');
                request.response.headers.set('Access-Control-Allow-Origin', '*');
                await request.response.addStream(file.openRead());
                await request.response.close();
                return;
              }
            }
            request.response.statusCode = 404;
            await request.response.close();
          } else if (request.uri.path == '/') {
            request.response.headers.set('Content-Type', 'text/html');
            request.response.write(_buildHtml(port, label, hasLocalJs: modelViewerJsPath != null));
            await request.response.close();
          } else {
            request.response.statusCode = 404;
            await request.response.close();
          }
        } catch (e) {
          debugPrint('Server error: $e');
        }
      });

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0A1628))
        ..loadRequest(Uri.parse('http://127.0.0.1:$port/'));

      if (mounted) {
        setState(() {
          if (isBefore) {
            _beforeController = controller;
          } else {
            _afterController = controller;
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing WebView: $e');
      if (mounted) {
        setState(() {
          if (isBefore) {
            _beforeState = _LoadState.error;
          } else {
            _afterState = _LoadState.error;
          }
        });
      }
    }
  }

  Future<void> _initVideoWebView(String videoPath) async {
    try {
      _afterServer?.close(force: true);

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _afterServer = server;
      final port = server.port;

      server.listen((request) async {
        try {
          if (request.uri.path == '/video.mp4') {
            final file = File(videoPath);
            if (await file.exists()) {
              final length = await file.length();
              request.response.headers.set('Content-Type', 'video/mp4');
              request.response.headers.set('Accept-Ranges', 'bytes');
              request.response.headers.set('Content-Length', '$length');
              request.response.headers.set('Access-Control-Allow-Origin', '*');
              await request.response.addStream(file.openRead());
              await request.response.close();
            } else {
              request.response.statusCode = 404;
              await request.response.close();
            }
          } else if (request.uri.path == '/') {
            request.response.headers.set('Content-Type', 'text/html');
            request.response.write(_buildVideoHtml(port));
            await request.response.close();
          } else {
            request.response.statusCode = 404;
            await request.response.close();
          }
        } catch (e) {
          debugPrint('Video server error: $e');
        }
      });

      final controller = WebViewController();
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0A1628))
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            controller.runJavaScript("document.querySelector('video')?.play();");
          },
        ))
        ..loadRequest(Uri.parse('http://127.0.0.1:$port/'));

      if (mounted) {
        setState(() => _afterController = controller);
      }
    } catch (e) {
      debugPrint('Error initializing video WebView: $e');
      if (mounted) {
        setState(() => _afterState = _LoadState.error);
      }
    }
  }

  String _buildVideoHtml(int port) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: #0A1628; display: flex; align-items: center; justify-content: center; }
    video {
      width: 100%;
      height: 100%;
      object-fit: contain;
      background: #0A1628;
    }
  </style>
</head>
<body>
  <video
    src="http://127.0.0.1:$port/video.mp4"
    autoplay
    loop
    muted
    playsinline
    controls>
  </video>
</body>
</html>
''';
  }

  String _buildHtml(int port, String title, {bool hasLocalJs = true}) {
    final jsUrl = hasLocalJs
        ? 'http://127.0.0.1:$port/model-viewer.min.js'
        : 'https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js';
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <script type="module" src="$jsUrl"></script>
  <style>
    * { margin: 0; padding: 0; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: #0A1628; }
    model-viewer {
      width: 100%;
      height: 100%;
      --poster-color: transparent;
    }
    #loading {
      position: absolute;
      top: 50%; left: 50%;
      transform: translate(-50%, -50%);
      font-family: sans-serif;
      color: #94A3B8;
      font-size: 14px;
      z-index: 10;
    }
  </style>
</head>
<body>
  <div id="loading">Loading...</div>
  <model-viewer
    src="http://127.0.0.1:$port/model.glb"
    alt="$title"
    auto-rotate
    camera-controls
    shadow-intensity="0.5"
    exposure="1"
    interaction-prompt="none"
    min-field-of-view="10deg"
    max-field-of-view="90deg"
    touch-action="none"
    style="width:100%;height:100%;"
    loading="lazy">
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

  // Fullscreen methods
  void _enterFullscreen(bool isBefore) {
    setState(() {
      _isFullscreen = true;
      _fullscreenIsBefore = isBefore;
      _drawMode = false;
      _strokes.clear();
    });
  }

  void _exitFullscreen() {
    setState(() {
      _isFullscreen = false;
      _drawMode = false;
    });
  }

  void _switchFullscreenModel() {
    setState(() {
      _fullscreenIsBefore = !_fullscreenIsBefore;
      _strokes.clear();
      _currentStroke = null;
    });
  }

  WebViewController? get _currentFullscreenController =>
      _fullscreenIsBefore ? _beforeController : _afterController;

  void _zoomIn() {
    _currentFullscreenController?.runJavaScript('''
      (function() {
        var mv = document.querySelector('model-viewer');
        if (!mv) return;
        var fov = mv.getFieldOfView();
        var minFov = mv.getMinimumFieldOfView();
        var newFov = Math.max(fov * 0.85, minFov, 10);
        mv.fieldOfView = newFov + 'deg';
      })();
    ''');
  }

  void _zoomOut() {
    _currentFullscreenController?.runJavaScript('''
      (function() {
        var mv = document.querySelector('model-viewer');
        if (!mv) return;
        var fov = mv.getFieldOfView();
        var maxFov = mv.getMaximumFieldOfView();
        var newFov = Math.min(fov * 1.15, maxFov, 120);
        mv.fieldOfView = newFov + 'deg';
      })();
    ''');
  }

  void _resetView() {
    _currentFullscreenController?.runJavaScript('''
      (function() {
        var mv = document.querySelector('model-viewer');
        if (!mv) return;
        mv.cameraOrbit = 'auto auto auto';
        mv.cameraTarget = 'auto auto auto';
        mv.fieldOfView = 'auto';
        mv.jumpCameraToGoal();
      })();
    ''');
  }

  void _toggleAutoRotate() {
    setState(() => _autoRotate = !_autoRotate);
    _currentFullscreenController?.runJavaScript(
      _autoRotate
          ? "document.querySelector('model-viewer').setAttribute('auto-rotate', '');"
          : "document.querySelector('model-viewer').removeAttribute('auto-rotate');",
    );
  }

  void _toggleDrawMode() {
    setState(() => _drawMode = !_drawMode);
    if (_drawMode) {
      _currentFullscreenController?.runJavaScript(
        "var mv = document.querySelector('model-viewer');"
        "mv.removeAttribute('camera-controls');"
        "mv.removeAttribute('auto-rotate');",
      );
    } else {
      _currentFullscreenController?.runJavaScript(
        "var mv = document.querySelector('model-viewer');"
        "mv.setAttribute('camera-controls', '');"
        "${_autoRotate ? "mv.setAttribute('auto-rotate', '');" : ""}",
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
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Clear All Drawings?', style: TextStyle(color: Colors.white)),
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
      setState(() => _hideUIForCapture = true);
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _hideUIForCapture = false);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      setState(() => _hideUIForCapture = false);

      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      if (!mounted) return;

      final nameController = TextEditingController();
      final modelLabel = _fullscreenIsBefore
          ? (widget.model.beforeLabel ?? 'Before')
          : (widget.model.afterLabel ?? 'After');
      nameController.text = '${widget.model.name} - $modelLabel';

      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Save Screenshot', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter name',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              labelText: 'Name',
              labelStyle: const TextStyle(color: Colors.white70),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade600),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
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

      if (name == null || name.isEmpty) return;

      final baseDir = await _service.getCacheDirectory();
      final systemDir = Directory('$baseDir/annotations/${widget.systemId}');
      if (!await systemDir.exists()) {
        await systemDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = '${name.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_')}_$timestamp';
      final file = File('${systemDir.path}/$safeName.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $name'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _hideUIForCapture = false);
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

  @override
  Widget build(BuildContext context) {
    final category = Model3DConfig.getCategoryById(widget.systemId);
    final color = category?.color ?? const Color(0xFFEC4899);

    // Show fullscreen view
    if (_isFullscreen) {
      return _buildFullscreenView(color);
    }

    // Show comparison view
    return Scaffold(
      backgroundColor: const Color(0xFF050d1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d1f3c),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.model.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(_showLabels ? Icons.label : Icons.label_off_outlined),
            tooltip: _showLabels ? 'Hide labels' : 'Show labels',
            onPressed: () => setState(() => _showLabels = !_showLabels),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Comparison Area
            Expanded(
              child: Row(
                children: [
                  // Before Model (or 3D Model in video mode)
                  Expanded(
                    child: _buildModelPanel(
                      label: _hasVideo ? '3D Model' : (widget.model.beforeLabel ?? 'Before'),
                      state: _beforeState,
                      progress: _beforeProgress,
                      controller: _beforeController,
                      color: color,
                      isBefore: true,
                    ),
                  ),
                  // Divider
                  Container(
                    width: 2,
                    color: const Color(0xFF334155),
                  ),
                  // After Model (or Video in video mode)
                  Expanded(
                    child: _buildModelPanel(
                      label: _hasVideo ? 'Video' : (widget.model.afterLabel ?? 'After'),
                      state: _afterState,
                      progress: _afterProgress,
                      controller: _afterController,
                      color: color,
                      isBefore: false,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Info Bar
            _buildInfoBar(color),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenView(Color color) {
    final controller = _fullscreenIsBefore ? _beforeController : _afterController;
    final state = _fullscreenIsBefore ? _beforeState : _afterState;
    final progress = _fullscreenIsBefore ? _beforeProgress : _afterProgress;
    final label = _fullscreenIsBefore
        ? (widget.model.beforeLabel ?? 'Before')
        : (widget.model.afterLabel ?? 'After');
    final otherLabel = _fullscreenIsBefore
        ? (widget.model.afterLabel ?? 'After')
        : (widget.model.beforeLabel ?? 'Before');

    return Scaffold(
      backgroundColor: const Color(0xFF050d1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d1f3c),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.fullscreen_exit),
          tooltip: 'Exit fullscreen',
          onPressed: _exitFullscreen,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.model.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _fullscreenIsBefore
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _fullscreenIsBefore ? Colors.blue.shade300 : Colors.orange.shade300,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (state == _LoadState.ready) ...[
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
              // Auto-rotate toggle
              IconButton(
                icon: Icon(
                  _autoRotate ? Icons.sync : Icons.sync_disabled,
                  color: _autoRotate ? Colors.green : null,
                ),
                tooltip: _autoRotate ? 'Stop rotation' : 'Auto rotate',
                onPressed: _toggleAutoRotate,
              ),
              // Show drawings toggle (if there are drawings)
              if (_strokes.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _showDrawings ? Icons.visibility : Icons.visibility_off,
                    color: _showDrawings ? Colors.blue : null,
                  ),
                  tooltip: _showDrawings ? 'Hide drawings' : 'Show drawings',
                  onPressed: () => setState(() => _showDrawings = !_showDrawings),
                ),
              // Save screenshot without draw mode
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                tooltip: 'Save screenshot',
                onPressed: _saveScreenshot,
              ),
            ],
          ],
        ],
      ),
      body: RepaintBoundary(
        key: _captureKey,
        child: Stack(
          children: [
            // Background
            Container(color: const Color(0xFF0A1628)),
            // Model Viewer
            if (state == _LoadState.ready && controller != null)
              WebViewWidget(
                controller: controller,
                gestureRecognizers: _drawMode
                    ? {}
                    : <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
              )
            else if (state == _LoadState.loading)
              _buildLoadingState(progress, color)
            else if (state == _LoadState.error)
              _buildErrorState(_fullscreenIsBefore),

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

            // Existing drawings shown when not in draw mode
            if (!_drawMode && _strokes.isNotEmpty && _showDrawings)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _DrawingPainter(strokes: _strokes),
                    size: Size.infinite,
                  ),
                ),
              ),

            // Draw mode indicator
            if (_drawMode && !_hideUIForCapture)
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
                            '| Tap to unlock',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Zoom controls - only when not in draw mode
            if (!_drawMode && state == _LoadState.ready && !_hideUIForCapture)
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildZoomButton(
                      icon: Icons.add,
                      onPressed: _zoomIn,
                      tooltip: 'Zoom in',
                    ),
                    const SizedBox(height: 8),
                    _buildZoomButton(
                      icon: Icons.crop_free,
                      onPressed: _resetView,
                      tooltip: 'Reset view',
                      isSmall: true,
                    ),
                    const SizedBox(height: 8),
                    _buildZoomButton(
                      icon: Icons.remove,
                      onPressed: _zoomOut,
                      tooltip: 'Zoom out',
                    ),
                  ],
                ),
              ),

            // Switch model button (Before/After toggle)
            if (!_drawMode && !_hideUIForCapture)
              Positioned(
                left: 16,
                bottom: 100,
                child: Material(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _switchFullscreenModel,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View $otherLabel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _drawMode ? _buildDrawToolbar() : null,
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
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
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

  Widget _buildModelPanel({
    required String label,
    required _LoadState state,
    required double progress,
    required WebViewController? controller,
    required Color color,
    required bool isBefore,
  }) {
    return Stack(
      children: [
        // Background
        Container(color: const Color(0xFF0A1628)),
        // Model Viewer
        if (state == _LoadState.ready && controller != null)
          WebViewWidget(
            controller: controller,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
            },
          )
        else if (state == _LoadState.loading)
          _buildLoadingState(progress, color)
        else if (state == _LoadState.error)
          _buildErrorState(isBefore),

        // Model Label
        if (_showLabels)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isBefore
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isBefore
                            ? Colors.blue.shade300
                            : Colors.orange.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Fullscreen button
        if (state == _LoadState.ready)
          Positioned(
            bottom: 12,
            right: 12,
            child: Material(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => _enterFullscreen(isBefore),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState(double progress, Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.view_in_ar_rounded,
            size: 40,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress > 0 ? '${(progress * 100).toInt()}%' : 'Loading...',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isBefore) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          const Text(
            'Failed to load',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _loadModel(isBefore: isBefore),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          top: BorderSide(color: Color(0xFF334155)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Before label
              Expanded(
                child: _buildStageLabel(
                  _hasVideo ? '3D Model' : (widget.model.beforeLabel ?? 'Before'),
                  Colors.blue,
                  false,
                ),
              ),
              // Arrow/separator indicator
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  _hasVideo ? Icons.compare : Icons.arrow_forward,
                  color: color,
                  size: 24,
                ),
              ),
              // After label
              Expanded(
                child: _buildStageLabel(
                  _hasVideo ? 'Video' : (widget.model.afterLabel ?? 'After'),
                  Colors.orange,
                  true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.model.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageLabel(String label, Color color, bool alignRight) {
    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
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
