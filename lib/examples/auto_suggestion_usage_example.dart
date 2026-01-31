// lib/examples/auto_suggestion_usage_example.dart
// Comprehensive example demonstrating the Enhanced Template Auto-Suggestion System

import 'package:flutter/material.dart';
import '../models/enhanced_disease_template.dart';
import '../repositories/template_repository.dart';
import '../services/template_suggestion_service.dart';
import '../widgets/auto_suggestion_panel.dart';

/// Example demonstrating how to use the Auto-Suggestion System in a consultation flow
class AutoSuggestionUsageExample extends StatefulWidget {
  const AutoSuggestionUsageExample({super.key});

  @override
  State<AutoSuggestionUsageExample> createState() => _AutoSuggestionUsageExampleState();
}

class _AutoSuggestionUsageExampleState extends State<AutoSuggestionUsageExample> {
  EnhancedDiseaseTemplate? _selectedTemplate;
  PatientContext? _patientContext;

  // Consultation data
  DateTime? _selectedNextVisit;
  List<String> _selectedInvestigations = [];
  String? _followUpPlan;

  @override
  void initState() {
    super.initState();
    _initializeExample();
  }

  void _initializeExample() {
    // Get a sample template (Diabetes)
    _selectedTemplate = TemplateRepository.instance.getTemplateById('dm_type2_v1');

    // Create a sample patient context
    _patientContext = _createSamplePatientContext();
  }

