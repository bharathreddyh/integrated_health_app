// lib/screens/consultation/page3_diagnosis_treatment.dart
// ✅ COMPLETE VERSION WITH AUTO-SAVE FOR LAB TESTS & INVESTIGATIONS

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/consultation_data.dart';
import '../../models/prescription.dart';
import '../../services/database_helper.dart';
import '../../widgets/prescription_dialog.dart';
import '../../models/disease_template.dart';

// Investigation model
class Investigation {
  final String name;
  final String category;
  String? notes;
  bool isUrgent;

  Investigation({
    required this.name,
    required this.category,
    this.notes,
    this.isUrgent = false,
  });
}

// Lab Test model
class LabTestOrder {
  final String name;
  final String category;
  String? notes;
  bool isUrgent;

  LabTestOrder({
    required this.name,
    required this.category,
    this.notes,
    this.isUrgent = false,
  });
}

class Page3DiagnosisTreatment extends StatefulWidget {
  const Page3DiagnosisTreatment({super.key});

  @override
  State<Page3DiagnosisTreatment> createState() => _Page3DiagnosisTreatmentState();
}

class _Page3DiagnosisTreatmentState extends State<Page3DiagnosisTreatment> {
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _dietPlanController = TextEditingController();
  final TextEditingController _lifestylePlanController = TextEditingController();
  final TextEditingController _followUpController = TextEditingController();

  final FocusNode _diagnosisFocusNode = FocusNode();
  final FocusNode _dietPlanFocusNode = FocusNode();
  final FocusNode _lifestylePlanFocusNode = FocusNode();
  final FocusNode _followUpFocusNode = FocusNode();

  bool _includeMedication = false;
  bool _includeDiet = false;
  bool _includeLifestyle = false;
  bool _includeLabTests = false;
  bool _includeInvestigations = false;

  // Lists to hold ordered tests and investigations
  List<LabTestOrder> _orderedLabTests = [];
  List<Investigation> _orderedInvestigations = [];

  Timer? _autoSaveTimer;
  bool _isSaving = false;

  // Available Lab Tests by Category
  static const Map<String, List<String>> _labTestsByCategory = {
    'Hematology': [
      'Complete Blood Count (CBC)',
      'Hemoglobin',
      'Platelet Count',
      'ESR',
      'Peripheral Smear',
      'Bleeding Time',
      'Clotting Time',
    ],
    'Biochemistry': [
      'Blood Glucose (Fasting)',
      'Blood Glucose (PP)',
      'HbA1c',
      'Lipid Profile',
      'Liver Function Test (LFT)',
      'Kidney Function Test (KFT)',
      'Serum Electrolytes',
      'Serum Calcium',
      'Serum Uric Acid',
    ],
    'Endocrine': [
      'Thyroid Profile (T3, T4, TSH)',
      'TSH',
      'Vitamin D',
      'Vitamin B12',
      'Cortisol',
      'Testosterone',
    ],
    'Cardiac': [
      'Troponin I',
      'CPK-MB',
      'BNP',
      'D-Dimer',
      'Lipid Profile',
    ],
    'Infectious Disease': [
      'HIV',
      'Hepatitis B Surface Antigen',
      'Hepatitis C Antibody',
      'VDRL',
      'Widal Test',
      'Dengue NS1 Antigen',
      'Malaria Antigen',
    ],
    'Urine Tests': [
      'Urine Routine',
      'Urine Culture',
      'Urine Pregnancy Test',
      'Microalbuminuria',
    ],
    'Stool Tests': [
      'Stool Routine',
      'Stool Culture',
      'Occult Blood',
    ],
  };

