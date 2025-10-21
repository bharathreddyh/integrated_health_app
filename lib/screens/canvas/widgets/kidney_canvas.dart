// lib/screens/kidney/widgets/kidney_canvas.dart - UPDATED WITH CUSTOM SHAPES

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/marker.dart';
import '../../../models/condition_tool.dart';
import '../../../models/drawing_path.dart';

class KidneyCanvas extends StatefulWidget {
  final String selectedPreset;
  final List<Marker> markers;
  final List<DrawingPath> drawingPaths;
  final int? selectedMarkerIndex;
  final int? selectedPathIndex;
  final String selectedTool;
  final List<ConditionTool> tools;
  final double zoom;
  final Offset pan;
  final Function(Marker) onMarkerAdded;
  final Function(int) onMarkerSelected;
  final Function(int, Offset) onMarkerMoved;
  final Function(int, double) onMarkerResized;
  final Function(Offset) onPanChanged;
  final bool waitingForClick;
  final String? pendingToolType;
  final double? pendingToolSize;

  final String selectedDrawingTool;
  final Color drawingColor;
  final double strokeWidth;
  final Function(DrawingPath) onDrawingPathAdded;
  final Function(int) onDrawingPathSelected;

  const KidneyCanvas({
    super.key,
    required this.selectedPreset,
    required this.markers,
    this.drawingPaths = const [],
    required this.selectedMarkerIndex,
    this.selectedPathIndex,
    required this.selectedTool,
    required this.tools,
    required this.zoom,
    required this.pan,
    required this.onMarkerAdded,
    required this.onMarkerSelected,
    required this.onMarkerMoved,
    required this.onMarkerResized,
    required this.onPanChanged,
    this.waitingForClick = false,
    this.pendingToolType,
    this.pendingToolSize,
    required this.selectedDrawingTool,
    required this.drawingColor,
    required this.strokeWidth,
    required this.onDrawingPathAdded,
    required this.onDrawingPathSelected,
  });

  @override
  State<KidneyCanvas> createState() => _KidneyCanvasState();
}

