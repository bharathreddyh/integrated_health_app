// ==================== UPDATED CANVAS TAB WITH SUB-TABS ====================
// lib/screens/endocrine/tabs/canvas_tab.dart

import 'package:flutter/material.dart';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../models/patient.dart';
import '../../../config/thyroid_disease_config.dart';
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
  List<Visit> _editedVisits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Sub-tab controller for Anatomy and Diseases
    _subTabController = TabController(length: 2, vsync: this);
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

  Widget _buildAnatomyContent() {
    final anatomyImages = widget.diseaseConfig.anatomyDiagrams.entries
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

  Widget _buildDiseasesContent() {
    final diseaseImages = widget.diseaseConfig.systemTemplates.entries
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
              'No images available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${images.length + editedVisits.length} total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap an image to preview, then edit to add annotations',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // EDITED IMAGES SECTION (Show first)
          if (hasEditedImages) ...[
            _buildEditedSection(editedVisits),
            const SizedBox(height: 32),
          ],

          // Original Images Section
          if (hasImages)
            _buildImageSection(
              title: 'Available Diagrams',
              icon: Icons.image,
              images: images,
            ),
        ],
      ),
    );
  }

  Widget _buildEditedSection(List<Visit> editedVisits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note,
                color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Your Edited Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${editedVisits.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Most recent annotations and edits',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: editedVisits.length,
          itemBuilder: (context, index) {
            final visit = editedVisits[index];
            return _buildEditedImageCard(visit);
          },
        ),
      ],
    );
  }

  Widget _buildImageSection({
    required String title,
    required IconData icon,
    required List<DiagramInfo> images,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            return _buildImageCard(image);
          },
        ),
      ],
    );
  }

  Widget _buildImageCard(DiagramInfo image) {
    return InkWell(
      onTap: () => _showImagePreview(image),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  image.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image_not_supported,
                          size: 48, color: Colors.grey.shade400),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToCanvas(
                        diagramType: image.id,
                        existingVisit: null,
                      ),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  Widget _buildEditedImageCard(Visit visit) {
    return InkWell(
      onTap: () => _showEditedImagePreview(visit),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
                child: visit.canvasImage != null
                    ? Image.memory(
                  visit.canvasImage!,
                  fit: BoxFit.cover,
                )
                    : Container(
                  color: Colors.grey.shade100,
                  child: Icon(Icons.image,
                      size: 48, color: Colors.grey.shade400),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'EDITED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getDiagramDisplayName(visit.diagramType),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(visit.createdAt),
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
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(
                            color: Colors.grey.shade300, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Edit Image',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
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
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CanvasScreen(
          patient: widget.patient,
          preSelectedSystem: 'thyroid',
          preSelectedDiagramType: diagramType,
          existingVisit: existingVisit,
        ),
      ),
    );

    if (result == true) {
      _loadEditedImages();
    }
  }

  String _getDiagramDisplayName(String diagramType) {
    final displayNames = {
      'anterior': 'Anterior View',
      'lateral': 'Lateral View',
      'cross_section': 'Cross-Section',
      'microscopic': 'Microscopic View',
      'anatomical': 'Anatomical View',
      'graves_diffuse': 'Diffuse Goiter',
      'graves_vascularity': 'Increased Vascularity',
      'graves_ophthalmopathy': 'Eye Changes',
      'hashimotos_lymphocytes': 'Lymphocytic Infiltration',
      'hashimotos_destruction': 'Thyroid Destruction',
      'hashimotos_fibrosis': 'Fibrosis',
    };
    return displayNames[diagramType] ?? diagramType;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

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