  // Available Investigations by Category
  static const Map<String, List<String>> _investigationsByCategory = {
    'Radiology': [
      'X-Ray Chest PA View',
      'X-Ray Chest AP View',
      'X-Ray Abdomen',
      'X-Ray Spine',
      'X-Ray Pelvis',
      'X-Ray Long Bones',
      'X-Ray Joints',
      'X-Ray Skull',
    ],
    'CT Scan': [
      'CT Brain Plain',
      'CT Brain Contrast',
      'CT Chest',
      'CT Abdomen',
      'CT Spine',
      'CT Angiography',
      'HRCT Chest',
    ],
    'MRI': [
      'MRI Brain',
      'MRI Spine',
      'MRI Joints',
      'MRI Abdomen',
      'MR Angiography',
      'MR Cholangiopancreatography (MRCP)',
    ],
    'Ultrasound': [
      'USG Abdomen',
      'USG Pelvis',
      'USG Abdomen & Pelvis',
      'USG KUB',
      'USG Obstetric',
      'Doppler Study',
      'ECHO (Echocardiography)',
      'USG Guided Biopsy',
    ],
    'Endoscopy': [
      'Upper GI Endoscopy',
      'Colonoscopy',
      'Sigmoidoscopy',
      'Bronchoscopy',
      'Cystoscopy',
    ],
    'Cardiac': [
      'ECG',
      'ECHO',
      '2D ECHO',
      'Stress Test (TMT)',
      'Holter Monitoring',
      'Angiography',
    ],
    'Other': [
      'PFT (Pulmonary Function Test)',
      'Audiometry',
      'Biopsy',
      'FNAC',
      'Bone Marrow Aspiration',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadExistingData();

    _diagnosisController.addListener(_onTextChanged);
    _dietPlanController.addListener(_onTextChanged);
    _lifestylePlanController.addListener(_onTextChanged);
    _followUpController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  // Reset page functionality
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
          'This will clear:\n'
              '• Diagnosis\n'
              '• All lab test orders\n'
              '• All investigation orders\n'
              '• All medications\n'
              '• Diet plan\n'
              '• Lifestyle modifications\n'
              '• Follow-up instructions\n\n'
              'Patient data and clinical history will be kept.',
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

      // Clear all controllers
      _diagnosisController.clear();
      _dietPlanController.clear();
      _lifestylePlanController.clear();
      _followUpController.clear();

      // Clear data model
      data.updateDiagnosis('');
      data.updateDietPlan('');
      data.updateLifestylePlan('');
      data.prescriptions.clear();
      data.updateOrderedLabTests([]);
      data.updateOrderedInvestigations([]);

      // Clear local lists
      _orderedLabTests.clear();
      _orderedInvestigations.clear();

      // Reset toggles
      setState(() {
        _includeMedication = false;
        _includeDiet = false;
        _includeLifestyle = false;
        _includeLabTests = false;
        _includeInvestigations = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Page reset successfully'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ✅ UPDATED: Auto-save with lab tests and investigations
  Future<void> _autoSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final data = Provider.of<ConsultationData>(context, listen: false);

      // Save text fields
      data.updateDiagnosis(_diagnosisController.text);
      if (_includeDiet) data.updateDietPlan(_dietPlanController.text);
      if (_includeLifestyle) data.updateLifestylePlan(_lifestylePlanController.text);

      // ✅ Save lab tests
      data.updateOrderedLabTests(
          _orderedLabTests.map((test) => {
            'name': test.name,
            'category': test.category,
            'notes': test.notes,
            'isUrgent': test.isUrgent,
          }).toList()
      );

      // ✅ Save investigations
      data.updateOrderedInvestigations(
          _orderedInvestigations.map((inv) => {
            'name': inv.name,
            'category': inv.category,
            'notes': inv.notes,
            'isUrgent': inv.isUrgent,
          }).toList()
      );

      await DatabaseHelper.instance.saveDraftConsultation(
        data.patient.id,
        data.toDraftJson(),
      );
      data.markAsSaved();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Draft saved'),
              ],
            ),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
          ),
        );
      }
    } catch (e) {
      print('Auto-save error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ✅ UPDATED: Load existing data including lab tests and investigations
  void _loadExistingData() {
    final consultationData = Provider.of<ConsultationData>(context, listen: false);
    _diagnosisController.text = consultationData.diagnosis;
    _dietPlanController.text = consultationData.dietPlan;
    _lifestylePlanController.text = consultationData.lifestylePlan;

    _includeMedication = consultationData.prescriptions.isNotEmpty;
    _includeDiet = consultationData.dietPlan.isNotEmpty;
    _includeLifestyle = consultationData.lifestylePlan.isNotEmpty;

    // ✅ Load lab tests
    if (consultationData.orderedLabTests.isNotEmpty) {
      _orderedLabTests = consultationData.orderedLabTests.map((testMap) =>
          LabTestOrder(
            name: testMap['name'] as String,
            category: testMap['category'] as String,
            notes: testMap['notes'] as String?,
            isUrgent: testMap['isUrgent'] as bool? ?? false,
          )
      ).toList();
      _includeLabTests = true;
    }

    // ✅ Load investigations
    if (consultationData.orderedInvestigations.isNotEmpty) {
      _orderedInvestigations = consultationData.orderedInvestigations.map((invMap) =>
          Investigation(
            name: invMap['name'] as String,
            category: invMap['category'] as String,
            notes: invMap['notes'] as String?,
            isUrgent: invMap['isUrgent'] as bool? ?? false,
          )
      ).toList();
      _includeInvestigations = true;
    }
  }

  void _saveData() {
    final consultationData = Provider.of<ConsultationData>(context, listen: false);
    consultationData.updateDiagnosis(_diagnosisController.text);

    if (_includeDiet) {
      consultationData.updateDietPlan(_dietPlanController.text);
    } else {
      consultationData.updateDietPlan('');
    }

    if (_includeLifestyle) {
      consultationData.updateLifestylePlan(_lifestylePlanController.text);
    } else {
      consultationData.updateLifestylePlan('');
    }
  }

  // ✅ UPDATED: Show multi-select dialog for lab tests with auto-save trigger
  Future<void> _showLabTestsMultiSelect() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _MultiSelectDialog(
        title: 'Select Lab Tests',
        categories: _labTestsByCategory,
        icon: Icons.science,
        color: Colors.purple,
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (var testName in selected) {
          String category = '';
          _labTestsByCategory.forEach((cat, tests) {
            if (tests.contains(testName)) {
              category = cat;
            }
          });

          if (!_orderedLabTests.any((t) => t.name == testName)) {
            _orderedLabTests.add(LabTestOrder(
              name: testName,
              category: category,
            ));
          }
        }
        _includeLabTests = _orderedLabTests.isNotEmpty;
      });

      // ✅ Trigger auto-save
      _autoSave();
    }
  }

  // ✅ UPDATED: Show multi-select dialog for investigations with auto-save trigger
  Future<void> _showInvestigationsMultiSelect() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _MultiSelectDialog(
        title: 'Select Investigations',
        categories: _investigationsByCategory,
        icon: Icons.medical_services,
        color: Colors.blue,
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (var invName in selected) {
          String category = '';
          _investigationsByCategory.forEach((cat, invs) {
            if (invs.contains(invName)) {
              category = cat;
            }
          });

          if (!_orderedInvestigations.any((i) => i.name == invName)) {
            _orderedInvestigations.add(Investigation(
              name: invName,
              category: category,
            ));
          }
        }
        _includeInvestigations = _orderedInvestigations.isNotEmpty;
      });

      // ✅ Trigger auto-save
      _autoSave();
    }
  }

  Future<void> _addPrescription() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    final consultationData = Provider.of<ConsultationData>(context, listen: false);

    final result = await showDialog<Prescription>(
      context: context,
      builder: (context) => const PrescriptionDialog(),
    );

    if (result != null) {
      consultationData.addPrescription(result);
      setState(() {
        _includeMedication = true;
      });
      _autoSave(); // ✅ Trigger auto-save
    }
  }

  void _editPrescription(int index) async {
    final consultationData = Provider.of<ConsultationData>(context, listen: false);
    final prescription = consultationData.prescriptions[index];

    final result = await showDialog<Prescription>(
      context: context,
      builder: (context) => PrescriptionDialog(prescription: prescription),
    );

    if (result != null) {
      setState(() {
        consultationData.prescriptions[index] = result;
      });
      _autoSave(); // ✅ Trigger auto-save
    }
  }

  void _deletePrescription(int index) {
    final consultationData = Provider.of<ConsultationData>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription'),
        content: const Text('Are you sure you want to delete this prescription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              consultationData.removePrescription(index);
              Navigator.pop(context);
              setState(() {
                if (consultationData.prescriptions.isEmpty) {
                  _includeMedication = false;
                }
              });
              _autoSave(); // ✅ Trigger auto-save
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationData>(
      builder: (context, consultationData, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Auto-save indicator
                if (_isSaving || consultationData.hasUnsavedChanges)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _isSaving ? Colors.blue.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isSaving ? Colors.blue.shade200 : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_isSaving)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(Icons.cloud_upload, size: 16, color: Colors.orange.shade700),
                        SizedBox(width: 8),
                        Text(
                          _isSaving ? 'Saving...' : 'Unsaved changes',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isSaving ? Colors.blue.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (consultationData.lastSaved != null) ...[
                          Spacer(),
                          Text(
                            'Last saved: ${_formatTime(consultationData.lastSaved!)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),

                // Reset button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _resetPage,
                      icon: Icon(Icons.restart_alt, size: 18),
                      label: Text('Reset Page'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: BorderSide(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Header
                _buildHeader(),
                const SizedBox(height: 24),

                // Diagnosis Section
                _buildDiagnosisSection(),
                const SizedBox(height: 32),

                // Treatment Plan Title
                _buildSectionTitle('Treatment Plan', Icons.medical_services),
                const SizedBox(height: 16),

                // Lab Tests Card
                _buildTreatmentOptionCard(
                  title: 'Lab Tests',
                  icon: Icons.science,
                  color: Colors.purple,
                  isSelected: _includeLabTests,
                  onToggle: (value) {
                    setState(() {
                      _includeLabTests = value;
                      if (!value) {
                        _orderedLabTests.clear();
                      }
                    });
                    _autoSave(); // ✅ Trigger auto-save
                  },
                  content: _includeLabTests ? _buildLabTestsSection() : null,
                ),
                const SizedBox(height: 16),

                // Investigations Card
                _buildTreatmentOptionCard(
                  title: 'Investigations',
                  icon: Icons.medical_information,
                  color: Colors.blue,
                  isSelected: _includeInvestigations,
                  onToggle: (value) {
                    setState(() {
                      _includeInvestigations = value;
                      if (!value) {
                        _orderedInvestigations.clear();
                      }
                    });
                    _autoSave(); // ✅ Trigger auto-save
                  },
                  content: _includeInvestigations ? _buildInvestigationsSection() : null,
                ),
                const SizedBox(height: 16),

                // Medications Card
                _buildTreatmentOptionCard(
                  title: 'Medications',
                  icon: Icons.medication,
                  color: Colors.teal,
                  isSelected: _includeMedication,
                  onToggle: (value) {
                    setState(() {
                      _includeMedication = value;
                      if (!value) {
                        consultationData.prescriptions.clear();
                      }
                    });
                    _autoSave(); // ✅ Trigger auto-save
                  },
                  content: _includeMedication ? _buildMedicationSection() : null,
                ),
                const SizedBox(height: 16),

                // Diet Plan Card
                _buildTreatmentOptionCard(
                  title: 'Diet Plan',
                  icon: Icons.restaurant,
                  color: Colors.orange,
                  isSelected: _includeDiet,
                  onToggle: (value) {
                    setState(() {
                      _includeDiet = value;
                      if (!value) {
                        _dietPlanController.clear();
                        consultationData.updateDietPlan('');
                      }
                    });
                    _autoSave(); // ✅ Trigger auto-save
                  },
                  content: _includeDiet ? _buildDietSection() : null,
                ),
                const SizedBox(height: 16),

                // Lifestyle Card
                _buildTreatmentOptionCard(
                  title: 'Lifestyle Modifications',
                  icon: Icons.directions_run,
                  color: Colors.green,
                  isSelected: _includeLifestyle,
                  onToggle: (value) {
                    setState(() {
                      _includeLifestyle = value;
                      if (!value) {
                        _lifestylePlanController.clear();
                        consultationData.updateLifestylePlan('');
                      }
                    });
                    _autoSave(); // ✅ Trigger auto-save
                  },
                  content: _includeLifestyle ? _buildLifestyleSection() : null,
                ),
                const SizedBox(height: 32),

                // Follow-up Section
                _buildFollowUpSection(),
                const SizedBox(height: 24),

                // Summary Card
                _buildSummaryCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnosis & Treatment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Finalize consultation details',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosisSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text(
                'Diagnosis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _diagnosisController,
            focusNode: _diagnosisFocusNode,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter primary and secondary diagnoses...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) => _saveData(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabTestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selected Lab Tests
        if (_orderedLabTests.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.science_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No lab tests ordered',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          ..._orderedLabTests.asMap().entries.map((entry) {
            final index = entry.key;
            final test = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  child: Icon(Icons.science, color: Colors.purple.shade700, size: 20),
                ),
                title: Text(
                  test.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Row(
                  children: [
                    Text(
                      test.category,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (test.isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        test.isUrgent ? Icons.flag : Icons.flag_outlined,
                        color: test.isUrgent ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _orderedLabTests[index].isUrgent = !test.isUrgent;
                        });
                        _autoSave(); // ✅ Trigger auto-save
                      },
                      tooltip: 'Mark as urgent',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _orderedLabTests.removeAt(index);
                          if (_orderedLabTests.isEmpty) {
                            _includeLabTests = false;
                          }
                        });
                        _autoSave(); // ✅ Trigger auto-save
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

        const SizedBox(height: 12),

        // Add Lab Tests Button
        ElevatedButton.icon(
          onPressed: _showLabTestsMultiSelect,
          icon: const Icon(Icons.add),
          label: Text(_orderedLabTests.isEmpty ? 'Add Lab Tests' : 'Add More Tests'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestigationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selected Investigations
        if (_orderedInvestigations.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.medical_information_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No investigations ordered',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          ..._orderedInvestigations.asMap().entries.map((entry) {
            final index = entry.key;
            final investigation = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.medical_information, color: Colors.blue.shade700, size: 20),
                ),
                title: Text(
                  investigation.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Row(
                  children: [
                    Text(
                      investigation.category,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (investigation.isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        investigation.isUrgent ? Icons.flag : Icons.flag_outlined,
                        color: investigation.isUrgent ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _orderedInvestigations[index].isUrgent = !investigation.isUrgent;
                        });
                        _autoSave(); // ✅ Trigger auto-save
                      },
                      tooltip: 'Mark as urgent',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _orderedInvestigations.removeAt(index);
                          if (_orderedInvestigations.isEmpty) {
                            _includeInvestigations = false;
                          }
                        });
                        _autoSave(); // ✅ Trigger auto-save
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

        const SizedBox(height: 12),

        // Add Investigations Button
        ElevatedButton.icon(
          onPressed: _showInvestigationsMultiSelect,
          icon: const Icon(Icons.add),
          label: Text(_orderedInvestigations.isEmpty
              ? 'Add Investigations'
              : 'Add More Investigations'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentOptionCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required Function(bool) onToggle,
    Widget? content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => onToggle(!isSelected),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : null,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Switch(
                    value: isSelected,
                    onChanged: onToggle,
                    activeColor: color,
                  ),
                ],
              ),
            ),
          ),
          if (isSelected && content != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationSection() {
    final consultationData = Provider.of<ConsultationData>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (consultationData.prescriptions.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.medication_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No medications added',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          ...consultationData.prescriptions.asMap().entries.map((entry) {
            final index = entry.key;
            final prescription = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.medication, color: Colors.white, size: 20),
                ),
                title: Text(
                  prescription.medicationName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${prescription.dosage} • ${prescription.frequency} • ${prescription.duration}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editPrescription(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deletePrescription(index),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _addPrescription,
          icon: const Icon(Icons.add),
          label: const Text('Add Medication'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDietSection() {
    return TextField(
      controller: _dietPlanController,
      focusNode: _dietPlanFocusNode,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'e.g., Low sodium diet, avoid processed foods, increase water intake...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.orange.shade50,
      ),
      onChanged: (value) => _saveData(),
    );
  }

  Widget _buildLifestyleSection() {
    return TextField(
      controller: _lifestylePlanController,
      focusNode: _lifestylePlanFocusNode,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'e.g., 30 min walking daily, quit smoking, stress management...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.green.shade50,
      ),
      onChanged: (value) => _saveData(),
    );
  }

  Widget _buildFollowUpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text(
                'Follow-up Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _followUpController,
            focusNode: _followUpFocusNode,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g., Follow up in 2 weeks, repeat labs after 1 month...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.green.shade50,
            ),
            onChanged: (value) => _saveData(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final consultationData = Provider.of<ConsultationData>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.summarize, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Consultation Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Page 1 Data
          _buildSummaryRow(
            'Chief Complaint',
            consultationData.chiefComplaint.isNotEmpty ? '✓ Entered' : '⚠️ Missing',
            consultationData.chiefComplaint.isNotEmpty,
          ),
          _buildSummaryRow(
            'Vitals',
            consultationData.vitals.isNotEmpty ? '✓ Recorded' : 'Not recorded',
            consultationData.vitals.isNotEmpty,
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Page 2 Content Section
          Text(
            'Selected Content from Page 2',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade900,
            ),
          ),
          const SizedBox(height: 8),

          _buildPage2ContentSummary(consultationData),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Page 3 Data
          _buildSummaryRow(
            'Diagnosis',
            _diagnosisController.text.isNotEmpty ? '✓ Entered' : '⚠️ Missing',
            _diagnosisController.text.isNotEmpty,
          ),
          _buildSummaryRow(
            'Lab Tests',
            _orderedLabTests.isEmpty ? 'None' : '${_orderedLabTests.length} ordered',
            _orderedLabTests.isNotEmpty,
          ),
          _buildSummaryRow(
            'Investigations',
            _orderedInvestigations.isEmpty ? 'None' : '${_orderedInvestigations.length} ordered',
            _orderedInvestigations.isNotEmpty,
          ),
          _buildSummaryRow(
            'Medications',
            consultationData.prescriptions.isEmpty
                ? 'None'
                : '${consultationData.prescriptions.length} added',
            consultationData.prescriptions.isNotEmpty,
          ),
          _buildSummaryRow(
            'Diet Plan',
            _includeDiet ? '✓ Included' : 'Not included',
            _includeDiet,
          ),
          _buildSummaryRow(
            'Lifestyle Plan',
            _includeLifestyle ? '✓ Included' : 'Not included',
            _includeLifestyle,
          ),
        ],
      ),
    );
  }

  Widget _buildPage2ContentSummary(ConsultationData data) {
    final diagramCount = data.selectedDiagramIds.length;
    final templateCount = data.selectedTemplateIds.length;
    final anatomyCount = data.selectedAnatomies.length;
    final totalSelected = diagramCount + templateCount + anatomyCount;

    if (totalSelected == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No visual content selected. PDF will not include diagrams.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Saved Kidney Diagrams
        if (diagramCount > 0)
          _buildContentTypeRow(
            Icons.photo_library,
            '$diagramCount Kidney Diagram${diagramCount == 1 ? '' : 's'}',
            Colors.blue,
          ),

        // Disease Templates
        if (templateCount > 0) ...[
          if (diagramCount > 0) const SizedBox(height: 6),
          _buildContentTypeRow(
            Icons.medical_information,
            '$templateCount Disease Template${templateCount == 1 ? '' : 's'}',
            Colors.purple,
          ),
          // Show template names
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.selectedTemplateIds.map((id) {
                // TODO: Implement DiseaseTemplates.getById
                final template = null; // DiseaseTemplates.getById(id);
                if (template == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Anatomy Diagrams
        if (anatomyCount > 0) ...[
          const SizedBox(height: 6),
          _buildContentTypeRow(
            Icons.category,
            '$anatomyCount Anatomy View${anatomyCount == 1 ? '' : 's'}',
            Colors.teal,
          ),
          // Show anatomy names
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.selectedAnatomies.map((anatomy) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${anatomy.systemName} - ${anatomy.viewType}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Total count badge
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
              const SizedBox(width: 6),
              Text(
                '$totalSelected item${totalSelected == 1 ? '' : 's'} will appear in PDF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentTypeRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: isComplete ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _diagnosisController.dispose();
    _dietPlanController.dispose();
    _lifestylePlanController.dispose();
    _followUpController.dispose();
    _diagnosisFocusNode.dispose();
    _dietPlanFocusNode.dispose();
    _lifestylePlanFocusNode.dispose();
    _followUpFocusNode.dispose();
    super.dispose();
  }
}

// Multi-Select Dialog Widget
class _MultiSelectDialog extends StatefulWidget {
  final String title;
  final Map<String, List<String>> categories;
  final IconData icon;
  final Color color;

  const _MultiSelectDialog({
    required this.title,
    required this.categories,
    required this.icon,
    required this.color,
  });

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  final Set<String> _selectedItems = {};
  String? _expandedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<String>>> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return widget.categories.entries.toList();
    }

    final filtered = <String, List<String>>{};
    widget.categories.forEach((category, items) {
      final matchingItems = items
          .where((item) => item.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
      if (matchingItems.isNotEmpty) {
        filtered[category] = matchingItems;
      }
    });
    return filtered.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _filteredCategories;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: widget.color.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_selectedItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_selectedItems.length} selected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Categories List
            Expanded(
              child: filteredCategories.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final entry = filteredCategories[index];
                  final category = entry.key;
                  final items = entry.value;
                  final isExpanded = _expandedCategory == category;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(widget.icon, color: widget.color),
                          title: Text(
                            category,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${items.length} items'),
                          trailing: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                          ),
                          onTap: () {
                            setState(() {
                              _expandedCategory = isExpanded ? null : category;
                            });
                          },
                        ),
                        if (isExpanded)
                          Column(
                            children: items.map((item) {
                              final isSelected = _selectedItems.contains(item);
                              return CheckboxListTile(
                                dense: true,
                                title: Text(
                                  item,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                value: isSelected,
                                activeColor: widget.color,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedItems.add(item);
                                    } else {
                                      _selectedItems.remove(item);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedItems.clear();
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _selectedItems.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selectedItems.toList()),
                    icon: const Icon(Icons.check),
                    label: Text('Add ${_selectedItems.length}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
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
}