class _KidneyCanvasState extends State<KidneyCanvas> {
  Offset? _panStart;
  Offset? _currentPan;
  int? _draggingMarkerIndex;
  bool _isResizing = false;
  List<Offset> _currentDrawingPoints = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: Transform(
              transform: Matrix4.identity()
                ..translate(widget.pan.dx, widget.pan.dy)
                ..scale(widget.zoom),
              child: Image.asset(
                _getImagePath(widget.selectedPreset),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Image not found', style: TextStyle(color: Colors.grey.shade600)),
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
              painter: CombinedPainter(
                markers: widget.markers,
                drawingPaths: widget.drawingPaths,
                currentDrawingPoints: _currentDrawingPoints,
                currentDrawingColor: widget.drawingColor,
                currentStrokeWidth: widget.strokeWidth,
                selectedMarkerIndex: widget.selectedMarkerIndex,
                selectedPathIndex: widget.selectedPathIndex,
                zoom: widget.zoom,
                pan: widget.pan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getImagePath(String preset) {
    switch (preset) {
      case 'anatomical': return 'assets/images/kidney_anatomical.png';
      case 'simple': return 'assets/images/kidney_simple.png';
      case 'crossSection': return 'assets/images/kidney_cross_section.png';
      case 'nephron': return 'assets/images/kidney_nephron.png';
      case 'polycystic': return 'assets/images/kidney_polycystic.png';
      case 'pyelonephritis': return 'assets/images/kidney_pyelonephritis.png';
      case 'glomerulonephritis': return 'assets/images/kidney_glomerulonephritis.png';
      default: return 'assets/images/kidney_anatomical.png';
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.selectedDrawingTool == 'pen') {
      for (int i = widget.drawingPaths.length - 1; i >= 0; i--) {
        if (widget.drawingPaths[i].containsPoint(
          details.localPosition,
          context.size!,
          widget.zoom,
          widget.pan,
        )) {
          widget.onDrawingPathSelected(i);
          return;
        }
      }
      widget.onDrawingPathSelected(-1);
    }

    if (widget.waitingForClick && widget.pendingToolType != null) {
      final tool = widget.tools.firstWhere((t) => t.id == widget.pendingToolType);
      final canvasSize = context.size!;
      final marker = Marker.fromScreenCoordinates(
        type: tool.id,
        screenPosition: details.localPosition,
        canvasSize: canvasSize,
        zoom: widget.zoom,
        pan: widget.pan,
        size: widget.pendingToolSize ?? tool.defaultSize.toDouble(),
        color: tool.color,
      );
      widget.onMarkerAdded(marker);
      return;
    }

    if (widget.selectedTool == 'pan') {
      final tappedMarkerIndex = _findMarkerAtPosition(details.localPosition);
      widget.onMarkerSelected(tappedMarkerIndex);
    } else if (widget.selectedDrawingTool == 'none') {
      final tool = widget.tools.firstWhere((t) => t.id == widget.selectedTool);
      final canvasSize = context.size!;
      final marker = Marker.fromScreenCoordinates(
        type: tool.id,
        screenPosition: details.localPosition,
        canvasSize: canvasSize,
        zoom: widget.zoom,
        pan: widget.pan,
        size: tool.defaultSize.toDouble(),
        color: tool.color,
      );
      widget.onMarkerAdded(marker);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_currentDrawingPoints.isNotEmpty) {
      final path = DrawingPath.fromScreenCoordinates(
        screenPoints: List.from(_currentDrawingPoints),
        canvasSize: context.size!,
        zoom: widget.zoom,
        pan: widget.pan,
        color: widget.drawingColor,
        strokeWidth: widget.strokeWidth,
      );
      widget.onDrawingPathAdded(path);
      setState(() => _currentDrawingPoints = []);
      return;
    }

    setState(() {
      _draggingMarkerIndex = null;
      _isResizing = false;
      _panStart = null;
      _currentPan = null;
    });
  }

  void _handlePanStart(DragStartDetails details) {
    if (widget.selectedDrawingTool == 'pen') {
      setState(() {
        _currentDrawingPoints = [details.localPosition];
      });
      return;
    }

    if (widget.selectedTool == 'pan') {
      if (widget.selectedMarkerIndex != null) {
        final resizeHandleIndex = _findResizeHandleAtPosition(details.localPosition);
        if (resizeHandleIndex != -1) {
          setState(() => _isResizing = true);
          return;
        }
      }

      final tappedMarkerIndex = _findMarkerAtPosition(details.localPosition);
      if (tappedMarkerIndex != -1) {
        setState(() => _draggingMarkerIndex = tappedMarkerIndex);
        widget.onMarkerSelected(tappedMarkerIndex);
      } else {
        setState(() {
          _panStart = details.localPosition;
          _currentPan = widget.pan;
        });
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.selectedDrawingTool == 'pen') {
      setState(() {
        _currentDrawingPoints.add(details.localPosition);
      });
      return;
    }

    if (_isResizing && widget.selectedMarkerIndex != null) {
      final canvasSize = context.size!;
      final marker = widget.markers[widget.selectedMarkerIndex!];
      final markerScreenPos = marker.toScreenCoordinates(
        canvasSize: canvasSize,
        zoom: widget.zoom,
        pan: widget.pan,
      );
      final distance = (details.localPosition - markerScreenPos).distance;
      final newSize = (distance * 2).clamp(8.0, 50.0);
      widget.onMarkerResized(widget.selectedMarkerIndex!, newSize);
    } else if (_draggingMarkerIndex != null) {
      final canvasSize = context.size!;
      final marker = widget.markers[_draggingMarkerIndex!];
      final newMarker = Marker.fromScreenCoordinates(
        type: marker.type,
        screenPosition: details.localPosition,
        canvasSize: canvasSize,
        zoom: widget.zoom,
        pan: widget.pan,
        size: marker.size,
        color: marker.color,
        label: marker.label,
      );
      widget.onMarkerMoved(_draggingMarkerIndex!, Offset(newMarker.x, newMarker.y));
    } else if (_panStart != null && _currentPan != null) {
      final delta = details.localPosition - _panStart!;
      final newPan = _currentPan! + delta;
      widget.onPanChanged(newPan);
    }
  }

  int _findMarkerAtPosition(Offset position) {
    final canvasSize = context.size!;
    for (int i = widget.markers.length - 1; i >= 0; i--) {
      final marker = widget.markers[i];
      final screenPos = marker.toScreenCoordinates(
        canvasSize: canvasSize,
        zoom: widget.zoom,
        pan: widget.pan,
      );
      final scaledSize = marker.getScaledSize(widget.zoom);
      final distance = (position - screenPos).distance;
      if (distance <= scaledSize / 2) return i;
    }
    return -1;
  }

  int _findResizeHandleAtPosition(Offset position) {
    if (widget.selectedMarkerIndex == null) return -1;
    final canvasSize = context.size!;
    final marker = widget.markers[widget.selectedMarkerIndex!];
    final screenPos = marker.toScreenCoordinates(
      canvasSize: canvasSize,
      zoom: widget.zoom,
      pan: widget.pan,
    );
    final scaledSize = marker.getScaledSize(widget.zoom);
    final handlePos = Offset(screenPos.dx + scaledSize / 2, screenPos.dy + scaledSize / 2);
    final distance = (position - handlePos).distance;
    if (distance <= 12.0) return widget.selectedMarkerIndex!;
    return -1;
  }
}

class CombinedPainter extends CustomPainter {
  final List<Marker> markers;
  final List<DrawingPath> drawingPaths;
  final List<Offset> currentDrawingPoints;
  final Color currentDrawingColor;
  final double currentStrokeWidth;
  final int? selectedMarkerIndex;
  final int? selectedPathIndex;
  final double zoom;
  final Offset pan;

  CombinedPainter({
    required this.markers,
    required this.drawingPaths,
    required this.currentDrawingPoints,
    required this.currentDrawingColor,
    required this.currentStrokeWidth,
    required this.selectedMarkerIndex,
    required this.selectedPathIndex,
    required this.zoom,
    required this.pan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed paths
    for (int i = 0; i < drawingPaths.length; i++) {
      final path = drawingPaths[i];
      final isSelected = i == selectedPathIndex;

      final screenPoints = path.toScreenCoordinates(
        canvasSize: size,
        zoom: zoom,
        pan: pan,
      );

      if (screenPoints.length > 1) {
        final paint = Paint()
          ..color = path.color
          ..strokeWidth = path.strokeWidth * zoom
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final drawPath = Path();
        drawPath.moveTo(screenPoints[0].dx, screenPoints[0].dy);
        for (int j = 1; j < screenPoints.length; j++) {
          drawPath.lineTo(screenPoints[j].dx, screenPoints[j].dy);
        }
        canvas.drawPath(drawPath, paint);

        if (isSelected) {
          final highlightPaint = Paint()
            ..color = Colors.blue.withOpacity(0.3)
            ..strokeWidth = (path.strokeWidth + 4) * zoom
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

    // Draw markers with custom shapes
    for (int i = 0; i < markers.length; i++) {
      final marker = markers[i];
      final isSelected = i == selectedMarkerIndex;
      final screenPos = marker.toScreenCoordinates(
        canvasSize: size,
        zoom: zoom,
        pan: pan,
      );
      final scaledSize = marker.getScaledSize(zoom);

      // ✅ CUSTOM SHAPES BASED ON MARKER TYPE
      if (marker.type == 'calculi') {
        _drawRuggedCalculi(canvas, screenPos, scaledSize, marker.color, isSelected, i);
      } else if (marker.type == 'tumor') {
        _drawBumpyTumor(canvas, screenPos, scaledSize, marker.color, isSelected, i);
      } else {
        // Default circular shape for other markers (cyst, etc.)
        _drawCircularMarker(canvas, screenPos, scaledSize, marker.color, isSelected, i);
      }

      // Draw resize handle if selected
      if (isSelected) {
        final handlePaint = Paint()..color = Colors.blue..style = PaintingStyle.fill;
        final handleOutlinePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final handlePos = Offset(
          screenPos.dx + scaledSize / 2,
          screenPos.dy + scaledSize / 2,
        );

        canvas.drawCircle(handlePos, 8.0, handlePaint);
        canvas.drawCircle(handlePos, 8.0, handleOutlinePaint);

        final iconPainter = TextPainter(
          text: const TextSpan(
            text: '⇲',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        iconPainter.layout();
        iconPainter.paint(
          canvas,
          Offset(
            handlePos.dx - iconPainter.width / 2,
            handlePos.dy - iconPainter.height / 2,
          ),
        );
      }
    }
  }

  // ✅ RUGGED/JAGGED SHAPE FOR CALCULI (kidney stones)
  void _drawRuggedCalculi(Canvas canvas, Offset center, double size, Color color, bool isSelected, int index) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();

    // Create irregular jagged star shape
    final numPoints = 8;
    final radius = size / 2;

    for (int i = 0; i < numPoints; i++) {
      final angle = (i * 2 * math.pi / numPoints) - math.pi / 2;
      // Alternate between outer and inner points with random variation
      final r = (i % 2 == 0)
          ? radius * (0.9 + math.sin(i * 1.5) * 0.1)  // Outer points
          : radius * (0.6 + math.sin(i * 2.3) * 0.15); // Inner points

      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // Outline
    final outlinePaint = Paint()
      ..color = isSelected ? Colors.blue : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.0;
    canvas.drawPath(path, outlinePaint);

    // Number label
    _drawMarkerNumber(canvas, center, size, index);

    // Selection indicator
    if (isSelected) {
      final selectionPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, size / 2 + 5, selectionPaint);
    }
  }

  // ✅ BUMPY/IRREGULAR SHAPE FOR TUMOR
  void _drawBumpyTumor(Canvas canvas, Offset center, double size, Color color, bool isSelected, int index) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();

    // Create irregular bumpy circle
    final numBumps = 12;
    final baseRadius = size / 2;

    for (int i = 0; i <= numBumps; i++) {
      final angle = (i * 2 * math.pi / numBumps) - math.pi / 2;
      // Add bumps with varying amplitudes
      final bumpSize = 0.15 + math.sin(i * 3.7) * 0.1;
      final r = baseRadius * (1.0 + math.sin(i * 2.1) * bumpSize);

      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // Outline
    final outlinePaint = Paint()
      ..color = isSelected ? Colors.blue : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.0;
    canvas.drawPath(path, outlinePaint);

    // Number label
    _drawMarkerNumber(canvas, center, size, index);

    // Selection indicator
    if (isSelected) {
      final selectionPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, size / 2 + 8, selectionPaint);
    }
  }

  // Default circular marker for other types (cyst, etc.)
  void _drawCircularMarker(Canvas canvas, Offset center, double size, Color color, bool isSelected, int index) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(center, size / 2, paint);

    final outlinePaint = Paint()
      ..color = isSelected ? Colors.blue : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.0;
    canvas.drawCircle(center, size / 2, outlinePaint);

    _drawMarkerNumber(canvas, center, size, index);

    if (isSelected) {
      final selectionPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, size / 2 + 5, selectionPaint);
    }
  }

  // Helper to draw marker number
  void _drawMarkerNumber(Canvas canvas, Offset center, double size, int index) {
    final numberPainter = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: TextStyle(
          color: Colors.white,
          fontSize: (size * 0.5).clamp(10.0, 16.0),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    numberPainter.layout();
    numberPainter.paint(
      canvas,
      Offset(
        center.dx - numberPainter.width / 2,
        center.dy - numberPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(CombinedPainter oldDelegate) {
    return oldDelegate.markers != markers ||
        oldDelegate.drawingPaths != drawingPaths ||
        oldDelegate.currentDrawingPoints != currentDrawingPoints ||
        oldDelegate.selectedMarkerIndex != selectedMarkerIndex ||
        oldDelegate.selectedPathIndex != selectedPathIndex ||
        oldDelegate.zoom != zoom ||
        oldDelegate.pan != pan;
  }
}