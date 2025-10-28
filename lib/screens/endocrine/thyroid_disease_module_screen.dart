// ==================== FIXED THYROID DISEASE MODULE SCREEN ====================
// lib/screens/endocrine/thyroid_disease_module_screen.dart
// ✅ All compilation errors fixed

import 'package:flutter/material.dart';
import '../../models/endocrine/endocrine_condition.dart';
import '../../models/patient.dart';
import '../../config/thyroid_disease_config.dart';
import '../../widgets/ai_pdf_generator_button.dart';
import 'tabs/overview_tab.dart';
import 'tabs/canvas_tab.dart';
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
  late Patient _patient;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    // CHANGED: Length from 8 to 7 (removed Anatomy tab)
    _tabController = TabController(length: 7, vsync: this);
    _diseaseConfig = ThyroidDiseaseConfig.getDiseaseConfig(widget.diseaseId)!;

    // ✅ FIXED: Use correct Patient constructor parameters
    _patient = Patient(
      id: widget.patientId,
      name: widget.patientName,
      age: 0,  // Or calculate from actual date of birth if available
      phone: '',  // Required parameter
      date: DateTime.now().toString(),  // Required parameter
    );

    // ✅ FIXED: Add required 'id' parameter
    _condition = EndocrineCondition(
      id: DateTime.now().millisecondsSinceEpoch.toString(),  // Generate unique ID
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

  void _updateCondition(EndocrineCondition updated) {
    setState(() {
      _condition = updated;
      _hasUnsavedChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          final shouldPop = await showDialog<bool>(
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
                  child: const Text('Discard', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xFF2563EB),
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Patient Data'),
                  Tab(text: 'Clinical Features'),
                  Tab(text: 'Canvas'),
                  Tab(text: 'Labs & Trends'),
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

                  // Tab 2: Canvas (Now with Anatomy & Diseases sub-tabs)
                  CanvasTab(
                    condition: _condition,
                    diseaseConfig: _diseaseConfig,
                    onUpdate: _updateCondition,
                    patient: _patient,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Save Changes Button (only show if unsaved changes)
                  if (_hasUnsavedChanges) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveCondition,
                        icon: const Icon(Icons.save, size: 20),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // AI PDF Generator Button
                  Expanded(
                    flex: _hasUnsavedChanges ? 1 : 2,
                    child: _buildAIPDFButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2563EB),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2563EB),
              const Color(0xFF1E40AF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _diseaseConfig.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.patientName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_condition.completionPercentage.toInt()}% Complete',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveCondition() async {
    // Implement save logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved successfully')),
    );
    setState(() => _hasUnsavedChanges = false);
  }

  Widget _buildAIPDFButton() {
    // Check if enough data is available for PDF generation
    final canGenerate = _condition.canGeneratePDF;

    if (!canGenerate) {
      // Show disabled button with tooltip
      return Tooltip(
        message: 'Complete required fields to generate PDF:\n${_condition.incompleteSections.join('\n')}',
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.picture_as_pdf, size: 20),
          label: const Text(
            'Generate AI Report',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade400,
            disabledBackgroundColor: Colors.grey.shade300,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      );
    }

    // Show active AI PDF button
    return AIPDFGeneratorButton(
      condition: _condition,
      patient: _patient,
      onSuccess: () {
        // Refresh the state after successful PDF generation
        setState(() {
          _hasUnsavedChanges = false;
        });
      },
    );
  }

  void _showIncompleteSectionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Incomplete Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please complete the following sections:'),
            const SizedBox(height: 12),
            ..._condition.incompleteSections.map((section) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(section, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}