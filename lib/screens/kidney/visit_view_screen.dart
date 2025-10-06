import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/visit.dart';
import '../../models/condition_tool.dart';
import 'widgets/kidney_canvas.dart';

class VisitViewScreen extends StatelessWidget {
  final Visit visit;
  final Patient patient;

  const VisitViewScreen({
    super.key,
    required this.visit,
    required this.patient,
  });

  final List<ConditionTool> tools = const [
    ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
    ConditionTool(id: 'calculi', name: 'Calculi', color: Colors.grey, defaultSize: 8),
    ConditionTool(id: 'cyst', name: 'Cyst', color: Color(0xFF2563EB), defaultSize: 12),
    ConditionTool(id: 'tumor', name: 'Tumor', color: Color(0xFF7C2D12), defaultSize: 16),
    ConditionTool(id: 'inflammation', name: 'Inflammation', color: Color(0xFFEA580C), defaultSize: 14),
    ConditionTool(id: 'blockage', name: 'Blockage', color: Color(0xFF9333EA), defaultSize: 10),
  ];

  final Map<String, String> presets = const {
    'anatomical': 'Detailed Anatomy',
    'simple': 'Simple Diagram',
    'crossSection': 'Cross-Section View',
    'nephron': 'Nephron',
    'polycystic': 'Polycystic Kidney Disease',
    'pyelonephritis': 'Pyelonephritis',
    'glomerulonephritis': 'Glomerulonephritis',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Visit - ${_formatDateTime(visit.createdAt)}'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Read-Only View',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        'This is a historical record and cannot be modified',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 600,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: KidneyCanvas(
                    selectedPreset: visit.diagramType,
                    markers: visit.markers,
                    drawingPaths: visit.drawingPaths,
                    selectedMarkerIndex: null,
                    selectedPathIndex: null, // FIXED
                    selectedTool: 'pan',
                    tools: tools,
                    zoom: 1.0,
                    pan: Offset.zero,
                    waitingForClick: false,
                    pendingToolType: null,
                    pendingToolSize: null,
                    selectedDrawingTool: 'none',
                    drawingColor: Colors.black,
                    strokeWidth: 3.0,
                    onMarkerAdded: (_) {},
                    onMarkerSelected: (_) {},
                    onMarkerMoved: (_, __) {},
                    onMarkerResized: (_, __) {},
                    onPanChanged: (_) {},
                    onDrawingPathAdded: (_) {},
                    onDrawingPathSelected: (_) {}, // FIXED
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        presets[visit.diagramType] ?? visit.diagramType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${visit.markers.length} markers',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 24),
                    Icon(Icons.draw, size: 16, color: Colors.purple.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${visit.drawingPaths.length} drawings',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 24),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(visit.createdAt),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Notes:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    visit.notes!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}