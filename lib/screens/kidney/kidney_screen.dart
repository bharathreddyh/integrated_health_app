import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/marker.dart';
import '../../models/condition_tool.dart';
import 'widgets/kidney_canvas.dart';
import 'widgets/tool_panel.dart';

class KidneyScreen extends StatefulWidget {
  const KidneyScreen({super.key});

  @override
  State<KidneyScreen> createState() => _KidneyScreenState();
}

class _KidneyScreenState extends State<KidneyScreen> {
  String selectedPreset = 'anatomical';
  String selectedTool = 'pan';
  List<Marker> markers = [];
  int? selectedMarkerIndex;
  double zoom = 1.0;
  Offset pan = Offset.zero;
  bool isPanning = false;

  Patient patient = Patient(
    name: 'John Doe',
    age: '45',
    diagnosis: '3mm renal calculi in right kidney',
    date: DateTime.now().toString().split(' ')[0], // Today's date automatically
  );

  final List<ConditionTool> tools = [
    const ConditionTool(
      id: 'pan',
      name: 'Pan Tool',
      color: Colors.grey,
      defaultSize: 0,
    ),

    const ConditionTool(
      id: 'calculi',
      name: 'Calculi',
      color: Colors.grey, // Changed from red to grey
      defaultSize: 8,
    ),
    const ConditionTool(
      id: 'cyst',
      name: 'Cyst',
      color: Color(0xFF2563EB),
      defaultSize: 12,
    ),
    const ConditionTool(
      id: 'tumor',
      name: 'Tumor',
      color: Color(0xFF7C2D12),
      defaultSize: 16,
    ),
    const ConditionTool(
      id: 'inflammation',
      name: 'Inflammation',
      color: Color(0xFFEA580C),
      defaultSize: 14,
    ),
    const ConditionTool(
      id: 'blockage',
      name: 'Blockage',
      color: Color(0xFF9333EA),
      defaultSize: 10,
    ),
  ];

  final Map<String, String> presets = {
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
      body: Row(
        children: [
          // Left Tool Panel
          SizedBox(
            width: 280,
            child: ToolPanel(
              tools: tools,
              selectedTool: selectedTool,
              onToolSelected: (tool) {
                setState(() {
                  selectedTool = tool;
                });
              },
              markers: markers,
              selectedMarkerIndex: selectedMarkerIndex,
              onMarkerDeleted: () {
                if (selectedMarkerIndex != null) {
                  setState(() {
                    markers.removeAt(selectedMarkerIndex!);
                    selectedMarkerIndex = null;
                  });
                }
              },
              onMarkerLabelChanged: (newLabel) {
                if (selectedMarkerIndex != null) {
                  setState(() {
                    markers[selectedMarkerIndex!] = markers[selectedMarkerIndex!].copyWith(label: newLabel);
                  });
                }
              },
              onMarkerSizeChanged: (newSize) {
                if (selectedMarkerIndex != null) {
                  setState(() {
                    markers[selectedMarkerIndex!] = markers[selectedMarkerIndex!].copyWith(size: newSize);
                  });
                }
              },
              zoom: zoom,
              onZoomChanged: (newZoom) {
                setState(() {
                  zoom = newZoom;
                });
              },
              onResetView: () {
                setState(() {
                  zoom = 1.0;
                  pan = Offset.zero;
                });
              },
              onClearAll: () {
                setState(() {
                  markers.clear();
                  selectedMarkerIndex = null;
                });
              },
            ),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Title
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Urinary System - Kidney Diagram Tool',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Interactive patient education diagrams',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Preset Selector
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          value: selectedPreset,
                          decoration: const InputDecoration(
                            labelText: 'Select Diagram',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: presets.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedPreset = value;
                                // Clear markers when changing presets for now
                                markers.clear();
                                selectedMarkerIndex = null;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Canvas Area
                Expanded(
                  child: Container(
                    color: Colors.grey.shade100,
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
                            selectedPreset: selectedPreset,
                            markers: markers,
                            selectedMarkerIndex: selectedMarkerIndex,
                            selectedTool: selectedTool,
                            tools: tools,
                            zoom: zoom,
                            pan: pan,
                            onMarkerAdded: (marker) {
                              setState(() {
                                markers.add(marker);
                                selectedMarkerIndex = markers.length - 1;
                                // Automatically switch back to pan tool after placing marker
                                selectedTool = 'pan';
                              });
                            },
                            onMarkerSelected: (index) {
                              setState(() {
                                selectedMarkerIndex = index == -1 ? null : index;
                              });
                            },
                            onMarkerMoved: (index, newPosition) {
                              setState(() {
                                markers[index] = markers[index].copyWith(
                                  x: newPosition.dx,
                                  y: newPosition.dy,
                                );
                              });
                            },
                            onMarkerResized: (index, newSize) {
                              setState(() {
                                markers[index] = markers[index].copyWith(size: newSize);
                              });
                            },
                            onPanChanged: (newPan) {
                              setState(() {
                                pan = newPan;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Patient Info Footer - Now Editable
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      // Patient Name Field
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Patient Name', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            SizedBox(
                              height: 30,
                              child: TextFormField(
                                initialValue: patient.name,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    patient = patient.copyWith(name: value);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Age Field
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Age', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            SizedBox(
                              height: 30,
                              child: TextFormField(
                                initialValue: patient.age,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    patient = patient.copyWith(age: value);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Diagnosis Field
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Diagnosis', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            SizedBox(
                              height: 30,
                              child: TextFormField(
                                initialValue: patient.diagnosis,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    patient = patient.copyWith(diagnosis: value);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Date Display (Auto-populated)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Date', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.shade100,
                            ),
                            child: Center(
                              child: Text(
                                patient.date,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Marker Count
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Markers', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Center(
                              child: Text(
                                '${markers.length} placed',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}