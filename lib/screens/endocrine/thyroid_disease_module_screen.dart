// ==================== FIXED THYROID DISEASE MODULE SCREEN ====================
// lib/screens/endocrine/thyroid_disease_module_screen.dart

import 'package:flutter/material.dart';
import '../../models/endocrine/endocrine_condition.dart';
import '../../models/patient.dart';  // ADD THIS IMPORT
import '../../config/thyroid_disease_config.dart';
import 'tabs/overview_tab.dart';
import 'tabs/canvas_tab.dart';
import 'tabs/anatomy_tab.dart';  // ADD THIS IMPORT
import 'tabs/labs_trends_tab.dart';
import 'tabs/clinical_features_tab.dart';
import 'tabs/investigations_tab.dart';
import 'tabs/treatment_tab.dart';
import 'tabs/patient_data_tab.dart';

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
  late Patient _patient;  // ADD THIS
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _diseaseConfig = ThyroidDiseaseConfig.getDiseaseConfig(widget.diseaseId)!;

    // CREATE PATIENT OBJECT - ADD THIS
    _patient = Patient(
      id: widget.patientId,
      name: widget.patientName,
      age: 0,  // You can update this from actual patient data
      phone: '',  // You can update this from actual patient data
      date: DateTime.now().toString().split(' ')[0],
    );

    // Initialize condition
    _condition = EndocrineCondition(
      id: 'thyroid_${DateTime.now().millisecondsSinceEpoch}',
      patientId: widget.patientId,
      patientName: widget.patientName,
      gland: 'thyroid',
      category: _diseaseConfig.category,
      diseaseId: widget.diseaseId,
      diseaseName: widget.diseaseName,
      status: DiagnosisStatus.suspected,
    );

    _tabController.addListener(() {
      setState(() {});
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

  Future<bool?> _showUnsavedChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveCondition();
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: const Color(0xFF2563EB),
                indicatorWeight: 3,
                isScrollable: true,
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
                  Tab(text: 'Anatomy'),  // CHANGED from 'Canvas'
                  Tab(text: 'Canvas'),
                  Tab(text: 'Labs'),
                  Tab(text: 'Overview'),
                  Tab(text: 'Investigations'),
                  Tab(text: 'Treatment'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0: Patient Data
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

                  // Tab 2: Anatomy (NEW - with canvas button)
                  AnatomyTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                    patient: _patient,  // PASS PATIENT HERE
                  ),

                  // Tab 3: Canvas (Image gallery with edited section)
                  CanvasTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                    patient: _patient,  // PASS PATIENT HERE
                  ),

                  // Tab 4: Labs & Trends
                  LabsTrendsTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                  ),

                  // Tab 5: Overview
                  OverviewTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                  ),

                  // Tab 6: Investigations
                  InvestigationsTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                  ),

                  // Tab 7: Treatment
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.diseaseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.patientName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (_hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Unsaved',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quick Mode indicator
          if (widget.isQuickMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Quick Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Save Button
          ElevatedButton.icon(
            onPressed: _hasUnsavedChanges ? _saveCondition : null,
            icon: const Icon(Icons.save, size: 20),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}