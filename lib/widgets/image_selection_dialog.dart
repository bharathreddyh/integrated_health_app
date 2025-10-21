// lib/widgets/image_selection_dialog.dart

import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../models/patient.dart';
import 'dart:typed_data';

class ImageSelectionDialog extends StatefulWidget {
  final Patient patient;
  final List<Visit> visits;
  final String currentSystem;

  const ImageSelectionDialog({
    super.key,
    required this.patient,
    required this.visits,
    required this.currentSystem,
  });

  @override
  State<ImageSelectionDialog> createState() => _ImageSelectionDialogState();
}

class _ImageSelectionDialogState extends State<ImageSelectionDialog> {
  final Set<int> _selectedVisitIds = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    // Pre-select all visits by default
    _selectedVisitIds.addAll(widget.visits.where((v) => v.canvasImage != null).map((v) => v.id!));
    _selectAll = _selectedVisitIds.length == widget.visits.where((v) => v.canvasImage != null).length;
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedVisitIds.clear();
      } else {
        _selectedVisitIds.addAll(widget.visits.where((v) => v.canvasImage != null).map((v) => v.id!));
      }
      _selectAll = !_selectAll;
    });
  }

  void _toggleSelection(int visitId) {
    setState(() {
      if (_selectedVisitIds.contains(visitId)) {
        _selectedVisitIds.remove(visitId);
      } else {
        _selectedVisitIds.add(visitId);
      }
      _selectAll = _selectedVisitIds.length == widget.visits.where((v) => v.canvasImage != null).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visitsWithImages = widget.visits.where((v) => v.canvasImage != null).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export Diagrams to PDF',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient: ${widget.patient.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select diagrams to include in PDF. Maximum 4 images per export.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Select All checkbox
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectAll,
                    onChanged: (value) => _toggleSelectAll(),
                  ),
                  const Text(
                    'Select All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedVisitIds.length} / ${visitsWithImages.length} selected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Images list
            Expanded(
              child: visitsWithImages.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No saved diagrams found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: visitsWithImages.length,
                itemBuilder: (context, index) {
                  final visit = visitsWithImages[index];
                  final isSelected = _selectedVisitIds.contains(visit.id);

                  return _buildImageCard(visit, isSelected);
                },
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _selectedVisitIds.isEmpty || _selectedVisitIds.length > 4
                        ? null
                        : () {
                      final selectedVisits = widget.visits
                          .where((v) => _selectedVisitIds.contains(v.id))
                          .toList();
                      Navigator.pop(context, selectedVisits);
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: Text(
                      _selectedVisitIds.length > 4
                          ? 'Too many selected (max 4)'
                          : 'Export ${_selectedVisitIds.length} Diagram${_selectedVisitIds.length == 1 ? '' : 's'}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(Visit visit, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _toggleSelection(visit.id!),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleSelection(visit.id!),
                ),
                const SizedBox(width: 12),

                // Thumbnail
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: visit.canvasImage != null
                        ? Image.memory(
                      visit.canvasImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image, color: Colors.grey.shade400);
                      },
                    )
                        : Icon(Icons.image, color: Colors.grey.shade400, size: 32),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              visit.system.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getDiagramDisplayName(visit.diagramType),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            _formatDateTime(visit.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            '${visit.markers.length} marker${visit.markers.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.draw, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            '${visit.drawingPaths.length} drawing${visit.drawingPaths.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selected indicator
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} ${hour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  String _getDiagramDisplayName(String diagramType) {
    final displayNames = {
      'anatomical': 'Detailed Anatomy',
      'simple': 'Simple Diagram',
      'crossSection': 'Cross-Section View',
      'nephron': 'Nephron',
      'polycystic': 'Polycystic Kidney Disease',
      'pyelonephritis': 'Pyelonephritis',
      'glomerulonephritis': 'Glomerulonephritis',
      // Add more mappings as needed
    };
    return displayNames[diagramType] ?? diagramType;
  }
}