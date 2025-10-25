// lib/screens/endocrine/canvas_editor_screen.dart
// COMPLETE CANVAS EDITOR WITH MARKER LABELS, EDIT, AND VIEW CONTROLS

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../../models/endocrine/endocrine_condition.dart';
import '../../config/thyroid_disease_config.dart';
import '../../config/thyroid_canvas_config.dart';
import '../../models/marker.dart';
import '../../models/drawing_path.dart';
import 'dart:math' as math;

class CanvasEditorScreen extends StatefulWidget {
  final EndocrineCondition condition;
  final ThyroidDiseaseConfig diseaseConfig;
  final String selectedImageId;
  final Function(EndocrineCondition) onSave;

  const CanvasEditorScreen({
    super.key,
    required this.condition,
    required this.diseaseConfig,
    required this.selectedImageId,
    required this.onSave,
  });

  @override
  State<CanvasEditorScreen> createState() => _CanvasEditorScreenState();
}

class _CanvasEditorScreenState extends State<CanvasEditorScreen> {
  List<Marker> _markers = [];
  List<DrawingPath> _drawingPaths = [];
  int? _selectedMarkerIndex;
  int? _selectedPathIndex;

  double _zoom = 1.0;
  Offset _pan = Offset.zero;

  String _selectedTool = 'pan';
  String _selectedDrawingTool = 'none';
  Color _drawingColor = const Color(0xFFDC2626);
  double _strokeWidth = 3.0;

  bool _showToolPanel = true;
  bool _showDrawingPanel = false;
  bool _hasUnsavedChanges = false;

  // Collapsible sections
  bool _isToolsExpanded = true;
  bool _isViewControlsExpanded = false;
  bool _isMarkersExpanded = true;

  final GlobalKey _canvasKey = GlobalKey();
  Offset? _panStart;
  int? _draggingMarkerIndex;
  bool _isResizing = false;
  List<Offset> _currentDrawingPoints = [];

  @override
  void initState() {
    super.initState();
    _loadAnnotations();
  }

  void _loadAnnotations() {
    if (widget.condition.canvasAnnotations != null) {
      final annotations = widget.condition.canvasAnnotations![widget.selectedImageId];
      if (annotations != null) {
        final data = annotations as Map<String, dynamic>;
        setState(() {
          _markers = (data['markers'] as List? ?? [])
              .map((m) => Marker.fromMap(m))
              .toList();
          _drawingPaths = (data['drawingPaths'] as List? ?? [])
              .map((p) => DrawingPath.fromMap(p))
              .toList();
          _zoom = data['zoom'] ?? 1.0;
          _pan = data['pan'] != null
              ? Offset(data['pan']['dx'], data['pan']['dy'])
              : Offset.zero;
        });
      }
    }
  }

  void _saveAnnotations() {
    final updatedAnnotations = Map<String, dynamic>.from(
      widget.condition.canvasAnnotations ?? {},
    );

    updatedAnnotations[widget.selectedImageId] = {
      'imageId': widget.selectedImageId,
      'markers': _markers.map((m) => m.toMap()).toList(),
      'drawingPaths': _drawingPaths.map((p) => p.toMap()).toList(),
      'zoom': _zoom,
      'pan': {'dx': _pan.dx, 'dy': _pan.dy},
      'lastModified': DateTime.now().toIso8601String(),
    };

    final updatedCondition = widget.condition.copyWith(
      canvasAnnotations: updatedAnnotations,
    );

    widget.onSave(updatedCondition);
    Navigator.pop(context, updatedCondition);
  }

