// ==================== FIXED CANVAS TAB WITH SUB-TABS ====================
// lib/screens/endocrine/tabs/canvas_tab.dart
// ✅ Fixed: Using SystemConfig for anatomyDiagrams and systemTemplates

import 'package:flutter/material.dart';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../models/patient.dart';
import '../../../config/thyroid_disease_config.dart';
import '../../../config/canvas_system_config.dart';  // ✅ ADDED: Import SystemConfig
import '../../../models/visit.dart';
import '../../../services/database_helper.dart';
import '../../canvas/canvas_screen.dart';
import 'dart:typed_data';

class CanvasTab extends StatefulWidget {
  final EndocrineCondition condition;
  final ThyroidDiseaseConfig diseaseConfig;
  final Function(EndocrineCondition) onUpdate;
  final Patient patient;

  const CanvasTab({
    super.key,
    required this.condition,
    required this.diseaseConfig,
    required this.onUpdate,
    required this.patient,
  });

  @override
  State<CanvasTab> createState() => _CanvasTabState();
}

class _CanvasTabState extends State<CanvasTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  late SystemConfig _systemConfig;  // ✅ ADDED: SystemConfig variable
  List<Visit> _editedVisits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Sub-tab controller for Anatomy and Diseases
    _subTabController = TabController(length: 2, vsync: this);
    _systemConfig = CanvasSystemConfig.systems['thyroid']!;  // ✅ ADDED: Initialize SystemConfig
    _loadEditedImages();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _loadEditedImages() async {
    try {
      final db = DatabaseHelper.instance;
      final visits = await db.getVisitsByPatient(widget.patient.id);

      setState(() {
        _editedVisits = visits
            .where((v) => v.canvasImage != null && v.system == 'thyroid')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading edited images: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-Tab Bar for Anatomy and Diseases
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _subTabController,
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: const Color(0xFF2563EB),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            tabs: [
              Tab(
                icon: const Icon(Icons.biotech, size: 20),
                text: 'Anatomy',
              ),
              Tab(
                icon: const Icon(Icons.medical_information, size: 20),
                text: 'Diseases',
              ),
            ],
          ),
        ),

        // Sub-Tab Content
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              // Anatomy Sub-Tab
              _buildAnatomyContent(),

              // Diseases Sub-Tab
              _buildDiseasesContent(),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ FIXED: Now using _systemConfig.anatomyDiagrams
  Widget _buildAnatomyContent() {
    final anatomyImages = _systemConfig.anatomyDiagrams.entries
        .map((e) => DiagramInfo(
      id: e.key,
      name: e.value.name,
      imagePath: e.value.imagePath,
      category: 'anatomy',
    ))
        .toList();

    return _buildImageGallery(
      title: 'Normal Anatomy',
      subtitle: 'Explore normal thyroid anatomy diagrams',
      images: anatomyImages,
      editedVisits: _editedVisits
          .where((v) => _isAnatomyDiagram(v.diagramType))
          .toList(),
    );
  }

  // ✅ FIXED: Now using _systemConfig.systemTemplates
  Widget _buildDiseasesContent() {
    final diseaseImages = _systemConfig.systemTemplates.entries
        .map((e) => DiagramInfo(
      id: e.key,
      name: e.value.name,
      imagePath: e.value.imagePath,
      category: 'disease',
    ))
        .toList();

    return _buildImageGallery(
      title: widget.diseaseConfig.name,
      subtitle: 'Disease-specific imaging and pathology',
      images: diseaseImages,
      editedVisits: _editedVisits
          .where((v) => !_isAnatomyDiagram(v.diagramType))
          .toList(),
    );
  }

  bool _isAnatomyDiagram(String diagramType) {
    final anatomyTypes = [
      'anterior',
      'lateral',
      'cross_section',
      'microscopic',
      'anatomical',
    ];
    return anatomyTypes.contains(diagramType);
  }

  Widget _buildImageGallery({
    required String title,
    required String subtitle,
    required List<DiagramInfo> images,
    required List<Visit> editedVisits,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasEditedImages = editedVisits.isNotEmpty;
    final hasImages = images.isNotEmpty;

    if (!hasImages && !hasEditedImages) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No diagrams available',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edited Images Section (if any)
          if (hasEditedImages) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your Edited Diagrams',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Icon(Icons.swipe, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Swipe →',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildEditedImagesGrid(editedVisits),
            const SizedBox(height: 24),
          ],

          // Available Templates Section
          if (hasImages) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.swipe, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Swipe →',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildImageGrid(images),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<DiagramInfo> images) {
    return SizedBox(
      height: 200, // Fixed height for horizontal scroll
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < images.length - 1 ? 12 : 0,
            ),
            child: _buildImageCard(image),
          );
        },
      ),
    );
  }

  Widget _buildImageCard(DiagramInfo image) {
    return GestureDetector(
      onTap: () => _showImagePreview(image),
      child: SizedBox(
        width: 160, // Fixed width for horizontal scroll
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.asset(
                  image.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      image.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToCanvas(
                        diagramType: image.id,
                        existingVisit: null,
                      ),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        minimumSize: const Size(double.infinity, 32),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditedImagesGrid(List<Visit> visits) {
    return SizedBox(
      height: 200, // Fixed height for horizontal scroll
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final visit = visits[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < visits.length - 1 ? 12 : 0,
            ),
            child: _buildEditedImageCard(visit),
          );
        },
      ),
    );
  }

  Widget _buildEditedImageCard(Visit visit) {
    return GestureDetector(
      onTap: () => _showEditedImagePreview(visit),
      child: SizedBox(
        width: 160, // Fixed width for horizontal scroll
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: visit.canvasImage != null
                    ? Image.memory(visit.canvasImage!, fit: BoxFit.cover)
                    : Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDiagramDisplayName(visit.diagramType),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(visit.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToCanvas(
                        diagramType: visit.diagramType,
                        existingVisit: visit,
                      ),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Re-edit', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        minimumSize: const Size(double.infinity, 32),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePreview(DiagramInfo image) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _buildPreviewDialog(
        title: image.name,
        subtitle: 'Tap Edit to add annotations',
        child: Image.asset(
          image.imagePath,
          fit: BoxFit.contain,
        ),
        onEdit: () {
          Navigator.pop(context);
          _navigateToCanvas(
            diagramType: image.id,
            existingVisit: null,
          );
        },
      ),
    );
  }

  void _showEditedImagePreview(Visit visit) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _buildPreviewDialog(
        title: _getDiagramDisplayName(visit.diagramType),
        subtitle: 'Edited: ${_formatDateTime(visit.createdAt)}',
        child: visit.canvasImage != null
            ? Image.memory(visit.canvasImage!, fit: BoxFit.contain)
            : const Icon(Icons.image, size: 100),
        onEdit: () {
          Navigator.pop(context);
          _navigateToCanvas(
            diagramType: visit.diagramType,
            existingVisit: visit,
          );
        },
      ),
    );
  }

  Widget _buildPreviewDialog({
    required String title,
    required String subtitle,
    required Widget child,
    required VoidCallback onEdit,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('Close',
                          style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Edit',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCanvas({
    required String diagramType,
    Visit? existingVisit,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CanvasScreen(
          patient: widget.patient,
          preSelectedSystem: 'thyroid',
          preSelectedDiagramType: diagramType,
          existingVisit: existingVisit,
        ),
      ),
    ).then((_) {
      _loadEditedImages();
    });
  }

  String _getDiagramDisplayName(String diagramType) {
    final diagrams = {..._systemConfig.anatomyDiagrams, ..._systemConfig.systemTemplates};
    return diagrams[diagramType]?.name ?? diagramType;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Helper class for diagram information
class DiagramInfo {
  final String id;
  final String name;
  final String imagePath;
  final String category;

  DiagramInfo({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.category,
  });
}