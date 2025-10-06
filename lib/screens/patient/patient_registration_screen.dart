import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../services/database_helper.dart';
import '../../models/vitals.dart';

class PatientStore {
  static final _db = DatabaseHelper.instance;

  static Future<List<Patient>> getPatients() async {
    return await _db.getAllPatients();
  }

  static Future<void> addPatient(Patient patient) async {
    await _db.createPatient(patient);
  }

  static Future<void> updatePatient(Patient patient) async {
    await _db.updatePatient(patient);
  }

  static Future<void> deletePatient(String id) async {
    await _db.deletePatient(id);
  }

  static Future<List<Patient>> searchPatients(String query) async {
    return await _db.searchPatients(query);
  }
}

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _clinicalHistoryController = TextEditingController();

  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _fbsController = TextEditingController();
  final _ppbsController = TextEditingController();
  final _hba1cController = TextEditingController();

  final Set<String> _selectedConditions = {};
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Register New Patient'),
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
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Patient Name *',
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
                                labelText: 'Age *',
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
                                labelText: 'Phone *',
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
                                        'BMI (Calculated)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
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
                      title: 'Clinical History',
                      child: TextField(
                        controller: _clinicalHistoryController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Chief complaint, symptoms, medical history, allergies...',
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
                      color: Colors.green.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.green.shade200),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 48,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'New Patient Registration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryItem('Required Fields', '3', Icons.star, Colors.red),
                          _buildSummaryItem('Vitals Entered', '${_countFilledVitals()}', Icons.favorite, Colors.blue),
                          _buildSummaryItem('Conditions', '${_selectedConditions.length}', Icons.medical_services, Colors.orange),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Quick Tips',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildTip('All vitals are optional'),
                                _buildTip('BMI auto-calculates'),
                                _buildTip('Only name, age & phone required'),
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
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _isSaving ? null : _savePatient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Text(
                            'Register Patient',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
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
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  int _countFilledVitals() {
    int count = 0;
    if (_bpSystolicController.text.isNotEmpty) count++;
    if (_pulseController.text.isNotEmpty) count++;
    if (_temperatureController.text.isNotEmpty) count++;
    if (_spo2Controller.text.isNotEmpty) count++;
    if (_heightController.text.isNotEmpty) count++;
    if (_weightController.text.isNotEmpty) count++;
    return count;
  }

  Future<void> _savePatient() async {
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields (Name, Age, Phone)')),
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

      final vitals = hasVitals ? Vitals(
        bpSystolic: _bpSystolicController.text.isEmpty ? null : int.tryParse(_bpSystolicController.text),
        bpDiastolic: _bpDiastolicController.text.isEmpty ? null : int.tryParse(_bpDiastolicController.text),
        pulse: _pulseController.text.isEmpty ? null : int.tryParse(_pulseController.text),
        temperature: _temperatureController.text.isEmpty ? null : double.tryParse(_temperatureController.text),
        spo2: _spo2Controller.text.isEmpty ? null : int.tryParse(_spo2Controller.text),
        respiratoryRate: _respiratoryRateController.text.isEmpty ? null : int.tryParse(_respiratoryRateController.text),
        height: _heightController.text.isEmpty ? null : double.tryParse(_heightController.text),
        weight: _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
        fbs: _fbsController.text.isEmpty ? null : int.tryParse(_fbsController.text),
        ppbs: _ppbsController.text.isEmpty ? null : int.tryParse(_ppbsController.text),
        hba1c: _hba1cController.text.isEmpty ? null : double.tryParse(_hba1cController.text),
      ) : null;

      final newPatient = Patient(
        id: 'P${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        age: int.parse(_ageController.text),
        phone: _phoneController.text,
        date: DateTime.now().toString().split(' ')[0],
        conditions: _selectedConditions.toList(),
        notes: _clinicalHistoryController.text.isEmpty ? null : _clinicalHistoryController.text,
        vitals: vitals,
      );

      await PatientStore.addPatient(newPatient);

      if (mounted) {
        final saved = await DatabaseHelper.instance.getPatient(newPatient.id);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Patient Saved'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${saved?.name}'),
                  const SizedBox(height: 8),
                  Text(
                    'Vitals saved: ${saved?.vitals != null ? "YES" : "NO"}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: saved?.vitals != null ? Colors.green : Colors.red,
                    ),
                  ),
                  if (saved?.vitals != null) ...[
                    const Divider(height: 24),
                    Text('BP: ${saved!.vitals!.bpSystolic ?? "--"}/${saved.vitals!.bpDiastolic ?? "--"}'),
                    Text('Pulse: ${saved.vitals!.pulse ?? "--"}'),
                    Text('Temp: ${saved.vitals!.temperature ?? "--"}'),
                    Text('SpO2: ${saved.vitals!.spo2 ?? "--"}'),
                    Text('Height: ${saved.vitals!.height ?? "--"}'),
                    Text('Weight: ${saved.vitals!.weight ?? "--"}'),
                    Text('FBS: ${saved.vitals!.fbs ?? "--"}'),
                    Text('PPBS: ${saved.vitals!.ppbs ?? "--"}'),
                    Text('HbA1c: ${saved.vitals!.hba1c ?? "--"}'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
    _clinicalHistoryController.dispose();
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