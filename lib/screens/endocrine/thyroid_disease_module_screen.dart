// ==================== THYROID DISEASE MODULE - 6 TAB VERSION ====================
// lib/screens/endocrine/thyroid_disease_module_screen.dart

import 'package:flutter/material.dart';
import '../../models/endocrine/endocrine_condition.dart';
import '../../config/thyroid_disease_config.dart';
import 'tabs/overview_tab.dart';
import 'tabs/canvas_tab.dart';
import 'tabs/labs_trends_tab.dart';
import 'tabs/clinical_features_tab.dart';
import 'tabs/investigations_tab.dart';
import 'tabs/treatment_tab.dart';
import 'tabs/patient_data_tab.dart'; // ✅ Add import

class ThyroidDiseaseModuleScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String diseaseId;
  final String diseaseName;
  final bool isQuickMode;

  const ThyroidDiseaseModuleScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.diseaseId,
    required this.diseaseName,
    this.isQuickMode = false,
  });

  @override
  State<ThyroidDiseaseModuleScreen> createState() =>
      _ThyroidDiseaseModuleScreenState();
}

class _ThyroidDiseaseModuleScreenState extends State<ThyroidDiseaseModuleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EndocrineCondition _condition;
  late ThyroidDiseaseConfig _diseaseConfig;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this); // Changed to 6 tabs
    _diseaseConfig = ThyroidDiseaseConfig.getDiseaseConfig(widget.diseaseId)!;

    // Initialize or load existing condition
    _condition = EndocrineCondition(
      id: 'thyroid_${DateTime.now().millisecondsSinceEpoch}',
      patientId: widget.patientId,
      patientName: widget.patientName, // ✅ Add patient name
      gland: 'thyroid',
      category: _diseaseConfig.category,
      diseaseId: widget.diseaseId,
      diseaseName: widget.diseaseName,
      status: DiagnosisStatus.suspected,
    );

    _tabController.addListener(() {
      setState(() {}); // Rebuild to update tab indicator
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveCondition() async {
    try {
      // TODO: Save to database
      // await DatabaseHelper.instance.saveEndocrineCondition(_condition);

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Condition saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateCondition(EndocrineCondition updatedCondition) {
    setState(() {
      _condition = updatedCondition;
      _hasUnsavedChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(),

            // Tab Bar with 6 tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: const Color(0xFF2563EB),
                indicatorWeight: 3,
                isScrollable: true, // Made scrollable for 6 tabs
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(text: 'Patient Data'),
                  Tab(text: 'Clinical'),
                  Tab(text: 'Canvas'),
                  Tab(text: 'Labs'),
                  Tab(text: 'Overview'),
                  Tab(text: 'Investigations'),
                  Tab(text: 'Treatment'),
                ],
              ),
            ),

            // Tab Content - 7 tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0 - Patient Data
                  PatientDataTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                  ),
                  // Tab 1: Clinical Features
                  ClinicalFeaturesTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                  ),
                  // Tab 2: Canvas
                  CanvasTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                  ),
                  // Tab 3: Labs & Trends
                  LabsTrendsTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                  ),
                  // Tab 4: Overview
                  OverviewTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                  ),
                  // Tab 5: Investigations
                  InvestigationsTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                  ),
                  // Tab 6: Treatment
                  TreatmentTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                  ),
                ],
              ),
            ),

            // Bottom Action Bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2563EB), const Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (_hasUnsavedChanges) {
                final shouldPop = await _showUnsavedChangesDialog();
                if (shouldPop == true && mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '🦋',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.diseaseName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_hasUnsavedChanges)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'UNSAVED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      widget.isQuickMode ? Icons.flash_on : Icons.person,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isQuickMode
                          ? 'Quick Template Mode'
                          : 'Patient: ${widget.patientName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
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

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Indicator
          Expanded(
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(_condition.status),
                  size: 20,
                  color: _getStatusColor(_condition.status),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(_condition.status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(_condition.status),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _hasUnsavedChanges ? _saveCondition : null,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveCondition();
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(DiagnosisStatus status) {
    switch (status) {
      case DiagnosisStatus.suspected:
        return Icons.help_outline;
      case DiagnosisStatus.provisional:  // 🆕 ADD
        return Icons.help_outline;
      case DiagnosisStatus.confirmed:
        return Icons.check_circle;
      case DiagnosisStatus.ruledOut:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(DiagnosisStatus status) {
    switch (status) {
      case DiagnosisStatus.suspected:
        return Colors.orange;
      case DiagnosisStatus.provisional:  // 🆕 ADD
        return Colors.blue;
      case DiagnosisStatus.confirmed:
        return Colors.green;
      case DiagnosisStatus.ruledOut:
        return Colors.grey;
    }
  }

  String _getStatusText(DiagnosisStatus status) {
    switch (status) {
      case DiagnosisStatus.suspected:
        return 'Suspected';
      case DiagnosisStatus.provisional:  // 🆕 ADD
        return 'Provisional';
      case DiagnosisStatus.confirmed:
        return 'Confirmed';
      case DiagnosisStatus.ruledOut:
        return 'Ruled Out';
    }
  }
}