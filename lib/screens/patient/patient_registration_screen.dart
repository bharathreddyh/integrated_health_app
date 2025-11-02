// lib/screens/patient/patient_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient.dart';
import '../../models/vitals.dart';
import '../../services/database_helper.dart';
import '../../services/whisper_voice_service.dart';
import '../canvas/canvas_screen.dart'; // ✅ ADD THIS IMPORT

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  // Vitals Controllers
  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Conditions
  final List<String> _availableConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Heart Disease',
    'Kidney Disease',
    'Thyroid Disorder',
    'Arthritis',
    'Allergies',
  ];
  final List<String> _selectedConditions = [];

  String? _activeVoiceField;
  bool _isExpanded = false;
  bool _isSaving = false;
  String? _returnTo; // ✅ NEW: Track where to return

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the returnTo parameter if passed from canvas dialog
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _returnTo = args?['returnTo'] as String?;
  }

  void _startVoiceDictation(String fieldName, TextEditingController controller) {
    setState(() {
      _activeVoiceField = fieldName;
    });

    final voiceService = WhisperVoiceService.instance;
    voiceService.onTranscription = (transcription) {
      if (_activeVoiceField == fieldName && mounted) {
        setState(() {
          controller.text = transcription;
          _activeVoiceField = null;
        });
      }
    };

    voiceService.startListening();
  }

  double? get _calculatedBMI {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (height != null && weight != null && height > 0) {
      final heightInMeters = height / 100;
      return weight / (heightInMeters * heightInMeters);
    }
    return null;
  }

  String get _bmiCategory {
    final bmi = _calculatedBMI;
    if (bmi == null) return '';

    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  // ✅ NEW: Create and save patient (shared logic)
  Future<Patient?> _createAndSavePatient() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      print('📵 Starting patient registration...');

      // Create Vitals object if any vitals entered
      Vitals? vitals;
      if (_bpSystolicController.text.isNotEmpty ||
          _heightController.text.isNotEmpty ||
          _weightController.text.isNotEmpty) {
        vitals = Vitals(
          bpSystolic: int.tryParse(_bpSystolicController.text),
          bpDiastolic: int.tryParse(_bpDiastolicController.text),
          pulse: int.tryParse(_pulseController.text),
          temperature: double.tryParse(_temperatureController.text),
          spo2: int.tryParse(_spo2Controller.text),
          height: double.tryParse(_heightController.text),
          weight: double.tryParse(_weightController.text),
        );
      }

      // Create Patient object
      final newPatient = Patient(
        id: 'P${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        phone: _phoneController.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        conditions: List.from(_selectedConditions),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        visits: 0,
        vitals: vitals,
      );

      // Save to database
      await DatabaseHelper.instance.createPatient(newPatient);
      print('✅ Patient saved to database successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient ${newPatient.name} registered successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return newPatient;

    } catch (e, stackTrace) {
      print('❌ Error during patient registration: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving patient: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ✅ NEW: Save and go to Consultation
  Future<void> _saveAndStartConsultation() async {
    final patient = await _createAndSavePatient();

    if (patient != null && mounted) {
      print('📵 Navigating to consultation screen...');

      // Navigate to 3-page consultation screen
      final result = await Navigator.pushNamed(
        context,
        '/medical-systems',
        arguments: {
          'patient': patient,
          'isQuickMode': false,
        },
      );

      print('📵 Returned from consultation screen');

      // Pop back to previous screen after consultation
      if (mounted) {
        Navigator.pop(context, patient);
      }
    }
  }

  // ✅ NEW: Save and go to Canvas/Annotate
  Future<void> _saveAndAnnotate() async {
    final patient = await _createAndSavePatient();

    if (patient != null && mounted) {
      if (_returnTo == 'canvas') {
        // Return to canvas dialog with patient data
        Navigator.pop(context, {
          'patient': patient,
          'action': 'annotate',
        });
      } else {
        // Navigate directly to canvas screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CanvasScreen(patient: patient),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Patient'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ✅ Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    _buildHeaderCard(),
                    const SizedBox(height: 24),

                    // Basic Information
                    _buildSectionTitle('Basic Information', Icons.person),
                    const SizedBox(height: 16),
                    _buildBasicInfoFields(),
                    const SizedBox(height: 24),

                    // Pre-existing Conditions
                    _buildSectionTitle('Pre-existing Conditions', Icons.medical_information),
                    const SizedBox(height: 12),
                    _buildConditionsSection(),
                    const SizedBox(height: 24),

                    // Quick Vitals (Optional - Expandable)
                    _buildVitalsSection(),
                    const SizedBox(height: 24),

                    // Clinical Notes
                    _buildSectionTitle('Clinical Notes', Icons.notes),
                    const SizedBox(height: 12),
                    _buildNotesField(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ✅ NEW: Bottom Action Bar with Two Save Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Save & Consultation Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAndStartConsultation,
                      icon: _isSaving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.medical_services, size: 20),
                      label: const Text(
                        'Save & Consultation',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Save & Annotate Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAndAnnotate,
                      icon: _isSaving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.draw, size: 20),
                      label: const Text(
                        'Save & Annotate',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316), // Orange
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade400,
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

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
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
            child: const Icon(Icons.person_add, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Patient Registration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Fill basic details to start',
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
        Icon(icon, color: Colors.blue.shade700, size: 24),
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

  Widget _buildBasicInfoFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Name with voice
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Patient Name *',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter patient name';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                onPressed: () => _startVoiceDictation('name', _nameController),
                icon: Icon(
                  _activeVoiceField == 'name' ? Icons.mic : Icons.mic_none,
                  color: _activeVoiceField == 'name' ? Colors.red : Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Age and Phone
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Age *',
                    prefixIcon: const Icon(Icons.cake),
                    suffixText: 'years',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 0 || age > 150) {
                      return 'Invalid age';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone *',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (value.length < 10) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select any pre-existing conditions:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableConditions.map((condition) {
              final isSelected = _selectedConditions.contains(condition);
              return FilterChip(
                label: Text(condition),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedConditions.add(condition);
                    } else {
                      _selectedConditions.remove(condition);
                    }
                  });
                },
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue.shade700,
              );
            }).toList(),
          ),
          if (_selectedConditions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No conditions selected',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVitalsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text(
              'Quick Vitals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Text(
          _isExpanded ? 'Tap to collapse' : 'Optional - Can be added later in consultation',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Blood Pressure and Pulse
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bpSystolicController,
                        decoration: InputDecoration(
                          labelText: 'BP Systolic',
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('/', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _bpDiastolicController,
                        decoration: InputDecoration(
                          labelText: 'Diastolic',
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pulse, Temp, SpO2
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pulseController,
                        decoration: InputDecoration(
                          labelText: 'Pulse',
                          suffixText: 'bpm',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _temperatureController,
                        decoration: InputDecoration(
                          labelText: 'Temp',
                          suffixText: '°F',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _spo2Controller,
                        decoration: InputDecoration(
                          labelText: 'SpO2',
                          suffixText: '%',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Height and Weight
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        decoration: InputDecoration(
                          labelText: 'Height',
                          suffixText: 'cm',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: 'Weight',
                          suffixText: 'kg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ],
                ),

                // BMI Display
                if (_calculatedBMI != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'BMI: ${_calculatedBMI!.toStringAsFixed(1)} - $_bmiCategory',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chief Complaint / Additional Notes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              IconButton(
                onPressed: () => _startVoiceDictation('notes', _notesController),
                icon: Icon(
                  _activeVoiceField == 'notes' ? Icons.mic : Icons.mic_none,
                  color: _activeVoiceField == 'notes' ? Colors.red : Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Optional: Chief complaint, reason for visit, or any additional notes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _pulseController.dispose();
    _temperatureController.dispose();
    _spo2Controller.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}