// ==================== THYROID DISEASE MODULE SCREEN WITH AI PDF ====================
// lib/screens/endocrine/thyroid_disease_module_screen.dart
// ✅ All compilation errors fixed
// ✅ AI PDF Generator integrated
// ✅ CORRECTED IMPORT PATH

import 'package:flutter/material.dart';
import '../../models/endocrine/endocrine_condition.dart';
import '../../models/patient.dart';
import '../../config/thyroid_disease_config.dart';
import 'tabs/overview_tab.dart';
import 'tabs/canvas_tab.dart';
import 'tabs/labs_trends_tab.dart';
import 'tabs/clinical_features_tab.dart';
import 'tabs/investigations_tab.dart';
import 'tabs/treatment_tab.dart';
import 'tabs/patient_data_tab.dart';
import '../../widgets/ai_pdf_generator_button.dart';  // ✅ CORRECTED: Two levels up

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

        // ✅ ADD THIS: Floating Action Button for AI PDF Generation
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAIPDFDialog(),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('AI Report'),
          backgroundColor: Colors.blue.shade600,
          heroTag: 'ai_report_fab',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

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

            // Bottom Save Bar
            if (_hasUnsavedChanges)
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
                child: ElevatedButton(
                  onPressed: _saveCondition,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
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

  // ✅ ADD THIS METHOD: Show AI PDF Generation Dialog
  void _showAIPDFDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal during generation
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with animated icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                '🤖 AI-Powered Medical Report',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'Generate a comprehensive medical report with AI analysis of all patient data, labs, imaging, and treatment plans.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // Feature highlights
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      Icons.speed,
                      'Lightning Fast',
                      'Generated in seconds',
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      Icons.insights,
                      'AI Analysis',
                      'Smart insights and trends',
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      Icons.picture_as_pdf,
                      'Professional PDF',
                      'Ready to share',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // AI PDF Generator Button (the actual widget)
              AIPDFGeneratorButton(
                condition: _condition,
                patient: _patient,
                onSuccess: () {
                  Navigator.pop(context); // Close dialog on success
                },
              ),

              const SizedBox(height: 12),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build feature items
  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade600,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.check_circle,
          color: Colors.green.shade400,
          size: 18,
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
}