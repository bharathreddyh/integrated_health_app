import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/marker.dart';
import '../../models/condition_tool.dart';
import '../../models/medical_condition.dart';
import 'widgets/medical_canvas.dart';

class MedicalConditionScreen extends StatefulWidget {
  final MedicalCondition condition;

  const MedicalConditionScreen({
    super.key,
    required this.condition,
  });

  @override
  State<MedicalConditionScreen> createState() => _MedicalConditionScreenState();
}

class _MedicalConditionScreenState extends State<MedicalConditionScreen> {
  String selectedTool = 'pan';
  List<Marker> markers = [];
  int? selectedMarkerIndex;
  double zoom = 1.0;
  Offset pan = Offset.zero;

  Patient patient = Patient(
    name: '',
    age: '',
    diagnosis: '',
    date: DateTime.now().toString().split(' ')[0],
  );

  // Medical annotation tools
  final List<ConditionTool> tools = [
    const ConditionTool(
      id: 'pan',
      name: 'Pan Tool',
      color: Colors.grey,
      defaultSize: 0,
    ),
    const ConditionTool(
      id: 'highlight',
      name: 'Highlight',
      color: Colors.yellow,
      defaultSize: 15,
    ),
    const ConditionTool(
      id: 'arrow',
      name: 'Arrow',
      color: Colors.red,
      defaultSize: 12,
    ),
    const ConditionTool(
      id: 'affected_area',
      name: 'Affected Area',
      color: Colors.orange,
      defaultSize: 18,
    ),
    const ConditionTool(
      id: 'inflammation',
      name: 'Inflammation',
      color: Color(0xFFEA580C),
      defaultSize: 14,
    ),
    const ConditionTool(
      id: 'note',
      name: 'Note',
      color: Colors.blue,
      defaultSize: 10,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Row(
        children: [
          // Left Panel - Tools & Controls
          _buildLeftPanel(),

          // Center Panel - Canvas
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildCanvasArea()),
              ],
            ),
          ),

          // Right Panel - Patient Data
          _buildRightPanel(),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tools Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Annotation Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select tool to annotate diagram',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Tools List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...tools.map((tool) => _buildToolButton(tool)),
                const SizedBox(height: 24),

                // Marker Controls
                if (selectedMarkerIndex != null) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildMarkerControls(),
                ],
              ],
            ),
          ),

          // View Controls
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'View Controls',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Zoom:', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: zoom,
                        min: 0.5,
                        max: 3.0,
                        divisions: 25,
                        onChanged: (value) {
                          setState(() => zoom = value);
                        },
                      ),
                    ),
                    Text(
                      '${(zoom * 100).toInt()}%',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            zoom = 1.0;
                            pan = Offset.zero;
                          });
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset View'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        markers.clear();
                        selectedMarkerIndex = null;
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(ConditionTool tool) {
    final isSelected = selectedTool == tool.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => selectedTool = tool.id),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tool.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getToolIcon(tool.id),
                    color: tool.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tool.name,
                    style: TextStyle(
                      fontSize: 14,
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

  IconData _getToolIcon(String toolId) {
    switch (toolId) {
      case 'pan': return Icons.pan_tool;
      case 'highlight': return Icons.highlight;
      case 'arrow': return Icons.arrow_upward;
      case 'affected_area': return Icons.circle_outlined;
      case 'inflammation': return Icons.local_fire_department;
      case 'note': return Icons.note;
      default: return Icons.circle;
    }
  }

  Widget _buildMarkerControls() {
    final marker = markers[selectedMarkerIndex!];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
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
          TextField(
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (value) {
              setState(() {
                markers[selectedMarkerIndex!] = markers[selectedMarkerIndex!].copyWith(label: value);
              });
            },
          ),
          const SizedBox(height: 12),
          const Text('Size', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Slider(
            value: marker.size,
            min: 5.0,
            max: 30.0,
            divisions: 25,
            onChanged: (value) {
              setState(() {
                markers[selectedMarkerIndex!] = markers[selectedMarkerIndex!].copyWith(size: value);
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      markers.removeAt(selectedMarkerIndex!);
                      selectedMarkerIndex = null;
                    });
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            iconSize: 24,
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: widget.condition.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.condition.icon, color: widget.condition.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.condition.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.condition.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Generate PDF
            },
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            label: const Text('Generate Summary'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Container(
          width: 900,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MedicalCanvas(
              condition: widget.condition,
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
                setState(() => pan = newPan);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Data Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter patient details and vitals',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Patient Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildTextField('Patient Name', 'Enter name', (value) {
                  setState(() => patient = patient.copyWith(name: value));
                }),
                const SizedBox(height: 16),
                _buildTextField('Age', 'Enter age', (value) {
                  setState(() => patient = patient.copyWith(age: value));
                }),
                const SizedBox(height: 16),
                _buildTextField('Phone Number', 'Enter phone', (value) {
                  // TODO: Add phone to patient model
                }),
                const SizedBox(height: 24),

                const Text(
                  'Vitals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('BP', '120/80', (value) {}),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField('Sugar', 'mg/dL', (value) {}),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Weight', 'kg', (value) {}),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField('Temp', '°C', (value) {}),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildTextField(
                  'Medicines Prescribed',
                  'Enter medications',
                      (value) {},
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Clinical Notes',
                  'Additional notes',
                      (value) {},
                  maxLines: 4,
                ),
              ],
            ),
          ),

          // Summary Info
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Date: ${patient.date}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Annotations: ${markers.length}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, Function(String) onChanged, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: onChanged,
        ),
      ],
    );
  }
}