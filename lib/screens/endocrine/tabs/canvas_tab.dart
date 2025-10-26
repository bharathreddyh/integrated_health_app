// ==================== ENHANCED CANVAS TAB WITH EDITED CATEGORY ====================
// lib/screens/endocrine/tabs/canvas_tab.dart

import 'package:flutter/material.dart';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../config/thyroid_disease_config.dart';
import '../../../config/thyroid_canvas_config.dart';
import '../../../models/visit.dart';
import '../../../services/database_helper.dart';
import '../../../models/patient.dart';
import '../../canvas/canvas_screen.dart';

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

class _CanvasTabState extends State<CanvasTab> {
  String? _selectedImageId;
  List<Visit> _editedVisits = [];
  bool _isLoadingEdits = true;

  @override
  void initState() {
    super.initState();
    _loadEditedImages();
  }

  Future<void> _loadEditedImages() async {
    setState(() => _isLoadingEdits = true);

    try {
      // Load all visits for this patient with thyroid system
      final allVisits = await DatabaseHelper.instance.getPatientVisits(
        widget.patient.id,
      );

      // Filter for thyroid system visits that are marked as edited
      final editedVisits = allVisits
          .where((v) => v.system == 'thyroid' && v.isEdited)
          .toList();

      setState(() {
        _editedVisits = editedVisits;
        _isLoadingEdits = false;
      });
    } catch (e) {
      print('Error loading edited images: $e');
      setState(() {
        _editedVisits = [];
        _isLoadingEdits = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final anatomyImages = ThyroidCanvasConfig.getAnatomyImages();
    final diseaseImages = ThyroidCanvasConfig.getDiseaseImagesOnly(
      widget.condition.diseaseId,
    );
    final hasDiseaseImages = diseaseImages.isNotEmpty;
    final hasEditedImages = _editedVisits.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _loadEditedImages,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.image, color: Color(0xFF2563EB), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'THYROID IMAGES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${anatomyImages.length + diseaseImages.length + _editedVisits.length} total',
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

            // EDITED IMAGES SECTION (Show first - most recent work)
            if (hasEditedImages) ...[
              _buildEditedSection(),
              const SizedBox(height: 32),
            ],

            // Normal Anatomy Section
            _buildImageSection(
              title: 'Normal Anatomy',
              icon: Icons.biotech,
              images: anatomyImages,
            ),

            // Disease-Specific Section
            if (hasDiseaseImages) ...[
              const SizedBox(height: 32),
              _buildImageSection(
                title: '${widget.diseaseConfig.name} Images',
                icon: Icons.medical_information,
                images: diseaseImages,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Icon(Icons.edit, size: 20, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            const Text(
              'Edited Images',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_editedVisits.length}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Your annotated diagrams',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),

        // Grid of edited images
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: _editedVisits.length,
          itemBuilder: (context, index) {
            final visit = _editedVisits[index];
            return _buildEditedImageCard(visit);
          },
        ),
      ],
    );
  }

  Widget _buildEditedImageCard(Visit visit) {
    final dateTime = visit.createdAt;
    final formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final diagramName = _getDiagramDisplayName(visit.diagramType);

    return GestureDetector(
      onTap: () => _showEditedImagePreview(visit),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Edited Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.edit, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'EDITED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Image Preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: visit.canvasImage != null
                      ? Image.memory(
                    visit.canvasImage!,
                    fit: BoxFit.cover,
                  )
                      : const Center(
                    child: Icon(Icons.image, color: Colors.grey, size: 32),
                  ),
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diagramName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.blue.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${visit.markers.length} markers',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
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
    );
  }

  Widget _buildImageSection({
    required String title,
    required IconData icon,
    required List<ThyroidImageConfig> images,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${images.length}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
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

  Widget _buildImageCard(ThyroidImageConfig image) {
    return GestureDetector(
      onTap: () => _showImagePreview(image),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
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
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    image.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                image.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(ThyroidImageConfig image) {
    setState(() {
      _selectedImageId = image.id;
    });

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _buildBigPreviewDialog(
        title: image.name,
        subtitle: image.category == 'anatomy'
            ? 'Normal Anatomy'
            : widget.diseaseConfig.name,
        child: Image.asset(
          image.imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Image not found',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
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
      builder: (context) => _buildBigPreviewDialog(
        title: _getDiagramDisplayName(visit.diagramType),
        subtitle: 'Edited: ${_formatDateTime(visit.createdAt)}',
        child: visit.canvasImage != null
            ? Image.memory(
          visit.canvasImage!,
          fit: BoxFit.contain,
        )
            : const Center(
          child: Icon(Icons.image, color: Colors.grey, size: 64),
        ),
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

  Widget _buildBigPreviewDialog({
    required String title,
    required String subtitle,
    required Widget child,
    required VoidCallback onEdit,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85, // 85% of screen height
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    iconSize: 28,
                  ),
                ],
              ),
            ),

            // Image - Takes up 3/4 of screen
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(child: child),
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('Close', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
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
                      label: const Text('Edit Image', style: TextStyle(fontSize: 16)),
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

    // Reload edited images after returning
    if (result == true) {
      _loadEditedImages();
    }
  }

  String _getDiagramDisplayName(String diagramType) {
    final displayNames = {
      'anterior': 'Anterior View',
      'lateral': 'Lateral View',
      'cross_section': 'Cross-Section View',
      'microscopic': 'Microscopic View',
      'graves_diffuse': 'Diffuse Goiter',
      'graves_vascularity': 'Increased Vascularity',
      'graves_ophthalmopathy': 'Eye Changes',
      'hashimotos_lymphocytes': 'Lymphocytic Infiltration',
      'hashimotos_destruction': 'Thyroid Destruction',
      'hashimotos_fibrosis': 'Fibrosis',
      // Add more as needed
    };
    return displayNames[diagramType] ?? diagramType;
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}