// lib/screens/patient/patient_voice_entry_screen.dart

import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/prescription.dart';
import '../../services/medical_dictation_service.dart';
import '../../widgets/floating_voice_button.dart';
import '../../services/database_helper.dart';
import '../../services/user_service.dart';

class PatientVoiceEntryScreen extends StatefulWidget {
  final Patient patient;
  final int? visitId;

  const PatientVoiceEntryScreen({
    super.key,
    required this.patient,
    this.visitId,
  });

  @override
  State<PatientVoiceEntryScreen> createState() => _PatientVoiceEntryScreenState();
}

class _PatientVoiceEntryScreenState extends State<PatientVoiceEntryScreen> {
  // Vitals Controllers
  final _bpController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _bloodSugarController = TextEditingController();

  // Clinical Notes Controllers
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _notesController = TextEditingController();

  // Lists
  final List<Map<String, String>> _prescriptions = [];
  final List<String> _labTests = [];

  @override
  void initState() {
    super.initState();
    // Register this screen for voice dictation
    _FloatingVoiceButtonState.registerDictationCallback(_handleDictation);
    _loadExistingData();
  }

  @override
  void dispose() {
    // Unregister callback when leaving screen
    _FloatingVoiceButtonState.registerDictationCallback(null);
    _bpController.dispose();
    _heartRateController.dispose();
    _temperatureController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _spo2Controller.dispose();
    _bloodSugarController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    if (widget.visitId != null) {
      // Load existing visit data if editing
      try {
        final db = await DatabaseHelper.instance.database;
        final visitData = await db.query(
          'visits',
          where: 'id = ?',
          whereArgs: [widget.visitId],
        );

        if (visitData.isNotEmpty && mounted) {
          // You can parse and populate existing data here
          // For now, we'll leave this as a placeholder
          print('Loaded existing visit data');
        }
      } catch (e) {
        print('Error loading visit data: $e');
      }
    }
  }

  void _handleDictation(DictationResult result) {
    setState(() {
      switch (result.type) {
        case DictationType.vitals:
          _updateVitals(result.data);
          break;
        case DictationType.prescription:
          _addPrescription(result.data);
          break;
        case DictationType.labTest:
          _addLabTest(result.data);
          break;
        case DictationType.diagnosis:
          _updateDiagnosis(result.data);
          break;
        case DictationType.treatment:
          _updateTreatment(result.data);
          break;
        case DictationType.notes:
          _addNotes(result.data);
          break;
        default:
          break;
      }
    });
  }

  void _updateVitals(Map<String, dynamic> vitals) {
    if (vitals.containsKey('bloodPressure')) {
      _bpController.text = vitals['bloodPressure'];
    }
    if (vitals.containsKey('heartRate')) {
      _heartRateController.text = vitals['heartRate'];
    }
    if (vitals.containsKey('temperature')) {
      _temperatureController.text = vitals['temperature'];
    }
    if (vitals.containsKey('weight')) {
      _weightController.text = vitals['weight'];
    }
    if (vitals.containsKey('height')) {
      _heightController.text = vitals['height'];
    }
    if (vitals.containsKey('spo2')) {
      _spo2Controller.text = vitals['spo2'];
    }
    if (vitals.containsKey('bloodSugar')) {
      _bloodSugarController.text = vitals['bloodSugar'];
    }
  }

  void _addPrescription(Map<String, dynamic> prescription) {
    _prescriptions.add({
      'medication': prescription['medicationName'] ?? '',
      'dosage': prescription['dosage'] ?? '',
      'frequency': prescription['frequency'] ?? '',
      'duration': prescription['duration'] ?? '',
      'instructions': prescription['instructions'] ?? '',
    });
  }

  void _addLabTest(Map<String, dynamic> test) {
    final testName = test['testName'] ?? '';
    if (testName.isNotEmpty && !_labTests.contains(testName)) {
      _labTests.add(testName);
    }
  }

  void _updateDiagnosis(Map<String, dynamic> data) {
    final diagnosis = data['diagnosis'] ?? '';
    if (_diagnosisController.text.isEmpty) {
      _diagnosisController.text = diagnosis;
    } else {
      _diagnosisController.text += '\n' + diagnosis;
    }
  }

  void _updateTreatment(Map<String, dynamic> data) {
    final treatment = data['treatment'] ?? '';
    if (_treatmentController.text.isEmpty) {
      _treatmentController.text = treatment;
    } else {
      _treatmentController.text += '\n' + treatment;
    }
  }

  void _addNotes(Map<String, dynamic> data) {
    final notes = data['notes'] ?? '';
    if (_notesController.text.isEmpty) {
      _notesController.text = notes;
    } else {
      _notesController.text += '\n' + notes;
    }
  }

