// lib/screens/models_3d/model_before_after_screen.dart
// Side-by-side before/after 3D model comparison screen
// Shows progression/growth of pathology (e.g., fibroid compression effects)

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadBothModels();
  }

  @override
  void dispose() {
    _beforeServer?.close(force: true);
    _afterServer?.close(force: true);
    super.dispose();
  }

  Future<void> _loadBothModels() async {
    // Load sequentially to prevent GPU resource conflicts
    await _loadModel(isBefore: true);
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadModel(isBefore: false);
  }

  Future<void> _loadModel({required bool isBefore}) async {
    final modelFileName = isBefore
        ? widget.model.beforeModelFileName
        : widget.model.afterModelFileName;

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

  Future<void> _initWebView(String modelPath, {required bool isBefore}) async {
    try {
      if (isBefore) {
        _beforeServer?.close(force: true);
      } else {
        _afterServer?.close(force: true);
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
          } else if (request.uri.path == '/') {
            request.response.headers.set('Content-Type', 'text/html');
            request.response.write(_buildHtml(port, label));
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

  String _buildHtml(int port, String title) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>
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

  @override
  Widget build(BuildContext context) {
    final category = Model3DConfig.getCategoryById(widget.systemId);
    final color = category?.color ?? const Color(0xFFEC4899);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
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
                  // Before Model
                  Expanded(
                    child: _buildModelPanel(
                      label: widget.model.beforeLabel ?? 'Before',
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
                  // After Model
                  Expanded(
                    child: _buildModelPanel(
                      label: widget.model.afterLabel ?? 'After',
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
                  widget.model.beforeLabel ?? 'Before',
                  Colors.blue,
                  false,
                ),
              ),
              // Arrow indicator
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.arrow_forward,
                  color: color,
                  size: 24,
                ),
              ),
              // After label
              Expanded(
                child: _buildStageLabel(
                  widget.model.afterLabel ?? 'After',
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
