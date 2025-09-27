import 'package:flutter/material.dart';
import '../../../models/condition_tool.dart';
import '../../../models/marker.dart';
import 'dart:math' as math;

class ToolPanel extends StatelessWidget {
  final List<ConditionTool> tools;
  final String selectedTool;
  final Function(String) onToolSelected;
  final List<Marker> markers;
  final int? selectedMarkerIndex;
  final VoidCallback onMarkerDeleted;
  final Function(String) onMarkerLabelChanged;
  final Function(double) onMarkerSizeChanged;
  final double zoom;
  final Function(double) onZoomChanged;
  final VoidCallback onResetView;
  final VoidCallback onClearAll;

  const ToolPanel({
    super.key,
    required this.tools,
    required this.selectedTool,
    required this.onToolSelected,
    required this.markers,
    required this.selectedMarkerIndex,
    required this.onMarkerDeleted,
    required this.onMarkerLabelChanged,
    required this.onMarkerSizeChanged,
    required this.zoom,
    required this.onZoomChanged,
    required this.onResetView,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: const Text(
              'Tools & Conditions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tools Section
                  _buildToolsSection(),
                  const SizedBox(height: 24),

                  // Selected Marker Controls
                  if (selectedMarkerIndex != null) ...[
                    _buildMarkerControls(),
                    const SizedBox(height: 24),
                  ],

                  // View Controls
                  _buildViewControls(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Tool',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...tools.map((tool) => _buildToolButton(tool)),
      ],
    );
  }

  Widget _buildToolButton(ConditionTool tool) {
    final isSelected = selectedTool == tool.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onToolSelected(tool.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (tool.id == 'pan')
                  const Icon(Icons.pan_tool, size: 20, color: Colors.grey)

                else if (tool.id == 'calculi')
                  // Jagged calculi icon
                    Container(
                      width: 20,
                      height: 20,
                      child: CustomPaint(
                        painter: ToolCalculiPainter(color: tool.color),
                      ),
                    )
                  else if (tool.id == 'cyst')
                    // Ovoid cyst icon
                      Container(
                        width: 20,
                        height: 20,
                        child: CustomPaint(
                          painter: ToolCystPainter(),
                        ),
                      )
                    else
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: tool.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tool.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.blue.shade700 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerControls() {
    final marker = markers[selectedMarkerIndex!];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Marker',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Label Editor
          TextFormField(
            initialValue: marker.label,
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: onMarkerLabelChanged,
          ),
          const SizedBox(height: 16),

          // Size Control Slider
          const Text(
            'Marker Size',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Small', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Expanded(
                child: Slider(
                  value: marker.size,
                  min: 5.0,
                  max: 30.0,
                  divisions: 25,
                  onChanged: onMarkerSizeChanged,
                  activeColor: Colors.blue,
                ),
              ),
              const Text('Large', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),

          // Size Info
          Text(
            'Size: ${marker.size.toStringAsFixed(1)}px',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            '~${(marker.size / 20 * 10).toStringAsFixed(1)}mm',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // Delete Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onMarkerDeleted,
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete Marker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Deselect Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onToolSelected('pan'), // Switch to pan tool and deselect
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Deselect'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'View Controls',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Zoom Control
        Text(
          'Zoom: ${(zoom * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Slider(
          value: zoom,
          min: 0.5,
          max: 3.0,
          divisions: 25,
          onChanged: onZoomChanged,
        ),
        const SizedBox(height: 8),

        // Reset View Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onResetView,
            child: const Text('Reset View'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement save functionality
            },
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save Diagram'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Clear All Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onClearAll,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear All'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for jagged calculi icon in tool panel
class ToolCalculiPainter extends CustomPainter {
  final Color color;

  ToolCalculiPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Create small irregular shape for tool icon
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Generate irregular points for jagged edges
    final points = <Offset>[];
    for (int i = 0; i < 8; i++) {
      final angle = (i * 3.14159 * 2) / 8;
      final variation = radius * (0.7 + (i % 3) * 0.3);
      points.add(Offset(
        center.dx + cos(angle) * variation,
        center.dy + sin(angle) * variation,
      ));
    }

    // Create jagged path
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  // Helper functions for math
  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for ovoid cyst icon in tool panel
class ToolCystPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Create ovoid shape (wider than tall)
    final center = Offset(size.width / 2, size.height / 2);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.8,
      height: size.height * 0.6, // Make it ovoid (wider than tall)
    );

    canvas.drawOval(ovalRect, fillPaint);
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}