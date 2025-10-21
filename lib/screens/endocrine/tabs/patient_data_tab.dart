// lib/screens/endocrine/tabs/patient_data_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../config/thyroid_disease_config.dart';
import '../../../services/patient_data_service.dart';


class PatientDataTab extends StatefulWidget {
  final EndocrineCondition condition;
  final ThyroidDiseaseConfig diseaseConfig;
  final Function(EndocrineCondition) onUpdate;

  const PatientDataTab({
    super.key,
    required this.condition,
    required this.diseaseConfig,
    required this.onUpdate,
  });

  @override
  State<PatientDataTab> createState() => _PatientDataTabState();
}

class _PatientDataTabState extends State<PatientDataTab> {
  // Clinical History Controllers
  final _chiefComplaintController = TextEditingController();
  final _historyController = TextEditingController();
  final _pastHistoryController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Vitals Controllers
  final _bpController = TextEditingController();
  final _hrController = TextEditingController();
  final _tempController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _rrController = TextEditingController();

  // Measurements Controllers
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _calculatedBMI;

  @override
  void initState() {
    super.initState();
    _loadExistingData();

    // Add listeners for BMI calculation
    _heightController.addListener(_calculateBMI);
    _weightController.addListener(_calculateBMI);
  }

  // REPLACE _loadExistingData() in patient_data_tab.dart