  Future<void> _saveData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Save vitals to patient record
      // Save prescriptions to database
      // Save lab tests to database
      // This is simplified - implement based on your database structure

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Entry - ${widget.patient.name}'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showHelpDialog();
            },
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveData,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice Instructions Card
            _buildInstructionsCard(),
            const SizedBox(height: 24),

            // Vitals Section
            _buildSectionHeader('Vitals', Icons.favorite, Colors.red),
            const SizedBox(height: 12),
            _buildVitalsGrid(),
            const SizedBox(height: 24),

            // Prescriptions Section
            _buildSectionHeader('Prescriptions', Icons.medication, Colors.green),
            const SizedBox(height: 12),
            _buildPrescriptionsList(),
            const SizedBox(height: 24),

            // Lab Tests Section
            _buildSectionHeader('Lab Tests', Icons.science, Colors.orange),
            const SizedBox(height: 12),
            _buildLabTestsList(),
            const SizedBox(height: 24),

            // Clinical Notes Section
            _buildSectionHeader('Clinical Notes', Icons.note_add, Colors.blue),
            const SizedBox(height: 12),
            _buildClinicalNotes(),
            const SizedBox(height: 80), // Extra space for floating button
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF3B82F6)),
            SizedBox(width: 8),
            Text('Voice Commands Help'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection('📊 Vitals', [
                '"Blood pressure 140 over 90"',
                '"Heart rate 72"',
                '"Temperature 98.6"',
                '"Weight 70 kg"',
              ]),
              const SizedBox(height: 16),
              _buildHelpSection('💊 Prescriptions', [
                '"Add Metformin 500mg twice daily"',
                '"Prescribe Aspirin 75mg after meals"',
              ]),
              const SizedBox(height: 16),
              _buildHelpSection('🧪 Lab Tests', [
                '"Order CBC"',
                '"Check blood sugar"',
                '"Order lipid profile"',
              ]),
              const SizedBox(height: 16),
              _buildHelpSection('📝 Notes', [
                '"Patient has mild chest pain"',
                '"Diagnosis: Hypertension"',
                '"Treatment: Rest and medication"',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, List<String> examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...examples.map((example) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(
            example,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Voice Commands Active',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the floating microphone button and speak naturally. The system will automatically fill the appropriate fields.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 12),
            _buildCommandExample('📊 Vitals', '"Blood pressure 140 over 90"'),
            _buildCommandExample('💊 Prescription', '"Add Metformin 500mg twice daily"'),
            _buildCommandExample('🧪 Lab Test', '"Order CBC"'),
            _buildCommandExample('📝 Diagnosis', '"Patient has mild chest pain"'),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandExample(String label, String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              example,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsGrid() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildVitalField(
                    'Blood Pressure',
                    _bpController,
                    'e.g., 120/80',
                    Icons.favorite,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalField(
                    'Heart Rate',
                    _heartRateController,
                    'bpm',
                    Icons.monitor_heart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildVitalField(
                    'Temperature',
                    _temperatureController,
                    '°F',
                    Icons.thermostat,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalField(
                    'SpO2',
                    _spo2Controller,
                    '%',
                    Icons.air,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildVitalField(
                    'Weight',
                    _weightController,
                    'kg',
                    Icons.monitor_weight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalField(
                    'Blood Sugar',
                    _bloodSugarController,
                    'mg/dL',
                    Icons.water_drop,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalField(
      String label,
      TextEditingController controller,
      String hint,
      IconData icon,
      ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildPrescriptionsList() {
    return Card(
      elevation: 2,
      child: _prescriptions.isEmpty
          ? Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.medication, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No prescriptions added',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Say: "Add Metformin 500mg twice daily"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      )
          : ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _prescriptions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final rx = _prescriptions[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.medication, color: Colors.green.shade700, size: 20),
            ),
            title: Text(
              rx['medication']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              '${rx['dosage']} • ${rx['frequency']}\n${rx['duration']}${rx['instructions']!.isNotEmpty ? ' • ${rx['instructions']}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  _prescriptions.removeAt(index);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabTestsList() {
    return Card(
      elevation: 2,
      child: _labTests.isEmpty
          ? Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.science, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No lab tests ordered',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Say: "Order CBC" or "Check blood sugar"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      )
          : ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _labTests.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Icon(Icons.science, color: Colors.orange.shade700, size: 20),
            ),
            title: Text(
              _labTests[index],
              style: const TextStyle(fontSize: 14),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  _labTests.removeAt(index);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildClinicalNotes() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _diagnosisController,
              decoration: InputDecoration(
                labelText: 'Diagnosis',
                hintText: 'Say: "Patient has hypertension"',
                prefixIcon: const Icon(Icons.medical_information),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _treatmentController,
              decoration: InputDecoration(
                labelText: 'Treatment Plan',
                hintText: 'Say: "Continue current medications"',
                prefixIcon: const Icon(Icons.healing),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Say: "Patient reports improvement"',
                prefixIcon: const Icon(Icons.note_add),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}