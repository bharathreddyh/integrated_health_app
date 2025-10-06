import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/vitals.dart';
import '../../services/database_helper.dart';
import '../kidney/kidney_screen.dart';

class PatientDataEditScreen extends StatefulWidget {
  final Patient patient;

  const PatientDataEditScreen({super.key, required this.patient});

  @override
  State<PatientDataEditScreen> createState() => _PatientDataEditScreenState();
}

class _PatientDataEditScreenState extends State<PatientDataEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  late TextEditingController _bpSystolicController;
  late TextEditingController _bpDiastolicController;
  late TextEditingController _pulseController;
  late TextEditingController _temperatureController;
  late TextEditingController _spo2Controller;
  late TextEditingController _respiratoryRateController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _fbsController;
  late TextEditingController _ppbsController;
  late TextEditingController _hba1cController;

  late Set<String> _selectedConditions;
  bool _isSaving = false;

  final List<String> _commonConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Arthritis',
    'GERD',
    'Migraine',
    'Depression',
    'Anxiety',
    'Thyroid Disorder',
    'Heart Disease',
    'Kidney Disease',
    'Chronic Pain',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.name);
    _ageController = TextEditingController(text: widget.patient.age.toString());
    _phoneController = TextEditingController(text: widget.patient.phone);
    _notesController = TextEditingController(text: widget.patient.notes ?? '');

    _bpSystolicController = TextEditingController(
        text: widget.patient.vitals?.bpSystolic?.toString() ?? '');
    _bpDiastolicController = TextEditingController(
        text: widget.patient.vitals?.bpDiastolic?.toString() ?? '');
    _pulseController = TextEditingController(
        text: widget.patient.vitals?.pulse?.toString() ?? '');
    _temperatureController = TextEditingController(
        text: widget.patient.vitals?.temperature?.toString() ?? '');
    _spo2Controller = TextEditingController(
        text: widget.patient.vitals?.spo2?.toString() ?? '');
    _respiratoryRateController = TextEditingController(
        text: widget.patient.vitals?.respiratoryRate?.toString() ?? '');
    _heightController = TextEditingController(
        text: widget.patient.vitals?.height?.toString() ?? '');
    _weightController = TextEditingController(
        text: widget.patient.vitals?.weight?.toString() ?? '');
    _fbsController = TextEditingController(
        text: widget.patient.vitals?.fbs?.toString() ?? '');
    _ppbsController = TextEditingController(
        text: widget.patient.vitals?.ppbs?.toString() ?? '');
    _hba1cController = TextEditingController(
        text: widget.patient.vitals?.hba1c?.toString() ?? '');

    _selectedConditions = Set<String>.from(widget.patient.conditions);
  }

  String get _calculatedBMI {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    if (height != null && weight != null && height > 0) {
      final heightInMeters = height / 100;
      final bmi = weight / (heightInMeters * heightInMeters);
      return bmi.toStringAsFixed(1);
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Review Patient Data'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection(
                    title: 'Patient Information',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Patient Name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Age',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.badge, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Patient ID: ${widget.patient.id}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const Spacer(),
                              Text(
                                'Registered: ${widget.patient.date}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Vitals & Measurements',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _bpSystolicController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'BP Systolic',
                                        suffixText: 'mmHg',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('/', style: TextStyle(fontSize: 24)),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _bpDiastolicController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Diastolic',
                                        suffixText: 'mmHg',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _pulseController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Pulse Rate',
                                  suffixText: 'bpm',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _temperatureController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Temperature',
                                  suffixText: '°F',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _spo2Controller,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'SpO2',
                                  suffixText: '%',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _respiratoryRateController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Respiratory Rate',
                                  suffixText: '/min',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _heightController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: 'Height',
                                  suffixText: 'cm',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: 'Weight',
                                  suffixText: 'kg',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BMI',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _calculatedBMI,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E40AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Blood Sugar Levels',
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fbsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'FBS (Fasting)',
                              suffixText: 'mg/dL',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _ppbsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'PPBS (Post-Prandial)',
                              suffixText: 'mg/dL',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _hba1cController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'HbA1c',
                              suffixText: '%',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Preexisting Conditions',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonConditions.map((condition) {
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
                          selectedColor: const Color(0xFFDCEAFE),
                          checkmarkColor: const Color(0xFF1E40AF),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Clinical Notes',
                    child: TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Clinical history, allergies, previous treatments...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 4,
                  offset: Offset(-2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.blue,
                        child: Text(
                          widget.patient.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.patient.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'ID: ${widget.patient.id}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Review and update patient data before consultation',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveAndContinue,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Save & Continue to Consultation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, Age, Phone required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final hasVitals = _bpSystolicController.text.isNotEmpty ||
          _bpDiastolicController.text.isNotEmpty ||
          _pulseController.text.isNotEmpty ||
          _temperatureController.text.isNotEmpty ||
          _spo2Controller.text.isNotEmpty ||
          _respiratoryRateController.text.isNotEmpty ||
          _heightController.text.isNotEmpty ||
          _weightController.text.isNotEmpty ||
          _fbsController.text.isNotEmpty ||
          _ppbsController.text.isNotEmpty ||
          _hba1cController.text.isNotEmpty;

      final vitals = hasVitals
          ? Vitals(
        bpSystolic: int.tryParse(_bpSystolicController.text),
        bpDiastolic: int.tryParse(_bpDiastolicController.text),
        pulse: int.tryParse(_pulseController.text),
        temperature: double.tryParse(_temperatureController.text),
        spo2: int.tryParse(_spo2Controller.text),
        respiratoryRate: int.tryParse(_respiratoryRateController.text),
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        fbs: int.tryParse(_fbsController.text),
        ppbs: int.tryParse(_ppbsController.text),
        hba1c: double.tryParse(_hba1cController.text),
      )
          : null;

      final updatedPatient = widget.patient.copyWith(
        name: _nameController.text,
        age: int.parse(_ageController.text),
        phone: _phoneController.text,
        conditions: _selectedConditions.toList(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        vitals: vitals,
      );

      await DatabaseHelper.instance.updatePatient(updatedPatient);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient data saved'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => KidneyScreen(patient: updatedPatient),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
    _respiratoryRateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _fbsController.dispose();
    _ppbsController.dispose();
    _hba1cController.dispose();
    super.dispose();
  }
}