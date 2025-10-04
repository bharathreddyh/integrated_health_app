import 'package:flutter/material.dart';
import '../../../models/marker.dart';
import '../../../models/condition_tool.dart';

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
  final bool waitingForClick;
  final String? pendingToolType;
  final double? pendingToolSize;

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
    this.waitingForClick = false,
    this.pendingToolType,
    this.pendingToolSize,
  });

  @override
  State<KidneyCanvas> createState() => _KidneyCanvasState();
}

class _KidneyCanvasState extends State<KidneyCanvas> {
  Offset? _panStart;
  Offset? _currentPan;
  int? _draggingMarkerIndex;
  bool _isResizing = false;
  Offset? _resizeStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Stack(
        children: [
          // Background image with zoom/pan
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
                          Icon(Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Image not found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getImagePath(widget.selectedPreset),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Markers overlay
          Positioned.fill(
            child: CustomPaint(
              painter: MarkerPainter(
                markers: widget.markers,
                selectedMarkerIndex: widget.selectedMarkerIndex,
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
      case 'anatomical':
        return 'assets/images/kidney_anatomical.png';
      case 'simple':
        return 'assets/images/kidney_simple.png';
      case 'crossSection':
        return 'assets/images/kidney_cross_section.png';
      case 'nephron':
        return 'assets/images/kidney_nephron.png';
      case 'polycystic':
        return 'assets/images/kidney_polycystic.png';
      case 'pyelonephritis':
        return 'assets/images/kidney_pyelonephritis.png';
      case 'glomerulonephritis':
        return 'assets/images/kidney_glomerulonephritis.png';
      default:
        return 'assets/images/kidney_anatomical.png';
    }
  }

  void _handleTapDown(TapDownDetails details) {
    // Handle voice-initiated placement
    if (widget.waitingForClick && widget.pendingToolType != null) {
      final tool = widget.tools.firstWhere(
            (t) => t.id == widget.pendingToolType,
        orElse: () => widget.tools.first,
      );
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

    // Regular tap handling
    if (widget.selectedTool == 'pan') {
      final tappedMarkerIndex = _findMarkerAtPosition(details.localPosition);
      widget.onMarkerSelected(tappedMarkerIndex);
    } else {
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

  void _handlePanStart(DragStartDetails details) {
    if (widget.selectedTool == 'pan') {
      // Check if starting to resize a selected marker
      if (widget.selectedMarkerIndex != null) {
        final resizeHandleIndex = _findResizeHandleAtPosition(details.localPosition);
        if (resizeHandleIndex != -1) {
          setState(() {
            _isResizing = true;
            _resizeStart = details.localPosition;
          });
          return;
        }
      }

      // Check if starting to drag a marker
      final tappedMarkerIndex = _findMarkerAtPosition(details.localPosition);

      if (tappedMarkerIndex != -1) {
        setState(() {
          _draggingMarkerIndex = tappedMarkerIndex;
        });
        widget.onMarkerSelected(tappedMarkerIndex);
      } else {
        // Start panning canvas
        setState(() {
          _panStart = details.localPosition;
          _currentPan = widget.pan;
        });
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isResizing && widget.selectedMarkerIndex != null) {
      // Resize marker by dragging the handle
      final canvasSize = context.size!;
      final marker = widget.markers[widget.selectedMarkerIndex!];
      final markerScreenPos = marker.toScreenCoordinates(
        canvasSize: canvasSize,
        zoom: widget.zoom,
        pan: widget.pan,
      );

      // Calculate new size based on distance from marker center
      final distance = (details.localPosition - markerScreenPos).distance;
      final newSize = (distance * 2).clamp(8.0, 50.0);

      widget.onMarkerResized(widget.selectedMarkerIndex!, newSize);

    } else if (_draggingMarkerIndex != null) {
      // Move marker
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
      // Pan canvas
      final delta = details.localPosition - _panStart!;
      final newPan = _currentPan! + delta;
      widget.onPanChanged(newPan);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _draggingMarkerIndex = null;
      _isResizing = false;
      _resizeStart = null;
      _panStart = null;
      _currentPan = null;
    });
  }

  int _findMarkerAtPosition(Offset position) {
    final canvasSize = context.size!;

    // Check from last to first (top to bottom in z-order)
    for (int i = widget.markers.length - 1; i >= 0; i--) {
      final marker = widget.markers[i];
      final screenPos = marker.toScreenCoordinates(
        canvasSize: canvasSize,
        zoom: widget.zoom,
        pan: widget.pan,
      );
      final scaledSize = marker.getScaledSize(widget.zoom);

      final distance = (position - screenPos).distance;
      if (distance <= scaledSize / 2) {
        return i;
      }
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

    // Resize handle position (bottom-right of marker)
    final handlePos = Offset(
      screenPos.dx + scaledSize / 2,
      screenPos.dy + scaledSize / 2,
    );

    final distance = (position - handlePos).distance;
    if (distance <= 12.0) { // Increased hit area for easier grabbing
      return widget.selectedMarkerIndex!;
    }

    return -1;
  }
}

class MarkerPainter extends CustomPainter {
  final List<Marker> markers;
  final int? selectedMarkerIndex;
  final double zoom;
  final Offset pan;

  MarkerPainter({
    required this.markers,
    required this.selectedMarkerIndex,
    required this.zoom,
    required this.pan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < markers.length; i++) {
      final marker = markers[i];
      final isSelected = i == selectedMarkerIndex;

      // Convert relative coordinates to screen coordinates
      final screenPos = marker.toScreenCoordinates(
        canvasSize: size,
        zoom: zoom,
        pan: pan,
      );

      // Get scaled size based on zoom
      final scaledSize = marker.getScaledSize(zoom);

      // Draw marker circle
      final paint = Paint()
        ..color = marker.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(screenPos, scaledSize / 2, paint);

      // Draw outline
      final outlinePaint = Paint()
        ..color = isSelected ? Colors.blue : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 2.0;

      canvas.drawCircle(screenPos, scaledSize / 2, outlinePaint);

      // Draw number label (marker index)
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
        Offset(
          screenPos.dx - numberPainter.width / 2,
          screenPos.dy - numberPainter.height / 2,
        ),
      );

      // Draw selection handles for selected marker
      if (isSelected) {
        // Resize handle (bottom-right)
        final handlePaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        final handleOutlinePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final handlePos = Offset(
          screenPos.dx + scaledSize / 2,
          screenPos.dy + scaledSize / 2,
        );

        // Draw resize handle
        canvas.drawCircle(handlePos, 8.0, handlePaint);
        canvas.drawCircle(handlePos, 8.0, handleOutlinePaint);

        // Draw resize icon
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

        // Optional: Draw selection box around marker
        final selectionRect = Rect.fromCircle(
          center: screenPos,
          radius: scaledSize / 2 + 5,
        );
        final selectionPaint = Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        canvas.drawCircle(screenPos, scaledSize / 2 + 5, selectionPaint);
      }
    }
  }

  @override
  bool shouldRepaint(MarkerPainter oldDelegate) {
    return oldDelegate.markers != markers ||
        oldDelegate.selectedMarkerIndex != selectedMarkerIndex ||
        oldDelegate.zoom != zoom ||
        oldDelegate.pan != pan;
  }
}