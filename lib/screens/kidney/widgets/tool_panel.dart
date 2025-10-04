import 'package:flutter/material.dart';
import '../../../models/marker.dart';
import '../../../models/condition_tool.dart';

class ToolPanel extends StatelessWidget {
  final List<ConditionTool> tools;
  final String selectedTool;
  final Function(String) onToolSelected;
  final List<Marker> markers;
  final int? selectedMarkerIndex;
  final Function() onMarkerDeleted;
  final Function(String) onMarkerLabelChanged;
  final Function(double) onMarkerSizeChanged;
  final double zoom;
  final Function(double) onZoomChanged;
  final Function() onResetView;
  final Function() onClearAll;

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

  // FIXED: Reorder markers so selected one appears at top
  List<MapEntry<int, Marker>> _getOrderedMarkers() {
    final entries = markers.asMap().entries.toList();

    if (selectedMarkerIndex == null) {
      return entries; // No selection, return as-is
    }

    // Put selected marker first, then all others
    final selected = entries[selectedMarkerIndex!];
    final others = entries.where((e) => e.key != selectedMarkerIndex).toList();

    return [selected, ...others];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  'Annotation Tools',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tools Section
                  _buildSectionTitle('Tools'),
                  const SizedBox(height: 8),
                  ...tools.map((tool) => _buildToolButton(tool)),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Zoom Controls
                  _buildSectionTitle('View Controls'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.zoom_in, size: 16, color: Colors.grey),
                      Expanded(
                        child: Slider(
                          value: zoom,
                          min: 0.5,
                          max: 3.0,
                          divisions: 25,
                          label: '${(zoom * 100).toInt()}%',
                          onChanged: onZoomChanged,
                        ),
                      ),
                      Text(
                        '${(zoom * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onResetView,
                          icon: const Icon(Icons.center_focus_strong, size: 16),
                          label: const Text('Reset View', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Marker List - FIXED: Selected marker appears at top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Markers (${markers.length})'),
                      if (selectedMarkerIndex != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Selected',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (markers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.location_off, color: Colors.grey.shade400, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'No markers yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                  // FIXED: Use reordered list
                    ..._getOrderedMarkers().map((entry) {
                      return _buildMarkerItem(entry.key, entry.value);
                    }),

                  if (markers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: onClearAll,
                      icon: const Icon(Icons.clear_all, size: 16, color: Colors.red),
                      label: const Text(
                        'Clear All',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Selected Marker Editor
                  if (selectedMarkerIndex != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Edit Selected Marker',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: onMarkerDeleted,
                                color: Colors.red.shade700,
                                tooltip: 'Delete Marker',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Label',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            controller: TextEditingController(
                              text: markers[selectedMarkerIndex!].label,
                            )..selection = TextSelection.fromPosition(
                              TextPosition(offset: markers[selectedMarkerIndex!].label.length),
                            ),
                            onChanged: onMarkerLabelChanged,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Size',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: markers[selectedMarkerIndex!].size,
                                  min: 4,
                                  max: 30,
                                  divisions: 26,
                                  label: markers[selectedMarkerIndex!].size.round().toString(),
                                  onChanged: onMarkerSizeChanged,
                                  activeColor: const Color(0xFF3B82F6),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  markers[selectedMarkerIndex!].size.round().toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildToolButton(ConditionTool tool) {
    final isSelected = selectedTool == tool.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? tool.color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onToolSelected(tool.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? tool.color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (tool.id == 'pan')
                  Icon(
                    Icons.pan_tool,
                    size: 18,
                    color: isSelected ? tool.color : Colors.grey.shade600,
                  )
                else
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: tool.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tool.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? tool.color : Colors.grey.shade800,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: tool.color,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerItem(int index, Marker marker) {
    final isSelected = selectedMarkerIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onToolSelected('pan'),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
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
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marker.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (marker.label.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          marker.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.blue,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}