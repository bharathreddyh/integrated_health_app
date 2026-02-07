// lib/widgets/model_thumbnail_widget.dart
// Hybrid thumbnail widget for 3D models
// Priority: 1) Live 3D preview (if model downloaded)
//           2) Static/animated thumbnail from assets
//           3) Placeholder icon

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/model_thumbnail_service.dart';

class ModelThumbnailWidget extends StatefulWidget {
  final String modelId;
  final Color accentColor;
  final double size;
  final bool preferLivePreview; // If true, prefer live 3D when available (disabled by default to prevent crashes)

  const ModelThumbnailWidget({
    super.key,
    required this.modelId,
    required this.accentColor,
    this.size = 80,
    this.preferLivePreview = false, // Disabled by default - too many WebViews cause crashes
  });

  @override
  State<ModelThumbnailWidget> createState() => _ModelThumbnailWidgetState();
}

class _ModelThumbnailWidgetState extends State<ModelThumbnailWidget>
    with AutomaticKeepAliveClientMixin {
  final _thumbnailService = ModelThumbnailService.instance;

  // State
  bool _isLoading = true;
  bool _hasStaticThumbnail = false;
  bool _hasAnimatedThumbnail = false;
  bool _isModelDownloaded = false;
  bool _showLivePreview = false;
  bool _hasError = false;

  // Live preview
  WebViewController? _controller;
  HttpServer? _server;
  String? _modelPath;
  int _retryCount = 0;
  static const _maxRetries = 2;

  @override
  bool get wantKeepAlive => _showLivePreview;

  @override
  void initState() {
    super.initState();
    _initialize();
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

  Future<void> _initialize() async {
    if (!mounted) return;

    // Check for static thumbnails in assets
    await _checkStaticThumbnails();

    // Check if 3D model is downloaded
    final isDownloaded = await _thumbnailService.isModelDownloaded(widget.modelId);

    if (mounted) {
      setState(() {
        _isModelDownloaded = isDownloaded;
        _isLoading = false;
      });

      // If model is downloaded and we prefer live preview, start it
      if (isDownloaded && widget.preferLivePreview) {
        final path = await _thumbnailService.getModelPath(widget.modelId);
        if (path != null && mounted) {
          _modelPath = path;
          _startLivePreview(path);
        }
      }
    }
  }

  Future<void> _checkStaticThumbnails() async {
    // Check for PNG thumbnail
    final pngPath = 'assets/images/model_thumbnails/${widget.modelId}.png';
    final gifPath = 'assets/images/model_thumbnails/${widget.modelId}.gif';

    try {
      await rootBundle.load(pngPath);
      if (mounted) {
        setState(() => _hasStaticThumbnail = true);
      }
    } catch (_) {
      // PNG not found, try GIF
      try {
        await rootBundle.load(gifPath);
        if (mounted) {
          setState(() {
            _hasStaticThumbnail = true;
            _hasAnimatedThumbnail = true;
          });
        }
      } catch (_) {
        // No static thumbnail available
      }
    }
  }

  Future<void> _startLivePreview(String modelPath) async {
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
        } catch (_) {}
      });

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
                setState(() => _showLivePreview = true);
              }
            },
            onWebResourceError: (_) {
              if (mounted && _retryCount < _maxRetries) {
                _retryCount++;
                Future.delayed(Duration(milliseconds: 500 * _retryCount), () {
                  if (mounted && _modelPath != null) {
                    _startLivePreview(_modelPath!);
                  }
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse('http://127.0.0.1:$port/'));

      if (mounted) {
        setState(() => _controller = controller);

        // Fallback timeout
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _controller != null && !_showLivePreview) {
            setState(() => _showLivePreview = true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
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
    html, body { width: 100%; height: 100%; overflow: hidden; background: #1E293B; }
    model-viewer { width: 100%; height: 100%; --poster-color: transparent; background: #1E293B; }
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
    super.build(context);

    // Show loading state initially
    if (_isLoading) {
      return _buildPlaceholder(showLoading: true);
    }

    // Priority 1: Live 3D preview (if model downloaded and loaded)
    if (_showLivePreview && _controller != null) {
      return _buildLivePreview();
    }

    // Priority 2: Static/animated thumbnail from assets
    if (_hasStaticThumbnail) {
      return _buildStaticThumbnail();
    }

    // Priority 3: Loading state while initializing live preview
    if (_isModelDownloaded && _controller != null && !_showLivePreview) {
      return _buildStaticThumbnail(showLoading: true);
    }

    // Fallback: Placeholder icon
    return _buildPlaceholder();
  }

  Widget _buildLivePreview() {
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
            Positioned.fill(
              child: IgnorePointer(
                child: WebViewWidget(
                  controller: _controller!,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{},
                ),
              ),
            ),
            // Live indicator
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.threed_rotation, size: 10, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      '3D',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticThumbnail({bool showLoading = false}) {
    final imagePath = _hasAnimatedThumbnail
        ? 'assets/images/model_thumbnails/${widget.modelId}.gif'
        : 'assets/images/model_thumbnails/${widget.modelId}.png';

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
          fit: StackFit.expand,
          children: [
            // Thumbnail image
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
            ),
            // Loading overlay if transitioning to live
            if (showLoading)
              Container(
                color: Colors.black26,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(widget.accentColor),
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
