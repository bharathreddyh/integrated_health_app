// lib/screens/model_viewer_screen.dart
// Displays a 3D .glb model using Google's <model-viewer> web component
// via webview_flutter with a local HTTP server to serve the file.
// Includes a drawing overlay for annotation on the 3D model.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/model_3d_config.dart';
import '../services/model_3d_service.dart';
import 'models_3d/model_compare_screen.dart';

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

  // Drawing visibility toggle
  bool _showDrawings = true;

  // Annotation visibility toggle
  bool _showAnnotations = true;

  // Annotation edit mode
  bool _annotationEditMode = false;

  // Custom annotations (user-added)
  List<ModelAnnotation> _customAnnotations = [];

  // UI capture state - hide overlays during screenshot
  bool _hideUIForCapture = false;

  // Current model config (for annotations)
  Model3DItem? _currentModelConfig;

  @override
  void initState() {
    super.initState();
    _findCurrentModelConfig();
    _loadCustomAnnotations();
    _loadModel();
  }

  void _findCurrentModelConfig() {
    // Find the current model in config to get annotations
    for (final category in Model3DConfig.categories) {
      for (final model in category.models) {
        if (model.modelFileName == widget.modelName) {
          _currentModelConfig = model;
          return;
        }
      }
    }
  }

  Future<void> _loadCustomAnnotations() async {
    try {
      final baseDir = await _service.getCacheDirectory();
      final file = File('$baseDir/annotations/${widget.modelName}_hotspots.json');
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        setState(() {
          _customAnnotations = jsonList.map((j) => ModelAnnotation(
            id: j['id'] as String,
            label: j['label'] as String,
            description: j['description'] as String?,
            position: j['position'] as String,
            normal: j['normal'] as String? ?? '0 0 1',
          )).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading custom annotations: $e');
    }
  }

  Future<void> _saveCustomAnnotations() async {
    try {
      final baseDir = await _service.getCacheDirectory();
      final dir = Directory('$baseDir/annotations');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('${dir.path}/${widget.modelName}_hotspots.json');
      final jsonList = _customAnnotations.map((a) => {
        'id': a.id,
        'label': a.label,
        'description': a.description,
        'position': a.position,
        'normal': a.normal,
      }).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving custom annotations: $e');
    }
  }

  List<ModelAnnotation> get _allAnnotations {
    return [...(_currentModelConfig?.annotations ?? []), ..._customAnnotations];
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
      ..addJavaScriptChannel(
        'AnnotationBridge',
        onMessageReceived: (message) {
          _handleAnnotationTap(message.message);
        },
      )
      ..loadRequest(Uri.parse('http://127.0.0.1:$port/'));

    if (mounted) {
      setState(() => _webController = controller);
    }
  }

  void _handleAnnotationTap(String message) async {
    if (!_annotationEditMode) return;

    try {
      final data = jsonDecode(message);
      final position = data['position'] as String;
      final normal = data['normal'] as String;

      if (!mounted) return;

      // Show dialog to add annotation
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => _AddAnnotationDialog(position: position, normal: normal),
      );

      if (result != null && mounted) {
        final newAnnotation = ModelAnnotation(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          label: result['label'] as String,
          description: result['description'] as String?,
          position: result['position'] as String,
          normal: result['normal'] as String,
        );

        setState(() {
          _customAnnotations.add(newAnnotation);
        });
        await _saveCustomAnnotations();

        // Reload WebView to show new annotation
        if (_localPath != null) {
          await _initWebView(_localPath!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added annotation: ${result['label']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling annotation tap: $e');
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

  void _toggleAnnotations() {
    setState(() {
      _showAnnotations = !_showAnnotations;
    });
    // Toggle annotations in WebView via JavaScript
    _webController?.runJavaScript('toggleAnnotations($_showAnnotations);');
  }

  void _toggleAnnotationEditMode() {
    setState(() {
      _annotationEditMode = !_annotationEditMode;
    });
    // Toggle edit mode in WebView via JavaScript
    _webController?.runJavaScript('setEditMode($_annotationEditMode);');
  }

  void _showManageAnnotationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _ManageAnnotationsDialog(
        customAnnotations: _customAnnotations,
        onDelete: (annotation) async {
          setState(() {
            _customAnnotations.removeWhere((a) => a.id == annotation.id);
          });
          await _saveCustomAnnotations();
          // Reload WebView
          if (_localPath != null) {
            await _initWebView(_localPath!);
          }
        },
        onDeleteAll: () async {
          setState(() {
            _customAnnotations.clear();
          });
          await _saveCustomAnnotations();
          // Reload WebView
          if (_localPath != null) {
            await _initWebView(_localPath!);
          }
        },
      ),
    );
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
      // Hide UI overlays before capture
      setState(() => _hideUIForCapture = true);

      // Wait for UI to rebuild without the banner
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _hideUIForCapture = false);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // Restore UI overlays
      setState(() => _hideUIForCapture = false);

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
      builder: (ctx) => _SavedImagesDialog(
        files: files,
        onShowFullImage: (file) => _showFullImage(ctx, file),
        onDeleted: () {
          Navigator.pop(ctx);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Images deleted'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      ),
    );
  }

  void _showCompareModelPicker() {
    // Get current model as Model3DItem
    Model3DItem? currentModel;
    String currentSystemId = widget.systemId;

    // Find the current model in config
    for (final category in Model3DConfig.categories) {
      for (final model in category.models) {
        if (model.modelFileName == widget.modelName) {
          currentModel = model;
          currentSystemId = category.id;
          break;
        }
      }
      if (currentModel != null) break;
    }

    if (currentModel == null) {
      // Create a temporary model item if not found in config
      currentModel = Model3DItem(
        id: widget.modelName,
        name: widget.title,
        description: '',
        modelFileName: widget.modelName,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModelPickerSheet(
        currentModel: currentModel!,
        currentSystemId: currentSystemId,
        onModelSelected: (selectedModel, selectedSystemId) {
          Navigator.pop(ctx);
          // Navigate to compare screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ModelCompareScreen(
                leftModel: currentModel!,
                rightModel: selectedModel,
                systemId: selectedSystemId,
              ),
            ),
          );
        },
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
    // Generate hotspot HTML from ALL annotations (config + custom)
    final annotations = _allAnnotations;
    final hotspotsHtml = annotations.map((annotation) {
      final isCustom = annotation.id.startsWith('custom_');
      return '''
    <button class="hotspot${isCustom ? ' custom' : ''}" slot="hotspot-${annotation.id}"
            data-position="${annotation.position}"
            data-normal="${annotation.normal}"
            data-visibility-attribute="visible">
      <div class="annotation-label">${annotation.label}</div>
    </button>''';
    }).join('\n');

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
    /* Annotation hotspot styles */
    .hotspot {
      display: block;
      width: 8px;
      height: 8px;
      border-radius: 50%;
      border: 1.5px solid #fff;
      background: #4CAF50;
      box-shadow: 0 1px 3px rgba(0,0,0,0.5);
      cursor: pointer;
      transition: transform 0.2s, opacity 0.3s;
      position: relative;
    }
    .hotspot.custom {
      background: #2196F3;
    }
    .hotspot:hover {
      transform: scale(1.5);
    }
    .hotspot.hidden {
      opacity: 0;
      pointer-events: none;
    }

    /* Label styling */
    .annotation-label {
      position: absolute;
      background: rgba(0,0,0,0.85);
      color: #fff;
      padding: 4px 8px;
      border-radius: 3px;
      font-size: 10px;
      font-family: -apple-system, BlinkMacSystemFont, sans-serif;
      white-space: nowrap;
      pointer-events: none;
      opacity: 0;
      transition: opacity 0.2s;
      box-shadow: 0 2px 6px rgba(0,0,0,0.3);
    }

    /* Default: label on top */
    .hotspot .annotation-label {
      bottom: 55px;
      left: 50%;
      transform: translateX(-50%);
    }
    .hotspot::before {
      content: '';
      position: absolute;
      left: 50%;
      transform: translateX(-50%);
      width: 1px;
      opacity: 0;
      transition: opacity 0.2s;
      background: rgba(255,255,255,0.7);
      bottom: 100%;
      height: 45px;
    }

    /* Label on bottom */
    .hotspot.label-bottom .annotation-label {
      bottom: auto;
      top: 55px;
      left: 50%;
      transform: translateX(-50%);
    }
    .hotspot.label-bottom::before {
      bottom: auto;
      top: 100%;
      height: 45px;
    }

    /* Label on left */
    .hotspot.label-left .annotation-label {
      bottom: auto;
      top: 50%;
      left: auto;
      right: 60px;
      transform: translateY(-50%);
    }
    .hotspot.label-left::before {
      bottom: auto;
      top: 50%;
      left: auto;
      right: 100%;
      transform: translateY(-50%);
      width: 50px;
      height: 1px;
    }

    /* Label on right */
    .hotspot.label-right .annotation-label {
      bottom: auto;
      top: 50%;
      left: 60px;
      right: auto;
      transform: translateY(-50%);
    }
    .hotspot.label-right::before {
      bottom: auto;
      top: 50%;
      left: 100%;
      right: auto;
      transform: translateY(-50%);
      width: 50px;
      height: 1px;
    }

    .hotspot:hover .annotation-label,
    .hotspot.show-label .annotation-label {
      opacity: 1;
    }
    .hotspot:hover::before,
    .hotspot.show-label::before {
      opacity: 1;
    }

    /* Edit mode cursor */
    model-viewer.edit-mode {
      cursor: crosshair;
    }
  </style>
</head>
<body>
  <div id="loading">Loading 3D model...</div>
  <model-viewer
    id="viewer"
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
$hotspotsHtml
  </model-viewer>
  <script>
    var modelViewer = document.getElementById('viewer');
    var editMode = false;

    modelViewer.addEventListener('load', function() {
      document.getElementById('loading').style.display = 'none';
      // Position labels based on normal direction
      positionLabels();
    });

    // Determine label position based on surface normal
    function positionLabels() {
      var hotspots = document.querySelectorAll('.hotspot');
      hotspots.forEach(function(h) {
        var normalStr = h.getAttribute('data-normal');
        if (!normalStr) return;

        var parts = normalStr.split(' ').map(parseFloat);
        if (parts.length < 3) return;

        var nx = parts[0], ny = parts[1], nz = parts[2];

        // Remove existing position classes
        h.classList.remove('label-top', 'label-bottom', 'label-left', 'label-right');

        // Determine dominant direction
        var absX = Math.abs(nx);
        var absY = Math.abs(ny);
        var absZ = Math.abs(nz);

        // If pointing mostly up/down (Y axis dominant)
        if (absY > absX && absY > absZ) {
          if (ny > 0) {
            h.classList.add('label-top');  // Surface faces up, label goes up
          } else {
            h.classList.add('label-bottom');  // Surface faces down, label goes down
          }
        }
        // If pointing mostly left/right (X axis dominant)
        else if (absX > absY && absX > absZ) {
          if (nx > 0) {
            h.classList.add('label-right');  // Surface faces right, label goes right
          } else {
            h.classList.add('label-left');  // Surface faces left, label goes left
          }
        }
        // If pointing mostly forward/back (Z axis dominant) or default
        else {
          // For forward-facing surfaces, use position-based logic
          var posStr = h.getAttribute('data-position');
          if (posStr) {
            var posParts = posStr.split(' ').map(parseFloat);
            if (posParts.length >= 3) {
              var px = posParts[0], py = posParts[1];
              // Use position to decide: if on left side of model, label left; if right, label right
              if (px < -0.02) {
                h.classList.add('label-left');
              } else if (px > 0.02) {
                h.classList.add('label-right');
              } else if (py > 0) {
                h.classList.add('label-top');
              } else {
                h.classList.add('label-bottom');
              }
            }
          }
        }
      });
    }

    // Handle click on model to get 3D position
    modelViewer.addEventListener('click', function(event) {
      if (!editMode) return;

      // Get position on the model surface
      var rect = modelViewer.getBoundingClientRect();
      var x = event.clientX - rect.left;
      var y = event.clientY - rect.top;

      // Use model-viewer's positionAndNormalFromPoint method
      var hit = modelViewer.positionAndNormalFromPoint(x, y);
      if (hit) {
        var pos = hit.position;
        var norm = hit.normal;
        var posStr = pos.x.toFixed(4) + ' ' + pos.y.toFixed(4) + ' ' + pos.z.toFixed(4);
        var normStr = norm.x.toFixed(4) + ' ' + norm.y.toFixed(4) + ' ' + norm.z.toFixed(4);

        // Send to Flutter
        AnnotationBridge.postMessage(JSON.stringify({
          position: posStr,
          normal: normStr
        }));
      }
    });

    // Function to toggle annotation visibility
    function toggleAnnotations(visible) {
      var hotspots = document.querySelectorAll('.hotspot');
      hotspots.forEach(function(h) {
        if (visible) {
          h.classList.remove('hidden');
        } else {
          h.classList.add('hidden');
        }
      });
    }

    // Function to toggle edit mode
    function setEditMode(enabled) {
      editMode = enabled;
      if (enabled) {
        modelViewer.classList.add('edit-mode');
        modelViewer.removeAttribute('auto-rotate');
      } else {
        modelViewer.classList.remove('edit-mode');
        modelViewer.setAttribute('auto-rotate', '');
      }
    }

    // Function to toggle labels always visible
    function toggleLabelsAlwaysVisible(visible) {
      var hotspots = document.querySelectorAll('.hotspot');
      hotspots.forEach(function(h) {
        if (visible) {
          h.classList.add('show-label');
        } else {
          h.classList.remove('show-label');
        }
      });
    }
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
            if (!_drawMode && !_annotationEditMode) ...[
              // Annotation toggle (only if there are any annotations)
              if (_allAnnotations.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _showAnnotations ? Icons.label : Icons.label_off_outlined,
                    color: _showAnnotations ? Colors.green : null,
                  ),
                  tooltip: _showAnnotations ? 'Hide annotations' : 'Show annotations',
                  onPressed: _toggleAnnotations,
                ),
              // Add annotation mode
              IconButton(
                icon: const Icon(Icons.add_location_alt_outlined),
                tooltip: 'Add annotations',
                onPressed: _toggleAnnotationEditMode,
              ),
              // Manage custom annotations (only if there are custom annotations)
              if (_customAnnotations.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.edit_location_alt),
                  tooltip: 'Manage annotations',
                  onPressed: _showManageAnnotationsDialog,
                ),
              // Compare with another model
              IconButton(
                icon: const Icon(Icons.compare_arrows),
                tooltip: 'Compare with...',
                onPressed: _showCompareModelPicker,
              ),
              // Show/hide drawings toggle (only if there are drawings)
              if (_strokes.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _showDrawings ? Icons.visibility : Icons.visibility_off,
                    color: _showDrawings ? Colors.blue : null,
                  ),
                  tooltip: _showDrawings ? 'Hide drawings' : 'Show drawings',
                  onPressed: () => setState(() => _showDrawings = !_showDrawings),
                ),
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
          // Draw mode indicator - tappable to exit (hidden during screenshot capture)
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
                          '| Tap to unlock camera',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Existing drawings shown even when not in draw mode (respects visibility toggle)
          if (!_drawMode && _strokes.isNotEmpty && _showDrawings)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DrawingPainter(strokes: _strokes),
                  size: Size.infinite,
                ),
              ),
            ),
          // Annotation edit mode indicator
          if (_annotationEditMode && !_hideUIForCapture)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _toggleAnnotationEditMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
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
                        Icon(Icons.add_location_alt, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Tap on model to add annotation',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '| Tap to exit',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Zoom controls - only show when not in draw mode or edit mode
          if (!_drawMode && !_annotationEditMode)
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

// Stateful dialog for saved images with selection mode
class _SavedImagesDialog extends StatefulWidget {
  final List<File> files;
  final Function(File) onShowFullImage;
  final VoidCallback onDeleted;

  const _SavedImagesDialog({
    required this.files,
    required this.onShowFullImage,
    required this.onDeleted,
  });

  @override
  State<_SavedImagesDialog> createState() => _SavedImagesDialogState();
}

class _SavedImagesDialogState extends State<_SavedImagesDialog> {
  bool _selectionMode = false;
  Set<String> _selectedPaths = {};
  late List<File> _files;

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedPaths.clear();
      }
    });
  }

  void _toggleSelection(File file) {
    setState(() {
      if (_selectedPaths.contains(file.path)) {
        _selectedPaths.remove(file.path);
      } else {
        _selectedPaths.add(file.path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedPaths.length == _files.length) {
        _selectedPaths.clear();
      } else {
        _selectedPaths = _files.map((f) => f.path).toSet();
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedPaths.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selectedPaths.length} image${_selectedPaths.length > 1 ? 's' : ''}?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete selected files
    for (final path in _selectedPaths) {
      try {
        await File(path).delete();
      } catch (_) {}
    }

    // Update list
    setState(() {
      _files.removeWhere((f) => _selectedPaths.contains(f.path));
      _selectedPaths.clear();
      _selectionMode = false;
    });

    if (_files.isEmpty) {
      widget.onDeleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selectedPaths.length == _files.length && _files.isNotEmpty;

    return Dialog(
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
                Expanded(
                  child: Text(
                    _selectionMode
                        ? '${_selectedPaths.length} selected'
                        : 'Saved Annotations (${_files.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_selectionMode) ...[
                  // Select All button
                  TextButton.icon(
                    onPressed: _selectAll,
                    icon: Icon(
                      allSelected ? Icons.deselect : Icons.select_all,
                      size: 20,
                    ),
                    label: Text(allSelected ? 'None' : 'All'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  // Delete selected
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete selected',
                    onPressed: _selectedPaths.isNotEmpty ? _deleteSelected : null,
                  ),
                ] else ...[
                  // Enter selection mode
                  IconButton(
                    icon: const Icon(Icons.checklist),
                    tooltip: 'Select multiple',
                    onPressed: _toggleSelectionMode,
                  ),
                ],
                IconButton(
                  icon: Icon(_selectionMode ? Icons.close : Icons.close),
                  onPressed: _selectionMode
                      ? _toggleSelectionMode
                      : () => Navigator.pop(context),
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
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final isSelected = _selectedPaths.contains(file.path);
                return GestureDetector(
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelection(file);
                    } else {
                      widget.onShowFullImage(file);
                    }
                  },
                  onLongPress: () {
                    if (!_selectionMode) {
                      setState(() {
                        _selectionMode = true;
                        _selectedPaths.add(file.path);
                      });
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(file, fit: BoxFit.cover),
                      ),
                      if (_selectionMode)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color: isSelected ? Colors.white : Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      if (_selectionMode && isSelected)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue, width: 3),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _selectionMode
                  ? 'Tap to select  |  Long press to start selection'
                  : 'Tap to view  |  Long press to select',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}

// Model picker bottom sheet for comparison
class _ModelPickerSheet extends StatefulWidget {
  final Model3DItem currentModel;
  final String currentSystemId;
  final Function(Model3DItem, String) onModelSelected;

  const _ModelPickerSheet({
    required this.currentModel,
    required this.currentSystemId,
    required this.onModelSelected,
  });

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  String? _expandedCategoryId;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Expand current system by default
    _expandedCategoryId = widget.currentSystemId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Model3DCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return Model3DConfig.categories;
    }

    final query = _searchQuery.toLowerCase();
    return Model3DConfig.categories
        .map((category) {
          final filteredModels = category.models.where((model) {
            return model.name.toLowerCase().contains(query) ||
                model.description.toLowerCase().contains(query) ||
                model.tags.any((tag) => tag.toLowerCase().contains(query));
          }).toList();

          if (filteredModels.isEmpty) return null;

          return Model3DCategory(
            id: category.id,
            name: category.name,
            description: category.description,
            icon: category.icon,
            color: category.color,
            models: filteredModels,
          );
        })
        .whereType<Model3DCategory>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.compare_arrows, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Compare with...',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Current: ${widget.currentModel.name}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search models...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const Divider(height: 1),
          // Categories and models list
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No models found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isExpanded = _expandedCategoryId == category.id ||
                          _searchQuery.isNotEmpty;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category header
                          InkWell(
                            onTap: () {
                              setState(() {
                                _expandedCategoryId =
                                    _expandedCategoryId == category.id
                                        ? null
                                        : category.id;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              color: category.color.withOpacity(0.1),
                              child: Row(
                                children: [
                                  Text(category.icon, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: category.color.withOpacity(0.9),
                                          ),
                                        ),
                                        Text(
                                          '${category.models.length} models',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Models in category
                          if (isExpanded)
                            ...category.models.map((model) {
                              final isCurrent =
                                  model.id == widget.currentModel.id;
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? Colors.blue.shade100
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isCurrent
                                        ? Icons.check
                                        : Icons.view_in_ar,
                                    size: 20,
                                    color: isCurrent
                                        ? Colors.blue
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                title: Text(
                                  model.name,
                                  style: TextStyle(
                                    fontWeight:
                                        isCurrent ? FontWeight.bold : null,
                                    color: isCurrent ? Colors.blue : null,
                                  ),
                                ),
                                subtitle: Text(
                                  model.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: isCurrent
                                    ? Chip(
                                        label: const Text(
                                          'Current',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor: Colors.blue.shade50,
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      )
                                    : const Icon(Icons.chevron_right),
                                enabled: !isCurrent,
                                onTap: isCurrent
                                    ? null
                                    : () => widget.onModelSelected(
                                        model, category.id),
                              );
                            }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Dialog to add a new annotation
class _AddAnnotationDialog extends StatefulWidget {
  final String position;
  final String normal;

  const _AddAnnotationDialog({
    required this.position,
    required this.normal,
  });

  @override
  State<_AddAnnotationDialog> createState() => _AddAnnotationDialogState();
}

class _AddAnnotationDialogState extends State<_AddAnnotationDialog> {
  final _labelController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _positionController = TextEditingController();
  final _normalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _positionController.text = widget.position;
    _normalController.text = widget.normal;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descriptionController.dispose();
    _positionController.dispose();
    _normalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_location_alt, color: Colors.green),
          SizedBox(width: 10),
          Text('Add Annotation'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Label *',
                hintText: 'e.g. Fundus, Fibroid, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Additional details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Position (x y z)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Normal (x y z)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _normalController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final label = _labelController.text.trim();
            if (label.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Label is required')),
              );
              return;
            }
            Navigator.pop(context, {
              'label': label,
              'description': _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              'position': _positionController.text.trim(),
              'normal': _normalController.text.trim(),
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Dialog to manage custom annotations
class _ManageAnnotationsDialog extends StatelessWidget {
  final List<ModelAnnotation> customAnnotations;
  final Function(ModelAnnotation) onDelete;
  final VoidCallback onDeleteAll;

  const _ManageAnnotationsDialog({
    required this.customAnnotations,
    required this.onDelete,
    required this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.edit_location_alt, size: 22, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Custom Annotations (${customAnnotations.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                if (customAnnotations.length > 1)
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete All?'),
                          content: Text('Delete all ${customAnnotations.length} custom annotations?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                                onDeleteAll();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Delete All', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                    label: const Text('Clear All', style: TextStyle(color: Colors.red)),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: customAnnotations.length,
              itemBuilder: (context, index) {
                final annotation = customAnnotations[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on, color: Colors.blue, size: 20),
                    ),
                    title: Text(
                      annotation.label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (annotation.description != null)
                          Text(
                            annotation.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        Text(
                          'pos: ${annotation.position}',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Annotation?'),
                            content: Text('Delete "${annotation.label}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.pop(context);
                                  onDelete(annotation);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    isThreeLine: annotation.description != null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Blue dots are custom annotations, green are preset',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
