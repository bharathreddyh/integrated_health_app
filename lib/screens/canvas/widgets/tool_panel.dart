import 'package:flutter/material.dart';

import '../../../models/marker.dart';
import '../../../models/condition_tool.dart';

class ToolPanel extends StatefulWidget {
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
  final Function() onClearMarkers;
  final Function() onClearDrawings;
  final int drawingPathsCount;

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
    required this.onClearMarkers,
    required this.onClearDrawings,
    required this.drawingPathsCount,
  });

  @override
  State<ToolPanel> createState() => _ToolPanelState();
}

class _ToolPanelState extends State<ToolPanel> {
  // ✅ NEW: Track expanded state for each section
  bool _isToolsExpanded = false;
  bool _isViewControlsExpanded = false;
  bool _isMarkersExpanded = true;

  List<MapEntry<int, Marker>> _getOrderedMarkers() {
    final entries = widget.markers.asMap().entries.toList();

    if (widget.selectedMarkerIndex == null) {
      return entries;
    }

    final selected = entries[widget.selectedMarkerIndex!];
    final others = entries.where((e) => e.key != widget.selectedMarkerIndex).toList();

    return [selected, ...others];
  }

  void _showClearMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          value: 'all',
          enabled: widget.markers.isNotEmpty || widget.drawingPathsCount > 0,
          child: Row(
            children: [
              Icon(
                Icons.clear_all,
                size: 20,
                color: (widget.markers.isNotEmpty || widget.drawingPathsCount > 0)
                    ? Colors.red.shade700
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clear All',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: (widget.markers.isNotEmpty || widget.drawingPathsCount > 0)
                            ? Colors.black87
                            : Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      '${widget.markers.length} markers, ${widget.drawingPathsCount} drawings',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'markers',
          enabled: widget.markers.isNotEmpty,
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: widget.markers.isNotEmpty ? Colors.orange.shade700 : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clear Markers Only',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: widget.markers.isNotEmpty ? Colors.black87 : Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      '${widget.markers.length} markers',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'drawings',
          enabled: widget.drawingPathsCount > 0,
          child: Row(
            children: [
              Icon(
                Icons.draw,
                size: 20,
                color: widget.drawingPathsCount > 0 ? Colors.blue.shade700 : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clear Drawings Only',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: widget.drawingPathsCount > 0 ? Colors.black87 : Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      '${widget.drawingPathsCount} drawings',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'all':
            _confirmAndExecute(
              context,
              'Clear All',
              'Are you sure you want to clear all markers and drawings?',
              widget.onClearAll,
            );
            break;
          case 'markers':
            _confirmAndExecute(
              context,
              'Clear Markers',
              'Are you sure you want to clear all ${widget.markers.length} markers?',
              widget.onClearMarkers,
            );
            break;
          case 'drawings':
            _confirmAndExecute(
              context,
              'Clear Drawings',
              'Are you sure you want to clear all ${widget.drawingPathsCount} drawings?',
              widget.onClearDrawings,
            );
            break;
        }
      }
    });
  }

  void _confirmAndExecute(
      BuildContext context,
      String title,
      String message,
      VoidCallback onConfirm,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyContent = widget.markers.isNotEmpty || widget.drawingPathsCount > 0;

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

          // Clear Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Builder(
              builder: (context) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasAnyContent ? () => _showClearMenu(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.clear_all, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Clear (M:${widget.markers.length} D:${widget.drawingPathsCount})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: hasAnyContent ? Colors.white : Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ✅ Scrollable Content with Collapsible Sections
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ✅ Tools Section (Collapsible)
                  _buildCollapsibleSection(
                    title: 'Tools',
                    icon: Icons.build,
                    isExpanded: _isToolsExpanded,
                    onToggle: () => setState(() => _isToolsExpanded = !_isToolsExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: widget.tools.map((tool) => _buildToolButton(tool)).toList(),
                      ),
                    ),
                  ),

                  // ✅ View Controls Section (Collapsible)
                  _buildCollapsibleSection(
                    title: 'View Controls',
                    icon: Icons.zoom_in,
                    isExpanded: _isViewControlsExpanded,
                    onToggle: () => setState(() => _isViewControlsExpanded = !_isViewControlsExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.zoom_in, size: 16, color: Colors.grey),
                              Expanded(
                                child: Slider(
                                  value: widget.zoom,
                                  min: 0.5,
                                  max: 3.0,
                                  divisions: 25,
                                  label: '${(widget.zoom * 100).toInt()}%',
                                  onChanged: widget.onZoomChanged,
                                ),
                              ),
                              Text(
                                '${(widget.zoom * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: widget.onResetView,
                              icon: const Icon(Icons.center_focus_strong, size: 16),
                              label: const Text('Reset View', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ Markers Section (Collapsible)
                  _buildCollapsibleSection(
                    title: 'Markers (${widget.markers.length})',
                    icon: Icons.location_on,
                    isExpanded: _isMarkersExpanded,
                    badge: widget.selectedMarkerIndex != null ? 'Selected' : null,
                    onToggle: () => setState(() => _isMarkersExpanded = !_isMarkersExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: widget.markers.isEmpty
                          ? Container(
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
                          : Column(
                        children: _getOrderedMarkers().map((entry) {
                          return _buildMarkerItem(entry.key, entry.value);
                        }).toList(),
                      ),
                    ),
                  ),

                  // ✅ Selected Marker Editor (Always visible when marker selected)
                  if (widget.selectedMarkerIndex != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
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
                                  onPressed: widget.onMarkerDeleted,
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
                                text: widget.markers[widget.selectedMarkerIndex!].label,
                              )..selection = TextSelection.fromPosition(
                                TextPosition(offset: widget.markers[widget.selectedMarkerIndex!].label.length),
                              ),
                              onChanged: widget.onMarkerLabelChanged,
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
                                    value: widget.markers[widget.selectedMarkerIndex!].size,
                                    min: 4,
                                    max: 50,
                                    divisions: 46,
                                    label: widget.markers[widget.selectedMarkerIndex!].size.round().toString(),
                                    onChanged: widget.onMarkerSizeChanged,
                                    activeColor: const Color(0xFF3B82F6),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    widget.markers[widget.selectedMarkerIndex!].size.round().toString(),
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
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Build collapsible section
  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) child,
        ],
      ),
    );
  }

  Widget _buildToolButton(ConditionTool tool) {
    final isSelected = widget.selectedTool == tool.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? tool.color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => widget.onToolSelected(tool.id),
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
    final isSelected = widget.selectedMarkerIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => widget.onToolSelected('pan'),
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