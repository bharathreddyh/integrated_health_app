import 'package:flutter/material.dart';
import '../../../models/medical_condition.dart';
import '../../../models/marker.dart';
import '../../../models/condition_tool.dart';

class MedicalCanvas extends StatefulWidget {
  final MedicalCondition condition;
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

  const MedicalCanvas({
    super.key,
    required this.condition,
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
  State<MedicalCanvas> createState() => _MedicalCanvasState();
}

class _MedicalCanvasState extends State<MedicalCanvas> {
  Offset? _lastPanPoint;

  // Map condition IDs to image paths
  final Map<String, String> _conditionImages = {
    'diabetes': 'assets/images/diabetes_diagram.png',
    'hypertension': 'assets/images/hypertension_diagram.png',
    'asthma': 'assets/images/asthma_diagram.png',
    'arthritis': 'assets/images/arthritis_diagram.png',
    'depression': 'assets/images/depression_diagram.png',
    'migraine': 'assets/images/migraine_diagram.png',
    'gerd': 'assets/images/gerd_diagram.png',
    'uti': 'assets/images/uti_diagram.png',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 400,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background medical image
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
                  child: _buildConditionImage(),
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

  Widget _buildConditionImage() {
    final imagePath = _conditionImages[widget.condition.id];

    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: 600,
        height: 400,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackDiagram();
        },
      );
    } else {
      return _buildFallbackDiagram();
    }
  }

  Widget _buildFallbackDiagram() {
    return Container(
      width: 600,
      height: 400,
      color: Colors.grey.shade50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: widget.condition.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              widget.condition.icon,
              size: 60,
              color: widget.condition.color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.condition.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.condition.description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Text(
              'Add medical diagram image to:\nassets/images/[condition]_diagram.png',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E40AF),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
      child: GestureDetector(
        onTap: () {
          widget.onMarkerSelected(index);
        },
        onPanStart: (details) {
          widget.onMarkerSelected(index);
        },
        onPanUpdate: (details) {
          // Convert local pan delta to canvas coordinates
          final canvasDelta = details.delta / widget.zoom;
          final newCanvasX = marker.x + canvasDelta.dx;
          final newCanvasY = marker.y + canvasDelta.dy;

          widget.onMarkerMoved(index, Offset(newCanvasX, newCanvasY));
        },
        onPanEnd: (details) {
          // Drag completed
        },
        child: _buildMarkerWidget(marker, tool, screenSize, isSelected),
      ),
    );
  }

  Widget _buildMarkerWidget(Marker marker, ConditionTool tool, double size, bool isSelected) {
    // Get marker number based on its position in the list
    final markerNumber = widget.markers.indexOf(marker) + 1;

    return Container(
      width: size * 2,
      height: size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              width: size * 2,
              height: size * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

          // Main marker - different shapes based on tool type
          Container(
            width: size * 2,
            height: size * 2,
            decoration: BoxDecoration(
              shape: _getMarkerShape(tool.id),
              color: tool.color.withOpacity(0.8),
              border: Border.all(
                color: isSelected ? Colors.black : tool.color,
                width: 1,
              ),
            ),
            child: _getMarkerIcon(tool.id),
          ),

          // Number label
          Positioned(
            top: -20 * widget.zoom,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4 * widget.zoom, vertical: 2 * widget.zoom),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4 * widget.zoom),
              ),
              child: Text(
                markerNumber.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6 * widget.zoom,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxShape _getMarkerShape(String toolId) {
    switch (toolId) {
      case 'highlight':
      case 'arrow':
        return BoxShape.rectangle;
      default:
        return BoxShape.circle;
    }
  }

  Widget? _getMarkerIcon(String toolId) {
    switch (toolId) {
      case 'arrow':
        return Icon(Icons.arrow_upward, color: Colors.white, size: 12 * widget.zoom);
      default:
        return null;
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