// lib/screens/consultation/page2_system_selector.dart
// ✅ COMPLETE IMPLEMENTATION - ALL PHASES
// Phase 1: Tab Structure ✓
// Phase 2: Disease Templates ✓
// Phase 3: Canvas Integration ✓
// Phase 4: Complete Saved Tab ✓
// Phase 5: PDF Generation Ready ✓

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../models/consultation_data.dart';
import '../../models/disease_template.dart';
import '../../models/disease_template_data.dart';
import '../../models/visit.dart';
import '../../models/patient.dart';
import '../../services/database_helper.dart';
import '../canvas/canvas_screen.dart';
import '../../widgets/disease_template_dialog.dart';

class Page2SystemSelector extends StatefulWidget {
  const Page2SystemSelector({super.key});

  @override
  State<Page2SystemSelector> createState() => _Page2SystemSelectorState();
}

class _Page2SystemSelectorState extends State<Page2SystemSelector> {
  String? _expandedSystem;
  String _selectedTab = 'saved';
  List<Visit> _savedDiagrams = [];
  bool _isLoadingDiagrams = true;

  @override
  void initState() {
    super.initState();
    _loadSavedDiagrams();
  }

  Future<void> _loadSavedDiagrams() async {
    setState(() => _isLoadingDiagrams = true);
    try {
      final consultationData = Provider.of<ConsultationData>(context, listen: false);
      final visits = await DatabaseHelper.instance.getAllVisitsForPatient(
        patientId: consultationData.patient.id,
      );
      final diagramVisits = visits.where((v) => v.canvasImage != null).toList();
      diagramVisits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _savedDiagrams = diagramVisits;
        _isLoadingDiagrams = false;
      });
    } catch (e) {
      print('Error loading diagrams: $e');
      setState(() => _isLoadingDiagrams = false);
    }
  }

  void _resetPage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.restart_alt, color: Colors.orange.shade700),
            SizedBox(width: 8),
            Text('Reset Page?'),
          ],
        ),
        content: Text(
          'This will clear all selected items from the Saved tab.\n\n'
              'Templates and diagrams in the library will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final data = Provider.of<ConsultationData>(context, listen: false);
      data.selectedDiagramIds.clear();
      data.completedTemplates.clear();
      data.annotatedAnatomies.clear();
      setState(() => _expandedSystem = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Saved items cleared'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultationData = Provider.of<ConsultationData>(context);
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          _buildHeader(),
          _buildTabSelector(),
          Expanded(
            child: _selectedTab == 'saved'
                ? _buildSavedTab(consultationData)
                : _selectedTab == 'templates'
                ? _buildTemplatesTab(consultationData)
                : _buildAnatomyTab(consultationData),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HEADER
  // ============================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.medical_services, color: Colors.purple.shade700, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visual Content Selection',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Saved items, disease templates, and anatomy diagrams',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _resetPage,
            icon: Icon(Icons.restart_alt, size: 18),
            label: Text('Reset'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: BorderSide(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // TAB SELECTOR
  // ============================================
  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _buildTab(
            label: 'Saved',
            icon: Icons.bookmark,
            value: 'saved',
            count: _getSavedItemsCount(),
          ),
          const SizedBox(width: 12),
          _buildTab(
            label: 'Disease Templates',
            icon: Icons.medical_information,
            value: 'templates',
          ),
          const SizedBox(width: 12),
          _buildTab(
            label: 'Anatomy Diagrams',
            icon: Icons.category,
            value: 'anatomy',
          ),
        ],
      ),
    );
  }

  int _getSavedItemsCount() {
    final data = Provider.of<ConsultationData>(context, listen: false);
    return data.selectedDiagramIds.length +
        data.completedTemplates.length +
        data.annotatedAnatomies.length;
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required String value,
    int? count,
  }) {
    final isSelected = _selectedTab == value;
    return InkWell(
      onTap: () => setState(() => _selectedTab = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================
  // SAVED TAB - PHASE 4 COMPLETE
  // ============================================
  Widget _buildSavedTab(ConsultationData data) {
    final totalItems = data.selectedDiagramIds.length +
        data.completedTemplates.length +
        data.annotatedAnatomies.length;

    if (totalItems == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Saved Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add templates or annotate diagrams to see them here',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedTab = 'templates'),
                  icon: Icon(Icons.medical_information),
                  label: Text('Browse Templates'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedTab = 'anatomy'),
                  icon: Icon(Icons.category),
                  label: Text('Browse Anatomy'),
                ),
              ],
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
          // Summary Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalItems item${totalItems == 1 ? '' : 's'} ready for PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All items below will be included in the consultation report',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Saved Diagrams Section
          if (data.selectedDiagramIds.isNotEmpty) ...[
            _buildSectionHeader(
              'Saved Diagrams',
              Icons.photo_library,
              Colors.blue,
              data.selectedDiagramIds.length,
            ),
            const SizedBox(height: 12),
            ..._buildSavedDiagramCards(data),
            const SizedBox(height: 24),
          ],

          // Completed Templates Section
          if (data.completedTemplates.isNotEmpty) ...[
            _buildSectionHeader(
              'Completed Disease Templates',
              Icons.medical_information,
              Colors.purple,
              data.completedTemplates.length,
            ),
            const SizedBox(height: 12),
            ..._buildCompletedTemplateCards(data),
            const SizedBox(height: 24),
          ],

          // Annotated Anatomies Section
          if (data.annotatedAnatomies.isNotEmpty) ...[
            _buildSectionHeader(
              'Annotated Anatomy Diagrams',
              Icons.category,
              Colors.teal,
              data.annotatedAnatomies.length,
            ),
            const SizedBox(height: 12),
            ..._buildAnnotatedAnatomyCards(data),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,  // ✅ FIXED
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,  // ✅ FIXED
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSavedDiagramCards(ConsultationData data) {
    return data.selectedDiagramIds.map((diagramId) {
      final diagram = _savedDiagrams.firstWhere(
            (v) => v.id == diagramId,
        orElse: () => Visit(
          id: diagramId,
          patientId: data.patient.id,
          system: 'Unknown',
          diagramType: 'Unknown',
          markers: [],
          drawingPaths: [],
          createdAt: DateTime.now(),
        ),
      );

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: diagram.canvasImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                diagram.canvasImage!,
                fit: BoxFit.cover,
              ),
            )
                : Icon(Icons.image, color: Colors.blue.shade700),
          ),
          title: Text(
            '${_capitalizeFirst(diagram.system)} - ${_capitalizeFirst(diagram.diagramType)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${diagram.markers.length} markers, ${diagram.drawingPaths.length} drawings',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDateTime(diagram.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editDiagram(diagram),
                tooltip: 'Edit diagram',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _deleteSavedDiagram(data, diagramId),
                tooltip: 'Remove from saved',
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildCompletedTemplateCards(ConsultationData data) {
    return data.completedTemplates.asMap().entries.map((entry) {
      final index = entry.key;
      final template = entry.value;
      final templateName = template['templateName'] ?? 'Unknown Template';
      final createdAt = template['createdAt'] ?? DateTime.now().toIso8601String();

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.medical_information,
              color: Colors.purple.shade700,
              size: 24,
            ),
          ),
          title: Text(
            templateName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _getTemplatePreview(template),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _formatDateTime(DateTime.parse(createdAt)),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editTemplate(data, index, template),
                tooltip: 'Edit template',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _deleteTemplate(data, index),
                tooltip: 'Remove from saved',
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildAnnotatedAnatomyCards(ConsultationData data) {
    return data.annotatedAnatomies.asMap().entries.map((entry) {
      final index = entry.key;
      final anatomy = entry.value;
      final systemName = anatomy['systemName'] ?? 'Unknown';
      final viewType = anatomy['viewType'] ?? 'Unknown';
      final createdAt = anatomy['createdAt'] ?? DateTime.now().toIso8601String();

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category,
              color: Colors.teal.shade700,
              size: 24,
            ),
          ),
          title: Text(
            '$systemName - $viewType',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  if (anatomy['hasAnnotations'] == true) ...[
                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Annotated',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else
                    Text(
                      'No annotations',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _formatDateTime(DateTime.parse(createdAt)),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editAnnotatedAnatomy(anatomy),
                tooltip: 'Edit annotations',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _deleteAnnotatedAnatomy(data, index),
                tooltip: 'Remove from saved',
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ============================================
  // TEMPLATES TAB - PHASE 2 COMPLETE
  // ============================================
  Widget _buildTemplatesTab(ConsultationData data) {
    final groupedTemplates = DiseaseTemplates.groupedBySystem;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: groupedTemplates.entries.map((entry) {
          final systemId = entry.key;
          final templates = entry.value;
          final system = MedicalSystems.getById(systemId);

          if (system == null) return const SizedBox.shrink();

          final isExpanded = _expandedSystem == systemId;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedSystem = isExpanded ? null : systemId;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              system.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                system.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${templates.length} template${templates.length == 1 ? '' : 's'} available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey.shade600,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Column(
                    children: templates.map((template) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.medical_information,
                              color: Colors.purple.shade700,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${template.requiredLabTests.length} lab tests required',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (template.requiredLabTests.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: template.requiredLabTests
                                      .take(3)
                                      .map((test) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      test,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                  ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (context) => DiseaseTemplateDialog(
                                  template: template,
                                ),
                              );

                              if (result != null && mounted) {
                                data.addCompletedTemplate(result);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text('${template.name} saved to Saved tab'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    action: SnackBarAction(
                                      label: 'VIEW',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        setState(() => _selectedTab = 'saved');
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================
  // ANATOMY TAB - PHASE 3 COMPLETE
  // ============================================
  Widget _buildAnatomyTab(ConsultationData data) {
    final anatomySystems = [
      {'id': 'kidney', 'name': 'Kidney', 'icon': '🫘'},
      {'id': 'heart', 'name': 'Heart', 'icon': '❤️'},
      {'id': 'lungs', 'name': 'Lungs', 'icon': '🫁'},
      {'id': 'brain', 'name': 'Brain', 'icon': '🧠'},
      {'id': 'liver', 'name': 'Liver', 'icon': '🟤'},
      {'id': 'spine', 'name': 'Spine', 'icon': '🦴'},
    ];

    final views = {
      'kidney': ['anatomical', 'cross_section', 'nephron', 'simple'],
      'heart': ['anterior', 'posterior', 'cross_section', 'coronary'],
      'lungs': ['anterior', 'posterior', 'lobes'],
      'brain': ['sagittal', 'coronal', 'axial'],
      'liver': ['anatomical', 'segments', 'blood_supply'],
      'spine': ['cervical', 'thoracic', 'lumbar'],
    };

    final viewLabels = {
      'anatomical': 'Anatomical',
      'cross_section': 'Cross Section',
      'nephron': 'Nephron',
      'simple': 'Simple',
      'anterior': 'Anterior View',
      'posterior': 'Posterior View',
      'coronary': 'Coronary Arteries',
      'lobes': 'Lobes',
      'sagittal': 'Sagittal View',
      'coronal': 'Coronal View',
      'axial': 'Axial View',
      'segments': 'Liver Segments',
      'blood_supply': 'Blood Supply',
      'cervical': 'Cervical Spine',
      'thoracic': 'Thoracic Spine',
      'lumbar': 'Lumbar Spine',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: anatomySystems.map((system) {
          final systemId = system['id'] as String;
          final systemName = system['name'] as String;
          final systemIcon = system['icon'] as String;
          final isExpanded = _expandedSystem == systemId;
          final systemViews = views[systemId] ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedSystem = isExpanded ? null : systemId;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              systemIcon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                systemName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${systemViews.length} diagram${systemViews.length == 1 ? '' : 's'} available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey.shade600,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Column(
                    children: systemViews.map((viewType) {
                      final viewLabel = viewLabels[viewType] ?? viewType;

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.category,
                              color: Colors.teal.shade700,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            viewLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Detailed $systemName diagram',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: () async {
                              // Navigate to canvas with pre-loaded anatomy
                              final result = await Navigator.push<int?>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CanvasScreen(
                                    patient: data.patient,
                                    preSelectedSystem: systemId,
                                    preSelectedDiagramType: viewType,
                                  ),
                                ),
                              );

                              // If user saved (returns visitId)
                              if (result != null && mounted) {
                                // Get the saved visit from database
                                final visit = await DatabaseHelper.instance.getVisitById(result);

                                if (visit != null) {
                                  // Add to ConsultationData
                                  data.addAnnotatedAnatomy({
                                    'visitId': visit.id,
                                    'systemName': systemName,
                                    'systemId': systemId,
                                    'viewType': viewLabel,
                                    'createdAt': visit.createdAt.toIso8601String(),
                                    'hasAnnotations': visit.markers.isNotEmpty ||
                                        visit.drawingPaths.isNotEmpty,
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '$systemName - $viewLabel saved to Saved tab',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      action: SnackBarAction(
                                        label: 'VIEW',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          setState(() => _selectedTab = 'saved');
                                        },
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================
  // HELPER METHODS
  // ============================================
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).replaceAll('_', ' ');
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _getTemplatePreview(Map<String, dynamic> template) {
    final data = template['data'] as Map<String, dynamic>? ?? {};
    final findings = data['findings'] as String? ?? '';
    final diagnosis = data['diagnosis'] as String? ?? '';

    if (findings.isNotEmpty) return findings;
    if (diagnosis.isNotEmpty) return diagnosis;

    // Show first few lab values
    final labValues = <String>[];
    data.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        labValues.add('$key: $value');
      }
    });

    if (labValues.isNotEmpty) {
      return labValues.take(2).join(', ');
    }

    return 'Template filled';
  }

  // ============================================
  // EDIT/DELETE ACTIONS
  // ============================================
  void _editDiagram(Visit diagram) async {
    final data = Provider.of<ConsultationData>(context, listen: false);

    final result = await Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder: (context) => CanvasScreen(
          patient: data.patient,
          existingVisit: diagram,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _loadSavedDiagrams();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagram updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteSavedDiagram(ConsultationData data, int diagramId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Diagram?'),
        content: const Text(
          'This will remove the diagram from saved items.\n\n'
              'The diagram will remain in the database and can be added again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        data.selectedDiagramIds.remove(diagramId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagram removed from saved items'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editTemplate(ConsultationData data, int index, Map<String, dynamic> template) async {
    final templateId = template['templateId'] as String?;
    if (templateId == null) return;

    final diseaseTemplate = DiseaseTemplates.getById(templateId);
    if (diseaseTemplate == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DiseaseTemplateDialog(
        template: diseaseTemplate,
        existingData: template,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        data.completedTemplates[index] = result;
      });
      data.notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteTemplate(ConsultationData data, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Template?'),
        content: const Text(
          'This will remove the template from saved items.\n\n'
              'You can fill it again from the Disease Templates tab.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        data.completedTemplates.removeAt(index);
      });
      data.notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template removed from saved items'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editAnnotatedAnatomy(Map<String, dynamic> anatomy) async {
    final visitId = anatomy['visitId'] as int?;
    if (visitId == null) return;

    final visit = await DatabaseHelper.instance.getVisitById(visitId);
    if (visit == null) return;

    final data = Provider.of<ConsultationData>(context, listen: false);

    final result = await Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder: (context) => CanvasScreen(
          patient: data.patient,
          existingVisit: visit,
        ),
      ),
    );

    if (result != null && mounted) {
      // Update the anatomy data with latest changes
      final updatedVisit = await DatabaseHelper.instance.getVisitById(result);
      if (updatedVisit != null) {
        // Find and update the anatomy in the list
        final anatomyIndex = data.annotatedAnatomies.indexWhere(
              (a) => a['visitId'] == visitId,
        );

        if (anatomyIndex >= 0) {
          data.annotatedAnatomies[anatomyIndex] = {
            ...anatomy,
            'hasAnnotations': updatedVisit.markers.isNotEmpty ||
                updatedVisit.drawingPaths.isNotEmpty,
            'createdAt': updatedVisit.createdAt.toIso8601String(),
          };
          data.notifyListeners();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anatomy diagram updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteAnnotatedAnatomy(ConsultationData data, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Anatomy Diagram?'),
        content: const Text(
          'This will remove the diagram from saved items.\n\n'
              'The diagram will remain in the database and can be added again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        data.annotatedAnatomies.removeAt(index);
      });
      data.notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anatomy diagram removed from saved items'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}