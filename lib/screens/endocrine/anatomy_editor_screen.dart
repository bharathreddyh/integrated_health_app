// lib/screens/endocrine/anatomy_editor_screen.dart
// Full-screen annotation editor matching your existing UI

import 'package:flutter/material.dart';
import '../../models/endocrine/endocrine_condition.dart';
import 'tabs/canvas_tab.dart'; // For DiagramInfo

class AnatomyEditorScreen extends StatefulWidget {
  final DiagramInfo diagramInfo;
  final EndocrineCondition condition;
  final Function(List<EditorAnnotation>) onSave;

  const AnatomyEditorScreen({
    super.key,
    required this.diagramInfo,
    required this.condition,
    required this.onSave,
  });

  @override
  State<AnatomyEditorScreen> createState() => _AnatomyEditorScreenState();
}

class _AnatomyEditorScreenState extends State<AnatomyEditorScreen> {
  String _selectedTool = 'pan';
  List<EditorAnnotation> _markers = [];
  List<DrawingPath> _drawings = [];
  double _zoom = 1.0;
  bool _showToolsPanel = true;

  // Voice button state
  bool _isListening = false;

  final List<AnnotationTool> _tools = [
    AnnotationTool(
      id: 'pan',
      name: 'Pan Tool',
      icon: Icons.pan_tool,
      color: Colors.grey,
    ),
    AnnotationTool(
      id: 'nodule',
      name: 'Nodule',
      icon: Icons.circle,
      color: Colors.grey.shade700,
    ),
    AnnotationTool(
      id: 'inflammation',
      name: 'Inflammation',
      icon: Icons.circle,
      color: Colors.red,
    ),
    AnnotationTool(
      id: 'calcification',
      name: 'Calcification',
      icon: Icons.circle,
      color: Colors.grey.shade400,
    ),
    AnnotationTool(
      id: 'tumor',
      name: 'Tumor',
      icon: Icons.circle,
      color: Colors.purple,
    ),
    AnnotationTool(
      id: 'cyst',
      name: 'Cyst',
      icon: Icons.circle,
      color: Colors.blue,
    ),
    AnnotationTool(
      id: 'arrow',
      name: 'Arrow',
      icon: Icons.arrow_forward,
      color: Colors.black,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2563EB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Row(
                children: [
                  // Canvas Area
                  Expanded(child: _buildCanvasArea()),

                  // Tools Panel (Right Side)
                  if (_showToolsPanel) _buildToolsPanel(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF2563EB),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _handleBack(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.diagramInfo.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_markers.length} markers, ${_drawings.length} drawings',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea() {
    return Container(
      color: Colors.grey.shade100,
      child: Stack(
        children: [
          // Voice Control Button (Floating)
          Positioned(
            left: 16,
            top: 16,
            child: FloatingActionButton(
              onPressed: _toggleVoice,
              backgroundColor: _isListening
                  ? const Color(0xFF2563EB)
                  : Colors.white,
              child: Icon(
                Icons.mic,
                color: _isListening ? Colors.white : const Color(0xFF2563EB),
              ),
            ),
          ),

          // Main Canvas
          Center(
            child: GestureDetector(
              onTapDown: (details) => _handleCanvasTap(details.localPosition),
              child: Container(
                margin: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Base Image
                      _buildBaseImage(),

                      // Markers Overlay
                      ..._markers.map((marker) => _buildMarker(marker)),

                      // Drawings Overlay
                      CustomPaint(
                        painter: DrawingsPainter(_drawings),
                        size: Size.infinite,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Zoom Info
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                'Zoom: ${(_zoom * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Annotations Count
          Positioned(
            left: 16,
            bottom: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                '${_markers.length + _drawings.length} annotations',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseImage() {
    if (widget.diagramInfo.hasImage) {
      return Image.asset(
        widget.diagramInfo.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 100,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildMarker(EditorAnnotation marker) {
    return Positioned(
      left: marker.x,
      top: marker.y,
      child: GestureDetector(
        onTap: () => _selectMarker(marker),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: marker.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${_markers.indexOf(marker) + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolsPanel() {
    return Container(
      width: 360,
      color: const Color(0xFF2563EB),
      child: Column(
        children: [
          // Panel Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.construction, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'Tools & Controls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _showToolsPanel = false),
                ),
              ],
            ),
          ),

          // Tools List
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Annotation Tools Section
                  _buildToolSection(
                    'Annotation Tools',
                    Icons.edit,
                    _tools.length,
                  ),
                  const SizedBox(height: 12),

                  ..._tools.map((tool) => _buildToolButton(tool)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolSection(String title, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildToolButton(AnnotationTool tool) {
    final isSelected = _selectedTool == tool.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? const Color(0xFFE0E7FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _selectedTool = tool.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  tool.icon,
                  size: 20,
                  color: tool.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tool.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey.shade700,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Color(0xFF2563EB),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Toggle Tools Button (if panel hidden)
          if (!_showToolsPanel)
            ElevatedButton.icon(
              onPressed: () => setState(() => _showToolsPanel = true),
              icon: const Icon(Icons.construction, size: 18),
              label: const Text('Show Tools'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
              ),
            ),

          const Spacer(),

          // Cancel Button
          OutlinedButton(
            onPressed: _handleBack,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text('Cancel'),
          ),

          const SizedBox(width: 12),

          // Save Button
          ElevatedButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.check, size: 20),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCanvasTap(Offset position) {
    if (_selectedTool == 'pan') return;

    final tool = _tools.firstWhere((t) => t.id == _selectedTool);

    setState(() {
      _markers.add(EditorAnnotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        x: position.dx - 15,
        y: position.dy - 15,
        type: tool.id,
        color: tool.color,
      ));
    });
  }

  void _selectMarker(EditorAnnotation marker) {
    // Show options to delete or edit
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Marker #${_markers.indexOf(marker) + 1}'),
        content: Text('Type: ${marker.type}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _markers.remove(marker));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleVoice() {
    setState(() => _isListening = !_isListening);
    // TODO: Implement actual voice control
  }

  void _handleBack() {
    if (_markers.isNotEmpty || _drawings.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved annotations. Do you want to save before leaving?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleSave();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _handleSave() {
    widget.onSave(_markers);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Annotations saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Models
class AnnotationTool {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  AnnotationTool({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class EditorAnnotation {
  final String id;
  final double x;
  final double y;
  final String type;
  final Color color;

  EditorAnnotation({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.color,
  });
}

class DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class DrawingsPainter extends CustomPainter {
  final List<DrawingPath> paths;

  DrawingsPainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    for (var path in paths) {
      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final pathToDraw = Path();
      if (path.points.isNotEmpty) {
        pathToDraw.moveTo(path.points.first.dx, path.points.first.dy);
        for (var point in path.points.skip(1)) {
          pathToDraw.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(pathToDraw, paint);
    }
  }

  @override
  bool shouldRepaint(DrawingsPainter oldDelegate) => true;
}