  ThyroidImageConfig _getCurrentImage() {
    final allImages = ThyroidCanvasConfig.getImagesForDisease(
      widget.condition.diseaseId,
    );
    return allImages.firstWhere(
          (img) => img.id == widget.selectedImageId,
      orElse: () => ThyroidCanvasConfig.anatomyImages['anterior']!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = _getCurrentImage();

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          return await _showExitConfirmation();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currentImage.name, style: const TextStyle(fontSize: 16)),
              Text(
                '${_markers.length} markers, ${_drawingPaths.length} drawings',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('UNSAVED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: Stack(
          children: [
            // Canvas
            Positioned.fill(
              child: RepaintBoundary(
                key: _canvasKey,
                child: GestureDetector(
                  onTapDown: _handleTapDown,
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..translate(_pan.dx, _pan.dy)
                            ..scale(_zoom),
                          child: Image.asset(
                            currentImage.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, size: 64, color: Colors.grey.shade500),
                                      const SizedBox(height: 16),
                                      Text('Image not found', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ThyroidCanvasPainter(
                            markers: _markers,
                            drawingPaths: _drawingPaths,
                            currentDrawingPoints: _currentDrawingPoints,
                            currentDrawingColor: _drawingColor,
                            currentStrokeWidth: _strokeWidth,
                            selectedMarkerIndex: _selectedMarkerIndex,
                            selectedPathIndex: _selectedPathIndex,
                            zoom: _zoom,
                            pan: _pan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_showToolPanel) _buildToolPanel(),
            if (_showDrawingPanel) _buildDrawingPanel(),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildToolPanel() {
    return Positioned(
      right: 16,
      top: 16,
      bottom: 80,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Tools & Controls', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => setState(() => _showToolPanel = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Tools Section
                    _buildCollapsibleSection(
                      title: 'Annotation Tools',
                      icon: Icons.edit,
                      isExpanded: _isToolsExpanded,
                      onToggle: () => setState(() => _isToolsExpanded = !_isToolsExpanded),
                      badge: '${ThyroidCanvasConfig.tools.length}',
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: ThyroidCanvasConfig.tools.map((tool) => _buildToolButton(tool)).toList(),
                        ),
                      ),
                    ),

                    // View Controls Section
                    _buildCollapsibleSection(
                      title: 'View Controls',
                      icon: Icons.zoom_in,
                      isExpanded: _isViewControlsExpanded,
                      onToggle: () => setState(() => _isViewControlsExpanded = !_isViewControlsExpanded),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Zoom slider
                            Row(
                              children: [
                                const Icon(Icons.zoom_out, size: 20, color: Colors.grey),
                                Expanded(
                                  child: Slider(
                                    value: _zoom,
                                    min: 0.5,
                                    max: 3.0,
                                    divisions: 25,
                                    label: '${(_zoom * 100).toInt()}%',
                                    onChanged: (value) => setState(() => _zoom = value),
                                  ),
                                ),
                                const Icon(Icons.zoom_in, size: 20, color: Colors.grey),
                              ],
                            ),
                            Text('Zoom: ${(_zoom * 100).toInt()}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 12),

                            // Zoom buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => setState(() => _zoom = (_zoom - 0.1).clamp(0.5, 3.0)),
                                    icon: const Icon(Icons.remove, size: 16),
                                    label: const Text('Out', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => setState(() => _zoom = (_zoom + 0.1).clamp(0.5, 3.0)),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('In', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Reset view
                            OutlinedButton.icon(
                              onPressed: () => setState(() {
                                _zoom = 1.0;
                                _pan = Offset.zero;
                              }),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reset View', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Markers Section
                    if (_markers.isNotEmpty)
                      _buildCollapsibleSection(
                        title: 'Markers',
                        icon: Icons.location_on,
                        isExpanded: _isMarkersExpanded,
                        onToggle: () => setState(() => _isMarkersExpanded = !_isMarkersExpanded),
                        badge: '${_markers.length}',
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: _markers.asMap().entries.map((entry) {
                              return _buildMarkerItem(entry.key, entry.value);
                            }).toList(),
                          ),
                        ),
                      ),

                    // Drawing Tools
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showDrawingPanel = !_showDrawingPanel;
                            if (_showDrawingPanel) {
                              _selectedDrawingTool = 'pen';
                              _selectedTool = 'pan';
                            } else {
                              _selectedDrawingTool = 'none';
                            }
                          });
                        },
                        icon: Icon(_showDrawingPanel ? Icons.brush : Icons.brush_outlined, size: 16),
                        label: Text(_showDrawingPanel ? 'Drawing Mode' : 'Enable Drawing', style: const TextStyle(fontSize: 12)),
                      ),
                    ),

                    // Clear buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        children: [
                          if (_markers.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () => _confirmClear('markers'),
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.orange),
                              label: const Text('Clear Markers', style: TextStyle(fontSize: 12, color: Colors.orange)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                            ),
                          if (_drawingPaths.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => _confirmClear('drawings'),
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.blue),
                              label: const Text('Clear Drawings', style: TextStyle(fontSize: 12, color: Colors.blue)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)),
                            ),
                          ],
                          if (_markers.isNotEmpty || _drawingPaths.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => _confirmClear('all'),
                              icon: const Icon(Icons.clear_all, size: 16, color: Colors.red),
                              label: const Text('Clear All', style: TextStyle(fontSize: 12, color: Colors.red)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                            ),
                          ],
                        ],
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

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badge, style: TextStyle(fontSize: 9, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 8),
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey.shade600, size: 20),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) child,
        ],
      ),
    );
  }

  Widget _buildToolButton(tool) {
    final isSelected = _selectedTool == tool.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? tool.color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTool = tool.id;
              if (tool.id != 'pan') {
                _selectedDrawingTool = 'none';
                _showDrawingPanel = false;
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? tool.color : Colors.grey.shade300, width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (tool.id == 'pan')
                  Icon(Icons.pan_tool, size: 16, color: isSelected ? tool.color : Colors.grey.shade600)
                else
                  Container(width: 16, height: 16, decoration: BoxDecoration(color: tool.color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(tool.name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                if (isSelected) Icon(Icons.check_circle, size: 14, color: tool.color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerItem(int index, Marker marker) {
    final isSelected = _selectedMarkerIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() {
            _selectedMarkerIndex = index;
            _selectedTool = 'pan';
          }),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: marker.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(marker.type.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      if (marker.label.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(marker.label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                if (isSelected) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                    onPressed: () => _showEditMarkerDialog(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    onPressed: () => _deleteMarker(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditMarkerDialog(int index) {
    final marker = _markers[index];
    final labelController = TextEditingController(text: marker.label);
    double size = marker.size;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: marker.color, shape: BoxShape.circle),
                child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Edit ${marker.type.toUpperCase()}', style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  hintText: 'Enter label (optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: size,
                      min: 8,
                      max: 30,
                      divisions: 22,
                      label: size.round().toString(),
                      onChanged: (value) => setDialogState(() => size = value),
                    ),
                  ),
                  SizedBox(width: 40, child: Text(size.round().toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _markers[index] = Marker(
                    type: marker.type,
                    x: marker.x,
                    y: marker.y,
                    size: size,
                    color: marker.color,
                    label: labelController.text,
                  );
                  _hasUnsavedChanges = true;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMarker(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Marker'),
        content: const Text('Are you sure you want to delete this marker?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _markers.removeAt(index);
                _selectedMarkerIndex = null;
                _hasUnsavedChanges = true;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClear(String type) {
    String title, message;
    VoidCallback action;

    switch (type) {
      case 'markers':
        title = 'Clear Markers';
        message = 'Remove all ${_markers.length} markers?';
        action = () => setState(() {
          _markers.clear();
          _selectedMarkerIndex = null;
          _hasUnsavedChanges = true;
        });
        break;
      case 'drawings':
        title = 'Clear Drawings';
        message = 'Remove all ${_drawingPaths.length} drawings?';
        action = () => setState(() {
          _drawingPaths.clear();
          _selectedPathIndex = null;
          _hasUnsavedChanges = true;
        });
        break;
      case 'all':
      default:
        title = 'Clear All';
        message = 'Remove all markers and drawings?';
        action = () => setState(() {
          _markers.clear();
          _drawingPaths.clear();
          _selectedMarkerIndex = null;
          _selectedPathIndex = null;
          _hasUnsavedChanges = true;
        });
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              action();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingPanel() {
    return Positioned(
      left: 16,
      top: 16,
      bottom: 80,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Drawing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() {
                    _showDrawingPanel = false;
                    _selectedDrawingTool = 'none';
                  }),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Text('Color', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Colors.black,
                const Color(0xFFDC2626),
                const Color(0xFF2563EB),
                const Color(0xFF16A34A),
                const Color(0xFFF97316),
                const Color(0xFF7C3AED),
              ].map((color) => _buildColorButton(color)).toList(),
            ),
            const SizedBox(height: 12),

            const Text('Width', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            Slider(
              value: _strokeWidth,
              min: 1,
              max: 10,
              divisions: 9,
              label: _strokeWidth.round().toString(),
              onChanged: (value) => setState(() => _strokeWidth = value),
            ),

            if (_drawingPaths.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    if (_drawingPaths.isNotEmpty) {
                      _drawingPaths.removeLast();
                      _hasUnsavedChanges = true;
                    }
                  });
                },
                icon: const Icon(Icons.undo, size: 14),
                label: const Text('Undo', style: TextStyle(fontSize: 11)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _drawingColor == color;
    return GestureDetector(
      onTap: () => setState(() => _drawingColor = color),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade400, width: isSelected ? 3 : 1),
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Zoom: ${(_zoom * 100).toInt()}%', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text('${_markers.length + _drawingPaths.length} annotations', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),

            if (!_showToolPanel)
              IconButton(
                onPressed: () => setState(() => _showToolPanel = true),
                icon: const Icon(Icons.build_circle, size: 24),
                color: const Color(0xFF2563EB),
              ),

            const SizedBox(width: 8),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontSize: 12))),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _saveAnnotations,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Save', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    if (_selectedDrawingTool == 'pen') {
      for (int i = _drawingPaths.length - 1; i >= 0; i--) {
        if (_drawingPaths[i].containsPoint(details.localPosition, context.size!, _zoom, _pan)) {
          setState(() => _selectedPathIndex = i);
          return;
        }
      }
      setState(() => _selectedPathIndex = null);
    }

    if (_selectedTool == 'pan') {
      final tappedMarkerIndex = _findMarkerAtPosition(details.localPosition);
      setState(() => _selectedMarkerIndex = tappedMarkerIndex);
    } else if (_selectedDrawingTool == 'none') {
      final tool = ThyroidCanvasConfig.tools.firstWhere((t) => t.id == _selectedTool);
      final canvasSize = context.size!;
      final marker = Marker.fromScreenCoordinates(
        type: tool.id,
        screenPosition: details.localPosition,
        canvasSize: canvasSize,
        zoom: _zoom,
        pan: _pan,
        size: tool.defaultSize.toDouble(),
        color: tool.color,
      );
      setState(() {
        _markers.add(marker);
        _hasUnsavedChanges = true;
      });
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (_selectedDrawingTool == 'pen') {
      setState(() => _currentDrawingPoints = [details.localPosition]);
      return;
    }

    if (_selectedTool == 'pan') {
      if (_selectedMarkerIndex != null) {
        final resizeHandleIndex = _findResizeHandleAtPosition(details.localPosition);
        if (resizeHandleIndex != -1) {
          setState(() => _isResizing = true);
          return;
        }
      }

      final tappedMarkerIndex = _findMarkerAtPosition(details.localPosition);
      if (tappedMarkerIndex != -1) {
        setState(() {
          _draggingMarkerIndex = tappedMarkerIndex;
          _selectedMarkerIndex = tappedMarkerIndex;
        });
      } else {
        setState(() => _panStart = details.localPosition);
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_selectedDrawingTool == 'pen') {
      setState(() => _currentDrawingPoints.add(details.localPosition));
      return;
    }

    if (_isResizing && _selectedMarkerIndex != null) {
      final marker = _markers[_selectedMarkerIndex!];
      final center = Offset(
        (marker.x * context.size!.width * _zoom) + _pan.dx,
        (marker.y * context.size!.height * _zoom) + _pan.dy,
      );
      final distance = (details.localPosition - center).distance;
      setState(() {
        _markers[_selectedMarkerIndex!] = Marker(
          type: marker.type,
          x: marker.x,
          y: marker.y,
          size: (distance / _zoom * 2).clamp(8.0, 30.0),
          color: marker.color,
          label: marker.label,
        );
        _hasUnsavedChanges = true;
      });
    } else if (_draggingMarkerIndex != null) {
      final marker = _markers[_draggingMarkerIndex!];
      setState(() {
        _markers[_draggingMarkerIndex!] = Marker(
          type: marker.type,
          x: ((marker.x * context.size!.width * _zoom) + details.delta.dx) / (_zoom * context.size!.width),
          y: ((marker.y * context.size!.height * _zoom) + details.delta.dy) / (_zoom * context.size!.height),
          size: marker.size,
          color: marker.color,
          label: marker.label,
        );
        _hasUnsavedChanges = true;
      });
    } else if (_panStart != null) {
      setState(() => _pan = Offset(_pan.dx + details.delta.dx, _pan.dy + details.delta.dy));
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_currentDrawingPoints.isNotEmpty && _currentDrawingPoints.length > 1) {
      final path = DrawingPath.fromScreenCoordinates(
        screenPoints: List.from(_currentDrawingPoints),
        canvasSize: context.size!,
        zoom: _zoom,
        pan: _pan,
        color: _drawingColor,
        strokeWidth: _strokeWidth,
      );
      setState(() {
        _drawingPaths.add(path);
        _currentDrawingPoints = [];
        _hasUnsavedChanges = true;
      });
      return;
    }

    setState(() {
      _draggingMarkerIndex = null;
      _isResizing = false;
      _panStart = null;
      _currentDrawingPoints = [];
    });
  }

  int _findMarkerAtPosition(Offset position) {
    for (int i = _markers.length - 1; i >= 0; i--) {
      final marker = _markers[i];
      final center = Offset(
        (marker.x * context.size!.width * _zoom) + _pan.dx,
        (marker.y * context.size!.height * _zoom) + _pan.dy,
      );
      if ((position - center).distance <= (marker.size * _zoom / 2)) {
        return i;
      }
    }
    return -1;
  }

  int _findResizeHandleAtPosition(Offset position) {
    if (_selectedMarkerIndex == null) return -1;

    final marker = _markers[_selectedMarkerIndex!];
    final scaledSize = marker.size * _zoom;
    final center = Offset(
      (marker.x * context.size!.width * _zoom) + _pan.dx,
      (marker.y * context.size!.height * _zoom) + _pan.dy,
    );
    final handlePos = Offset(center.dx + scaledSize / 2, center.dy + scaledSize / 2);

    return (position - handlePos).distance <= 10.0 ? 0 : -1;
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save before exiting?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
          ElevatedButton(
            onPressed: () {
              _saveAnnotations();
              Navigator.pop(context, false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ) ?? false;
  }
}

// Custom Painter for Thyroid Canvas
class ThyroidCanvasPainter extends CustomPainter {
  final List<Marker> markers;
  final List<DrawingPath> drawingPaths;
  final List<Offset> currentDrawingPoints;
  final Color currentDrawingColor;
  final double currentStrokeWidth;
  final int? selectedMarkerIndex;
  final int? selectedPathIndex;
  final double zoom;
  final Offset pan;

  ThyroidCanvasPainter({
    required this.markers,
    required this.drawingPaths,
    required this.currentDrawingPoints,
    required this.currentDrawingColor,
    required this.currentStrokeWidth,
    this.selectedMarkerIndex,
    this.selectedPathIndex,
    required this.zoom,
    required this.pan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw drawings first
    for (int i = 0; i < drawingPaths.length; i++) {
      final path = drawingPaths[i];
      final isSelected = i == selectedPathIndex;

      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.strokeWidth * zoom
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final drawPath = Path();
      final screenPoints = path.points.map((p) {
        return Offset(
          (p.dx * size.width * zoom) + pan.dx,
          (p.dy * size.height * zoom) + pan.dy,
        );
      }).toList();

      if (screenPoints.isNotEmpty) {
        drawPath.moveTo(screenPoints[0].dx, screenPoints[0].dy);
        for (int j = 1; j < screenPoints.length; j++) {
          drawPath.lineTo(screenPoints[j].dx, screenPoints[j].dy);
        }
        canvas.drawPath(drawPath, paint);

        if (isSelected) {
          final highlightPaint = Paint()
            ..color = Colors.yellow
            ..strokeWidth = (path.strokeWidth + 2) * zoom
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;
          canvas.drawPath(drawPath, highlightPaint);
        }
      }
    }

    // Draw current path being drawn
    if (currentDrawingPoints.length > 1) {
      final paint = Paint()
        ..color = currentDrawingColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final drawPath = Path();
      drawPath.moveTo(currentDrawingPoints[0].dx, currentDrawingPoints[0].dy);
      for (int i = 1; i < currentDrawingPoints.length; i++) {
        drawPath.lineTo(currentDrawingPoints[i].dx, currentDrawingPoints[i].dy);
      }
      canvas.drawPath(drawPath, paint);
    }

    // Draw markers with labels
    for (int i = 0; i < markers.length; i++) {
      final marker = markers[i];
      final isSelected = i == selectedMarkerIndex;
      final center = Offset(
        (marker.x * size.width * zoom) + pan.dx,
        (marker.y * size.height * zoom) + pan.dy,
      );
      final scaledSize = marker.size * zoom;

      // Draw marker
      final paint = Paint()..color = marker.color..style = PaintingStyle.fill;
      canvas.drawCircle(center, scaledSize / 2, paint);

      final outlinePaint = Paint()
        ..color = isSelected ? Colors.blue : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 2.0;
      canvas.drawCircle(center, scaledSize / 2, outlinePaint);

      // Draw marker number
      final numberPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: (scaledSize * 0.5).clamp(10.0, 16.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      numberPainter.layout();
      numberPainter.paint(
        canvas,
        Offset(center.dx - numberPainter.width / 2, center.dy - numberPainter.height / 2),
      );

      // Draw label if exists
      if (marker.label.isNotEmpty) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: marker.label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              backgroundColor: Colors.white.withOpacity(0.9),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();

        final labelBg = Paint()..color = Colors.white.withOpacity(0.9);
        final labelRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center.dx - labelPainter.width / 2 - 4,
            center.dy + scaledSize / 2 + 4,
            labelPainter.width + 8,
            labelPainter.height + 4,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(labelRect, labelBg);
        labelPainter.paint(
          canvas,
          Offset(center.dx - labelPainter.width / 2, center.dy + scaledSize / 2 + 6),
        );
      }

      // Draw selection indicator
      if (isSelected) {
        final selectionPaint = Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(center, scaledSize / 2 + 5, selectionPaint);

        // Draw resize handle
        final handlePaint = Paint()..color = Colors.blue..style = PaintingStyle.fill;
        final handleOutlinePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final handlePos = Offset(center.dx + scaledSize / 2, center.dy + scaledSize / 2);
        canvas.drawCircle(handlePos, 8.0, handlePaint);
        canvas.drawCircle(handlePos, 8.0, handleOutlinePaint);

        final iconPainter = TextPainter(
          text: const TextSpan(
            text: '⇲',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        iconPainter.layout();
        iconPainter.paint(
          canvas,
          Offset(handlePos.dx - iconPainter.width / 2, handlePos.dy - iconPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(ThyroidCanvasPainter oldDelegate) => true;
}