  /// Create different patient scenarios for demonstration
  PatientContext _createSamplePatientContext() {
    // SCENARIO 1: New Diabetes Diagnosis
    return PatientContext(
      patientId: 'P12345',
      age: 52,
      gender: 'Male',
      currentVitals: {
        'fasting_blood_sugar': 185.0,
        'hba1c': 8.5,
        'systolic_bp': 138.0,
        'diastolic_bp': 88.0,
        'weight': 82.0,
      },
      currentComplaints: [
        'Increased thirst',
        'Frequent urination',
        'Fatigue',
      ],
      currentMedications: [
        'Metformin 500mg BD',
      ],
      lastVisitDate: null, // New diagnosis
      lastInvestigations: {}, // No previous investigations
      lastVitals: {},
      chronicConditions: ['Prediabetes', 'Obesity'],
      isNewDiagnosis: true,
      hasComplications: false,
      controlStatus: 'uncontrolled',
    );

    /* OTHER SCENARIOS YOU CAN TEST:

    // SCENARIO 2: Uncontrolled Diabetes (existing patient)
    return PatientContext(
      patientId: 'P12346',
      age: 58,
      gender: 'Female',
      currentVitals: {
        'fasting_blood_sugar': 220.0,
        'hba1c': 9.2,
        'systolic_bp': 145.0,
        'diastolic_bp': 92.0,
      },
      lastVisitDate: DateTime.now().subtract(const Duration(days: 95)),
      lastInvestigations: {
        'HBA1C': DateTime.now().subtract(const Duration(days: 95)),
        'FBS': DateTime.now().subtract(const Duration(days: 30)),
        'LIPID': DateTime.now().subtract(const Duration(days: 200)),
      },
      isNewDiagnosis: false,
      hasComplications: false,
      controlStatus: 'uncontrolled',
    );

    // SCENARIO 3: Well-Controlled Diabetes
    return PatientContext(
      patientId: 'P12347',
      age: 45,
      gender: 'Male',
      currentVitals: {
        'fasting_blood_sugar': 105.0,
        'hba1c': 6.5,
        'systolic_bp': 125.0,
        'diastolic_bp': 80.0,
      },
      lastVisitDate: DateTime.now().subtract(const Duration(days: 85)),
      lastInvestigations: {
        'HBA1C': DateTime.now().subtract(const Duration(days: 85)),
        'FBS': DateTime.now().subtract(const Duration(days: 20)),
        'LIPID': DateTime.now().subtract(const Duration(days: 170)),
        'RFT': DateTime.now().subtract(const Duration(days: 170)),
      },
      isNewDiagnosis: false,
      hasComplications: false,
      controlStatus: 'controlled',
    );

    // SCENARIO 4: Diabetes with Complications
    return PatientContext(
      patientId: 'P12348',
      age: 65,
      gender: 'Female',
      currentVitals: {
        'fasting_blood_sugar': 165.0,
        'hba1c': 7.8,
        'systolic_bp': 150.0,
        'diastolic_bp': 95.0,
      },
      lastVisitDate: DateTime.now().subtract(const Duration(days: 120)),
      lastInvestigations: {
        'HBA1C': DateTime.now().subtract(const Duration(days: 120)),
        'RFT': DateTime.now().subtract(const Duration(days: 250)),
        'UACR': DateTime.now().subtract(const Duration(days: 400)),
        'FUNDOSCOPY': DateTime.now().subtract(const Duration(days: 450)),
      },
      chronicConditions: ['Diabetic Nephropathy', 'Hypertension'],
      isNewDiagnosis: false,
      hasComplications: true,
      controlStatus: 'borderline',
    );
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Suggestion System Demo'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: _selectedTemplate == null || _patientContext == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Patient Info Card
            _buildPatientInfoCard(),

            const SizedBox(height: 16),

            // Auto-Suggestion Panel
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AutoSuggestionPanel(
                template: _selectedTemplate!,
                context: _patientContext!,
                onNextVisitSelected: (date) {
                  setState(() {
                    _selectedNextVisit = date;
                  });
                },
                onInvestigationsSelected: (investigations) {
                  setState(() {
                    _selectedInvestigations = investigations;
                  });
                },
                onFollowUpPlanAccepted: (plan) {
                  setState(() {
                    _followUpPlan = plan;
                  });
                },
                onRefresh: () {
                  // Refresh suggestions
                  setState(() {});
                },
              ),
            ),

            const SizedBox(height: 16),

            // Applied Suggestions Summary
            if (_selectedNextVisit != null ||
                _selectedInvestigations.isNotEmpty ||
                _followUpPlan != null)
              _buildAppliedSuggestionsCard(),

            const SizedBox(height: 16),

            // Template Selector (for testing different diseases)
            _buildTemplateSelector(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Patient: ${_patientContext!.patientId}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            _buildInfoRow('Age', '${_patientContext!.age} years'),
            _buildInfoRow('Gender', _patientContext!.gender),
            _buildInfoRow('Diagnosis', _selectedTemplate!.name),
            _buildInfoRow('Status', _patientContext!.controlStatus.toUpperCase()),

            if (_patientContext!.isNewDiagnosis)
              Chip(
                label: const Text('NEW DIAGNOSIS'),
                backgroundColor: Colors.orange.shade100,
              ),

            const SizedBox(height: 12),
            const Text(
              'Current Vitals:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _patientContext!.currentVitals.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key}: ${entry.value}'),
                  backgroundColor: Colors.grey.shade200,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedSuggestionsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Applied Suggestions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (_selectedNextVisit != null) ...[
              Text(
                '✓ Next Visit: ${_formatDate(_selectedNextVisit!)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],

            if (_selectedInvestigations.isNotEmpty) ...[
              Text(
                '✓ Investigations: ${_selectedInvestigations.length} tests added',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              ...(_selectedInvestigations.map((inv) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text('• $inv', style: const TextStyle(fontSize: 12)),
              ))),
              const SizedBox(height: 8),
            ],

            if (_followUpPlan != null) ...[
              const Text(
                '✓ Follow-up plan applied',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Different Templates:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TemplateRepository.instance.getAllTemplates().map((template) {
                final isSelected = template.id == _selectedTemplate?.id;
                return ChoiceChip(
                  label: Text(template.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTemplate = template;
                        // Reset applied suggestions
                        _selectedNextVisit = null;
                        _selectedInvestigations = [];
                        _followUpPlan = null;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// =============================================================================
// STANDALONE USAGE EXAMPLE (without UI)
// =============================================================================

/// Example of using the service programmatically
class ProgrammaticUsageExample {
  static Future<void> demonstrateUsage() async {
    print('=== Auto-Suggestion System Demo ===\n');

    // 1. Get a template
    final template = TemplateRepository.instance.getTemplateById('dm_type2_v1')!;
    print('Template: ${template.name}');
    print('Category: ${template.category}\n');

    // 2. Create patient context
    final patientContext = PatientContext(
      patientId: 'P12345',
      age: 52,
      gender: 'Male',
      currentVitals: {
        'fasting_blood_sugar': 185.0,
        'hba1c': 8.5,
      },
      isNewDiagnosis: true,
      controlStatus: 'uncontrolled',
    );

    print('Patient: ${patientContext.patientId}');
    print('Age: ${patientContext.age}');
    print('New Diagnosis: ${patientContext.isNewDiagnosis}\n');

    // 3. Generate suggestions
    print('Generating suggestions...\n');
    final suggestions = await TemplateSuggestionService.instance.generateSuggestions(
      template: template,
      context: patientContext,
      isInitialVisit: true,
    );

    // 4. Display results
    print('--- NEXT VISIT ---');
    print('Date: ${suggestions.suggestedNextVisit}');
    print('Rationale: ${suggestions.nextVisitRationale}\n');

    print('--- INVESTIGATIONS (${suggestions.suggestedInvestigations.length}) ---');
    for (final inv in suggestions.suggestedInvestigations) {
      print('${inv.name}${inv.isUrgent ? " [URGENT]" : ""}${inv.isOverdue ? " [OVERDUE]" : ""}');
      print('  → ${inv.rationale}');
    }
    print('');

    if (suggestions.criticalReminders.isNotEmpty) {
      print('--- CRITICAL REMINDERS ---');
      for (final reminder in suggestions.criticalReminders) {
        print('⚠️  $reminder');
      }
      print('');
    }

    print('--- FOLLOW-UP PLAN ---');
    print(suggestions.followUpPlanText);
    print('');

    print('=== Demo Complete ===');
  }
}

// =============================================================================
// INTEGRATION EXAMPLE
// =============================================================================

/// Example showing how to integrate into existing consultation flow
class ConsultationIntegrationExample {
  static Future<void> showIntegrationPattern() async {
    print('=== Integration Pattern ===\n');

    // Typical consultation flow:

    // 1. Doctor selects disease template during consultation
    final selectedTemplate = TemplateRepository.instance
        .getTemplatesByCategory('Endocrine')
        .first;

    // 2. System gathers patient context from existing records
    final patientContext = _gatherPatientContextFromEHR('P12345');

    // 3. Generate suggestions in background (can be done while doctor is entering vitals)
    final suggestions = await TemplateSuggestionService.instance.generateSuggestions(
      template: selectedTemplate,
      context: patientContext,
      isInitialVisit: patientContext.lastVisitDate == null,
    );

    // 4. Show suggestions to doctor
    print('Suggestions ready!');
    print('Next visit: ${suggestions.suggestedNextVisit}');
    print('Tests needed: ${suggestions.suggestedInvestigations.length}');

    // 5. Doctor can:
    //    - Accept individual suggestions (next visit date, specific tests)
    //    - Accept all suggestions at once
    //    - Modify suggestions before applying
    //    - Ignore suggestions

    // 6. Apply accepted suggestions to consultation record
    _applyToConsultation(suggestions);

    print('\n✓ Suggestions integrated into consultation');
    print('✓ Time saved: 2-3 minutes per consultation');
  }

  static PatientContext _gatherPatientContextFromEHR(String patientId) {
    // In real implementation, this would query the EHR database
    return PatientContext(
      patientId: patientId,
      age: 52,
      gender: 'Male',
      currentVitals: {},
      lastVisitDate: DateTime.now().subtract(const Duration(days: 90)),
      lastInvestigations: {},
      isNewDiagnosis: false,
      controlStatus: 'controlled',
    );
  }

  static void _applyToConsultation(SuggestionResult suggestions) {
    // Apply to consultation record:
    // - Set next visit date
    // - Add investigations to orders
    // - Populate follow-up plan text field
    print('Applying suggestions to consultation...');
  }
}