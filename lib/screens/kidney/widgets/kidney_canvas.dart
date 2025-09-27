import 'package:flutter/material.dart';
import '../../../models/marker.dart';
import '../../../models/condition_tool.dart';
import 'dart:math' as math;

class KidneyCanvas extends StatefulWidget {
  final String selectedPreset;
  final List<Marker> markers;
  final int? selectedMarkerIndex;
  final String selectedTool;
  final List<ConditionTool> tools;
  final double zoom;
  final Offset pan;
  final Function(Marker) onMarkerAdded;
  final Function(int) onMarkerSelected;
  final Function(int, Offset) onMarkerMoved;
  final Function(int, double) onMarkerResized;
  final Function(Offset) onPanChanged;

  const KidneyCanvas({
    super.key,
    required this.selectedPreset,
    required this.markers,
    required this.selectedMarkerIndex,
    required this.selectedTool,
    required this.tools,
    required this.zoom,
    required this.pan,
    required this.onMarkerAdded,
    required this.onMarkerSelected,
    required this.onMarkerMoved,
    required this.onMarkerResized,
    required this.onPanChanged,
  });

  @override
  State<KidneyCanvas> createState() => _KidneyCanvasState();
}

class _KidneyCanvasState extends State<KidneyCanvas> {
  Offset? _lastPanPoint;

  // Map presets to actual kidney image paths
  final Map<String, String> _presetImages = {
    'anatomical': 'assets/images/kidney_anatomical.png',
    'simple': 'assets/images/kidney_simple.png',
    'crossSection': 'assets/images/kidney_cross_section.png',
    'nephron': 'assets/images/kidney_nephron.png',
    'polycystic': 'assets/images/kidney_polycystic.png',
    'pyelonephritis': 'assets/images/kidney_pyelonephritis.png',
    'glomerulonephritis': 'assets/images/kidney_glomerulonephritis.png',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 400,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background image - only responds to gestures when pan tool is selected
          Transform.translate(
            offset: widget.pan,
            child: Transform.scale(
              scale: widget.zoom,
              child: Container(
                width: 600,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildKidneyImage(),
                ),
              ),
            ),
          ),

