// lib/screens/models_3d/model_compare_screen.dart
// Side-by-side 3D model comparison screen
// Allows comparing two anatomical models (e.g., normal vs pathology)

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/model_3d_config.dart';
import '../../services/model_3d_service.dart';

class ModelCompareScreen extends StatefulWidget {
  final Model3DItem leftModel;
  final Model3DItem rightModel;
  final String systemId;

  const ModelCompareScreen({
    super.key,
    required this.leftModel,
    required this.rightModel,
    required this.systemId,
  });

  @override
  State<ModelCompareScreen> createState() => _ModelCompareScreenState();
}

class _ModelCompareScreenState extends State<ModelCompareScreen> {
  final _service = Model3DService.instance;

  // Left model state
  _LoadState _leftState = _LoadState.loading;
  double _leftProgress = 0.0;
  WebViewController? _leftController;
  HttpServer? _leftServer;

  // Right model state
  _LoadState _rightState = _LoadState.loading;
  double _rightProgress = 0.0;
  WebViewController? _rightController;
  HttpServer? _rightServer;

  // Sync controls
  bool _syncRotation = true;
  bool _showLabels = true;

  @override
  void initState() {
    super.initState();
    _loadBothModels();
  }

  @override
  void dispose() {
    _leftServer?.close(force: true);
    _rightServer?.close(force: true);
    super.dispose();
  }

  Future<void> _loadBothModels() async {
    await Future.wait([
      _loadModel(isLeft: true),
      _loadModel(isLeft: false),
    ]);
  }

  Future<void> _loadModel({required bool isLeft}) async {
    final model = isLeft ? widget.leftModel : widget.rightModel;

    if (!mounted) return;

    setState(() {
      if (isLeft) {
        _leftState = _LoadState.loading;
        _leftProgress = 0.0;
      } else {
        _rightState = _LoadState.loading;
        _rightProgress = 0.0;
      }
    });

    try {
      final path = await _service.downloadModel(
        model.modelFileName,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              if (isLeft) {
                _leftProgress = p;
              } else {
                _rightProgress = p;
              }
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        if (isLeft) {
          _leftState = _LoadState.ready;
        } else {
          _rightState = _LoadState.ready;
        }
      });

      await _initWebView(path, isLeft: isLeft);
    } catch (e) {
      debugPrint('Error loading model ${model.modelFileName}: $e');
      if (mounted) {
        setState(() {
          if (isLeft) {
            _leftState = _LoadState.error;
          } else {
            _rightState = _LoadState.error;
          }
        });
      }
    }
  }

  Future<void> _initWebView(String modelPath, {required bool isLeft}) async {
    try {
      if (isLeft) {
        _leftServer?.close(force: true);
      } else {
        _rightServer?.close(force: true);
      }

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      if (isLeft) {
        _leftServer = server;
      } else {
        _rightServer = server;
      }
      final port = server.port;
      final model = isLeft ? widget.leftModel : widget.rightModel;

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
          } else if (request.uri.path == '/') {
            request.response.headers.set('Content-Type', 'text/html');
            request.response.write(_buildHtml(port, model.name));
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
        ..setBackgroundColor(const Color(0xFF1E293B))
        ..loadRequest(Uri.parse('http://127.0.0.1:$port/'));

      if (mounted) {
        setState(() {
          if (isLeft) {
            _leftController = controller;
          } else {
            _rightController = controller;
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing WebView: $e');
      if (mounted) {
        setState(() {
          if (isLeft) {
            _leftState = _LoadState.error;
          } else {
            _rightState = _LoadState.error;
          }
        });
      }
    }
  }

  String _buildHtml(int port, String title) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>
  <style>
    * { margin: 0; padding: 0; touch-action: none; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: #1E293B; }
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
    disable-zoom="false"
    shadow-intensity="1"
    touch-action="none"
    interaction-prompt="none"
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

  void _swapModels() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ModelCompareScreen(
          leftModel: widget.rightModel,
          rightModel: widget.leftModel,
          systemId: widget.systemId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = Model3DConfig.getCategoryById(widget.systemId);
    final color = category?.color ?? const Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text(
          'Compare Models',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          // Swap button
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Swap models',
            onPressed: _swapModels,
          ),
          // Toggle labels
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
                  // Left Model
                  Expanded(
                    child: _buildModelPanel(
                      model: widget.leftModel,
                      state: _leftState,
                      progress: _leftProgress,
                      controller: _leftController,
                      color: color,
                      isLeft: true,
                    ),
                  ),
                  // Divider
                  Container(
                    width: 2,
                    color: const Color(0xFF334155),
                  ),
                  // Right Model
                  Expanded(
                    child: _buildModelPanel(
                      model: widget.rightModel,
                      state: _rightState,
                      progress: _rightProgress,
                      controller: _rightController,
                      color: color,
                      isLeft: false,
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

  Widget _buildModelPanel({
    required Model3DItem model,
    required _LoadState state,
    required double progress,
    required WebViewController? controller,
    required Color color,
    required bool isLeft,
  }) {
    final isPathology = model.tags.contains('pathology');

    return Stack(
      children: [
        // Background
        Container(color: const Color(0xFF1E293B)),
        // Model Viewer
        if (state == _LoadState.ready && controller != null)
          WebViewWidget(
            controller: controller,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
            },
          )
        else if (state == _LoadState.loading)
          _buildLoadingState(progress)
        else if (state == _LoadState.error)
          _buildErrorState(isLeft),

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPathology
                              ? Colors.red.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPathology ? 'PATHOLOGY' : 'NORMAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isPathology
                                ? Colors.red.shade300
                                : Colors.green.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    model.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState(double progress) {
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
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
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

  Widget _buildErrorState(bool isLeft) {
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
            onPressed: () => _loadModel(isLeft: isLeft),
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
      child: Row(
        children: [
          // Left model info
          Expanded(
            child: _buildModelInfo(widget.leftModel, color),
          ),
          // VS divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'VS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          // Right model info
          Expanded(
            child: _buildModelInfo(widget.rightModel, color, alignRight: true),
          ),
        ],
      ),
    );
  }

  Widget _buildModelInfo(Model3DItem model, Color color, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          model.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          model.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

enum _LoadState { loading, ready, error }