  void _loadExistingData() async {
    // Load existing condition data
    _chiefComplaintController.text = widget.condition.chiefComplaint ?? '';
    _historyController.text = widget.condition.historyOfPresentIllness ?? '';
    _pastHistoryController.text = widget.condition.pastMedicalHistory ?? '';
    _familyHistoryController.text = widget.condition.familyHistory ?? '';
    _allergiesController.text = widget.condition.allergies ?? '';

    // Load vitals
    if (widget.condition.vitals != null) {
      _bpController.text = widget.condition.vitals!['bloodPressure'] ?? '';
      _hrController.text = widget.condition.vitals!['heartRate'] ?? '';
      _tempController.text = widget.condition.vitals!['temperature'] ?? '';
      _spo2Controller.text = widget.condition.vitals!['spo2'] ?? '';
      _rrController.text = widget.condition.vitals!['respiratoryRate'] ?? '';
    }

    // Load measurements
    if (widget.condition.measurements != null) {
      _heightController.text = widget.condition.measurements!['height'] ?? '';
      _weightController.text = widget.condition.measurements!['weight'] ?? '';
      _calculateBMI();
    }

    // ✅ NEW: Check for previous patient data
    if (widget.condition.chiefComplaint == null ||
        widget.condition.vitals == null ||
        widget.condition.vitals!.isEmpty) {

      final snapshot = await PatientDataService.instance.getLatestPatientData(
          widget.condition.patientId
      );

      if (snapshot != null && mounted) {
        // Show auto-fill dialog
        final shouldAutoFill = await PatientDataService.instance.showAutoFillDialog(
          context,
          patientName: widget.condition.patientName,
          lastUpdated: snapshot.lastUpdated,
          updatedFrom: snapshot.updatedFrom,
        );

        if (shouldAutoFill) {
          final updatedCondition = await PatientDataService.instance.autoFillEndocrineCondition(
              widget.condition
          );

          widget.onUpdate(updatedCondition);

          // Reload with auto-filled data
          setState(() {
            _loadExistingData();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Patient data auto-filled successfully'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _calculateBMI() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (height != null && weight != null && height > 0) {
      final heightInMeters = height / 100;
      final bmi = weight / (heightInMeters * heightInMeters);
      setState(() {
        _calculatedBMI = bmi.toStringAsFixed(1);
      });
    } else {
      setState(() {
        _calculatedBMI = null;
      });
    }
  }

  void _saveData() async {
    final updatedCondition = widget.condition.copyWith(
      chiefComplaint: _chiefComplaintController.text,
      historyOfPresentIllness: _historyController.text,
      pastMedicalHistory: _pastHistoryController.text,
      familyHistory: _familyHistoryController.text,
      allergies: _allergiesController.text,
      vitals: {
        'bloodPressure': _bpController.text,
        'heartRate': _hrController.text,
        'temperature': _tempController.text,
        'spo2': _spo2Controller.text,
        'respiratoryRate': _rrController.text,
      },
      measurements: {
        'height': _heightController.text,
        'weight': _weightController.text,
        'bmi': _calculatedBMI ?? '',
      },
    );

    widget.onUpdate(updatedCondition);

    // ✅ NEW: Also save to patient data service
    await PatientDataService.instance.updateFromEndocrine(updatedCondition);
  }

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _historyController.dispose();
    _pastHistoryController.dispose();
    _familyHistoryController.dispose();
    _allergiesController.dispose();
    _bpController.dispose();
    _hrController.dispose();
    _tempController.dispose();
    _spo2Controller.dispose();
    _rrController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info Card (Read-only)
          _buildPatientInfoCard(),
          const SizedBox(height: 20),

          // Clinical History Section
          _buildSectionHeader('Clinical History', Icons.medical_information),
          const SizedBox(height: 12),
          _buildClinicalHistorySection(),
          const SizedBox(height: 24),

          // Vital Signs Section
          _buildSectionHeader('Vital Signs', Icons.favorite),
          const SizedBox(height: 12),
          _buildVitalsSection(),
          const SizedBox(height: 24),

          // Measurements Section
          _buildSectionHeader('Measurements', Icons.height),
          const SizedBox(height: 12),
          _buildMeasurementsSection(),
          const SizedBox(height: 24),

          // Quick Save Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                _saveData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Patient data saved'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Patient Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF2563EB).withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF2563EB),
              child: Text(
                widget.condition.patientName?.substring(0, 1).toUpperCase() ?? 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.condition.patientName ?? 'Patient',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.badge, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.condition.patientId,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.medical_services, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.diseaseConfig.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.condition.status),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getStatusText(widget.condition.status),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalHistorySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(
              controller: _chiefComplaintController,
              label: 'Chief Complaint *',
              hint: 'Main reason for visit',
              icon: Icons.priority_high,
              maxLines: 2,
              onChanged: (value) => _saveData(),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _historyController,
              label: 'History of Present Illness',
              hint: 'Duration, severity, associated symptoms...',
              icon: Icons.history,
              maxLines: 3,
              onChanged: (value) => _saveData(),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _pastHistoryController,
              label: 'Past Medical History',
              hint: 'Previous conditions, surgeries...',
              icon: Icons.folder_open,
              maxLines: 2,
              onChanged: (value) => _saveData(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _familyHistoryController,
                    label: 'Family History',
                    hint: 'Hereditary conditions',
                    icon: Icons.people,
                    maxLines: 2,
                    onChanged: (value) => _saveData(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _allergiesController,
                    label: 'Allergies',
                    hint: 'Drug/food allergies',
                    icon: Icons.warning,
                    maxLines: 2,
                    onChanged: (value) => _saveData(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildVitalField(
                    controller: _bpController,
                    label: 'Blood Pressure',
                    hint: '120/80',
                    unit: 'mmHg',
                    icon: Icons.favorite,
                    onChanged: (value) => _saveData(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalField(
                    controller: _hrController,
                    label: 'Heart Rate',
                    hint: '72',
                    unit: 'bpm',
                    icon: Icons.monitor_heart,
                    onChanged: (value) => _saveData(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildVitalField(
                    controller: _tempController,
                    label: 'Temperature',
                    hint: '98.6',
                    unit: '°F',
                    icon: Icons.thermostat,
                    onChanged: (value) => _saveData(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalField(
                    controller: _spo2Controller,
                    label: 'SpO2',
                    hint: '98',
                    unit: '%',
                    icon: Icons.air,
                    onChanged: (value) => _saveData(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildVitalField(
              controller: _rrController,
              label: 'Respiratory Rate',
              hint: '16',
              unit: '/min',
              icon: Icons.wind_power,
              onChanged: (value) => _saveData(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildVitalField(
                    controller: _heightController,
                    label: 'Height',
                    hint: '170',
                    unit: 'cm',
                    icon: Icons.height,
                    onChanged: (value) => _saveData(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalField(
                    controller: _weightController,
                    label: 'Weight',
                    hint: '70',
                    unit: 'kg',
                    icon: Icons.monitor_weight,
                    onChanged: (value) => _saveData(),
                  ),
                ),
              ],
            ),
            if (_calculatedBMI != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getBMIColor(double.parse(_calculatedBMI!)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBMIColor(double.parse(_calculatedBMI!)),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getBMIColor(double.parse(_calculatedBMI!)),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calculate,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Body Mass Index',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _calculatedBMI!,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _getBMIColor(double.parse(_calculatedBMI!)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getBMIColor(double.parse(_calculatedBMI!)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getBMICategory(double.parse(_calculatedBMI!)),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  Widget _buildVitalField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String unit,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: label == 'Blood Pressure'
          ? TextInputType.text
          : TextInputType.number,
      inputFormatters: label == 'Blood Pressure'
          ? [BloodPressureFormatter()]
          : null,
      onChanged: onChanged,
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(DiagnosisStatus status) {
    switch (status) {
      case DiagnosisStatus.suspected:
        return Colors.orange;
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
      case DiagnosisStatus.confirmed:
        return 'Confirmed';
      case DiagnosisStatus.ruledOut:
        return 'Ruled Out';
    }
  }
}

// Blood Pressure Formatter
class BloodPressureFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    if (digitsOnly.length == 3 && !text.contains('/')) {
      final formatted = '$digitsOnly/';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    if (digitsOnly.length > 3) {
      final systolic = digitsOnly.substring(0, 3);
      final diastolic = digitsOnly.substring(3, digitsOnly.length > 6 ? 6 : digitsOnly.length);
      final formatted = '$systolic/$diastolic';

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );
  }
}