          // Pan gesture layer - ONLY when pan tool is selected
          if (widget.selectedTool == 'pan')
            Positioned.fill(
              child: GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                onTap: () => widget.onMarkerSelected(-1), // Deselect markers
                child: Container(color: Colors.transparent),
              ),
            ),

          // Marker placement layer - ONLY when NOT using pan tool
          if (widget.selectedTool != 'pan')
            Positioned.fill(
              child: GestureDetector(
                onTapDown: _handleTapDown,
                child: Container(color: Colors.transparent),
              ),
            ),

          // Draggable markers - these should always be on top
          ...widget.markers.asMap().entries.map((entry) {
            final index = entry.key;
            final marker = entry.value;
            return _buildDraggableMarker(marker, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildKidneyImage() {
    final imagePath = _presetImages[widget.selectedPreset] ?? _presetImages['anatomical']!;

    return Image.asset(
      imagePath,
      width: 600,
      height: 400,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackDiagram();
      },
    );
  }

  Widget _buildFallbackDiagram() {
    return Container(
      width: 600,
      height: 400,
      color: Colors.grey.shade100,
      child: CustomPaint(
        painter: FallbackKidneyPainter(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Kidney image not found\nShowing fallback diagram',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableMarker(Marker marker, int index) {
    final isSelected = index == widget.selectedMarkerIndex;
    final tool = widget.tools.firstWhere((t) => t.id == marker.type);

    // Calculate screen position including zoom and pan
    final screenX = marker.x * widget.zoom + widget.pan.dx;
    final screenY = marker.y * widget.zoom + widget.pan.dy;
    final screenSize = marker.size * widget.zoom;

    return Positioned(
      left: screenX - screenSize,
      top: screenY - screenSize,
      child: Column(
        children: [
          // MARKER - Keep the same structure as original but without number label
          GestureDetector(
            onTap: () {
              widget.onMarkerSelected(index);
              print('Selected marker $index');
            },
            onPanStart: (details) {
              widget.onMarkerSelected(index);
              print('Started dragging marker $index');
            },
            onPanUpdate: (details) {
              // Convert local pan delta to canvas coordinates
              final canvasDelta = details.delta / widget.zoom;
              final newCanvasX = marker.x + canvasDelta.dx;
              final newCanvasY = marker.y + canvasDelta.dy;

              widget.onMarkerMoved(index, Offset(newCanvasX, newCanvasY));
            },
            onPanEnd: (details) {
              print('Finished dragging marker $index to: (${marker.x}, ${marker.y})');
            },
            child: _buildMarkerShape(
              marker,
              screenSize,
              marker.type == 'cyst' ? Colors.black : tool.color.withOpacity(0.8),
              isSelected ? Colors.black : (marker.type == 'cyst' ? Colors.pink : tool.color),
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerShape(Marker marker, double size, Color fillColor, Color? borderColor, bool isShadow) {
    if (marker.type == 'calculi') {
      return CustomPaint(
        painter: IrregularCalculiPainter(
          color: fillColor,
          size: size,
          isOutline: false,
          borderColor: borderColor,
          seed: marker.id.hashCode,
        ),
      );
    } else if (marker.type == 'cyst') {
      return CustomPaint(
        painter: OvoidCystPainter(
          fillColor: fillColor,
          borderColor: borderColor ?? Colors.pink,
          size: size,
        ),
      );
    } else {
      // Regular circular markers
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fillColor,
          border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
        ),
      );
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.selectedTool != 'pan') {
      // Add new marker
      final canvasX = (details.localPosition.dx - widget.pan.dx) / widget.zoom;
      final canvasY = (details.localPosition.dy - widget.pan.dy) / widget.zoom;

      final tool = widget.tools.firstWhere((t) => t.id == widget.selectedTool);
      final newMarker = Marker(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: widget.selectedTool,
        x: canvasX,
        y: canvasY,
        size: tool.defaultSize,
        label: '${tool.name} ${widget.markers.length + 1}',
      );
      widget.onMarkerAdded(newMarker);
      print('Added marker at canvas position: ($canvasX, $canvasY)');
    } else {
      // Deselect markers when tapping empty space with pan tool
      widget.onMarkerSelected(-1);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (widget.selectedTool == 'pan') {
      _lastPanPoint = details.localPosition;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.selectedTool == 'pan' && _lastPanPoint != null) {
      final delta = details.localPosition - _lastPanPoint!;
      widget.onPanChanged(widget.pan + delta);
      _lastPanPoint = details.localPosition;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPanPoint = null;
  }
}

class IrregularCalculiPainter extends CustomPainter {
  final Color color;
  final double size;
  final bool isOutline;
  final Color? borderColor;
  final int seed;

  IrregularCalculiPainter({
    required this.color,
    required this.size,
    required this.isOutline,
    this.borderColor,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor ?? color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Create irregular, jagged calculi shape using seed for variation
    final path = Path();
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

    // Generate irregular points around center with sharp edges
    final points = <Offset>[];
    final numPoints = 10 + (seed % 6); // 10-15 points for variety

    for (int i = 0; i < numPoints; i++) {
      final angle = (i * math.pi * 2) / numPoints;

      // Create variation in radius for irregular shape using seed
      final baseRadius = size * 0.8;
      final variation = size * 0.6;

      // Use seed to create different patterns for each marker
      final seedFactor1 = (seed * 1.618 + i * 2.718) % 1000 / 1000; // Golden ratio variation
      final seedFactor2 = (seed * 0.577 + i * 1.414) % 1000 / 1000; // Different ratio
      final seedFactor3 = (seed * 2.236 + i * 3.162) % 1000 / 1000; // Another variation

      // Create unique jagged effect for each marker
      final radiusVariation = math.sin(i * (2.0 + seedFactor1)) * variation * 0.5 +
          math.cos(i * (3.0 + seedFactor2)) * variation * 0.3 +
          math.sin(i * (1.5 + seedFactor3)) * variation * 0.2;

      final radius = baseRadius + radiusVariation;

      points.add(Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      ));
    }

    // Create sharp, jagged path
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);

      // Connect points with sharp lines (no smooth curves)
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      path.close();
    }

    // Draw the irregular shape
    canvas.drawPath(path, paint);

    // Draw border if specified
    if (borderColor != null) {
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OvoidCystPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double size;

  OvoidCystPainter({
    required this.fillColor,
    required this.borderColor,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Create round shape (same width and height)
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = size; // Make it perfectly round

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FallbackKidneyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFFF8F8F8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final kidneyPaint = Paint()..color = const Color(0xFFE8B4A0);
    final outlinePaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Simple kidney shapes
    final leftKidney = RRect.fromRectAndRadius(
      const Rect.fromLTWH(120, 120, 120, 160),
      const Radius.circular(60),
    );

    final rightKidney = RRect.fromRectAndRadius(
      const Rect.fromLTWH(360, 120, 120, 160),
      const Radius.circular(60),
    );

    canvas.drawRRect(leftKidney, kidneyPaint);
    canvas.drawRRect(leftKidney, outlinePaint);
    canvas.drawRRect(rightKidney, kidneyPaint);
    canvas.drawRRect(rightKidney, outlinePaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = const TextSpan(
      text: 'Left Kidney',
      style: TextStyle(color: Colors.black87, fontSize: 14),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(140, 290));

    textPainter.text = const TextSpan(
      text: 'Right Kidney',
      style: TextStyle(color: Colors.black87, fontSize: 14),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(380, 290));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}