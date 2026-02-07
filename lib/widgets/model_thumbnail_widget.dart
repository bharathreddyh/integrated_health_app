// lib/widgets/model_thumbnail_widget.dart
// Widget that displays a 3D model thumbnail preview
// Shows live WebView preview if model is downloaded, otherwise placeholder

import 'dart:async';
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

class _ModelThumbnailWidgetState extends State<ModelThumbnailWidget>
    with AutomaticKeepAliveClientMixin {
  final _thumbnailService = ModelThumbnailService.instance;

  bool _isLoading = true;
  bool _isModelAvailable = false;
  bool _hasError = false;
  String? _modelPath;
  WebViewController? _controller;
  HttpServer? _server;
  int _retryCount = 0;
  static const _maxRetries = 2;

  @override
  bool get wantKeepAlive => _isModelAvailable; // Keep alive if model loaded

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  @override
  void dispose() {
    _cleanupServer();
    super.dispose();
  }

  void _cleanupServer() {
    _server?.close(force: true);
    _server = null;
  }

  Future<void> _initializePreview() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final isDownloaded = await _thumbnailService.isModelDownloaded(widget.modelId);

      if (!mounted) return;

      if (isDownloaded) {
        final path = await _thumbnailService.getModelPath(widget.modelId);
        if (path != null && mounted) {
          setState(() {
            _isModelAvailable = true;
            _modelPath = path;
          });
          await _startPreviewServer(path);
        } else {
          setState(() {
            _isModelAvailable = false;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isModelAvailable = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        _scheduleRetry();
      }
    }
  }

  void _scheduleRetry() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      Future.delayed(Duration(milliseconds: 500 * _retryCount), () {
        if (mounted) {
          _initializePreview();
        }
      });
    }
  }

  Future<void> _startPreviewServer(String modelPath) async {
    _cleanupServer();

    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = server;
      final port = server.port;

      server.listen((request) async {
        try {
          if (request.uri.path == '/model.glb') {
            final file = File(modelPath);
            if (await file.exists()) {
              request.response.headers.set('Content-Type', 'model/gltf-binary');
              request.response.headers.set('Access-Control-Allow-Origin', '*');
              request.response.headers.set('Cache-Control', 'max-age=3600');
              await request.response.addStream(file.openRead());
            } else {
              request.response.statusCode = 404;
            }
            await request.response.close();
          } else if (request.uri.path == '/') {
            request.response.headers.set('Content-Type', 'text/html');
            request.response.headers.set('Cache-Control', 'no-cache');
            request.response.write(_buildPreviewHtml(port));
            await request.response.close();
          } else {
            request.response.statusCode = 404;
            await request.response.close();
          }
        } catch (_) {
          // Ignore request errors
        }
      });

      // Small delay to ensure server is ready
      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) {
        _cleanupServer();
        return;
      }

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF1E293B))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (_) {
              if (mounted && _retryCount < _maxRetries) {
                _scheduleRetry();
              }
            },
          ),
        )
        ..loadRequest(Uri.parse('http://127.0.0.1:$port/'));

      if (mounted) {
        setState(() {
          _controller = controller;
        });

        // Fallback: mark as loaded after timeout
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isLoading) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        _scheduleRetry();
      }
    }
  }

  String _buildPreviewHtml(int port) {
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
      background: #1E293B;
    }
    model-viewer {
      width: 100%;
      height: 100%;
      --poster-color: transparent;
      background: #1E293B;
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
    camera-orbit="45deg 65deg 2.5m"
    field-of-view="35deg"
    min-field-of-view="25deg"
    max-field-of-view="45deg"
    loading="eager"
    style="width:100%;height:100%;pointer-events:none;">
  </model-viewer>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Show placeholder if not available or has error
    if (!_isModelAvailable || _hasError) {
      return _buildPlaceholder();
    }

    // Show loading while initializing
    if (_controller == null) {
      return _buildPlaceholder(showLoading: true);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // WebView
            Positioned.fill(
              child: IgnorePointer(
                child: WebViewWidget(
                  controller: _controller!,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{},
                ),
              ),
            ),
            // Loading overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF1E293B),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(
                          widget.accentColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: showLoading
            ? SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(
                    widget.accentColor.withOpacity(0.5),
                  ),
                ),
              )
            : Icon(
                Icons.view_in_ar_rounded,
                size: widget.size * 0.4,
                color: widget.accentColor,
              ),
      ),
    );
  }
}
