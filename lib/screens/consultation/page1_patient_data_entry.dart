

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/consultation_data.dart';
import '../../models/lab_result.dart';
import '../../services/database_helper.dart';
import 'package:flutter/services.dart';
import '../../services/patient_data_service.dart';

class BloodPressureFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;

    // Remove any non-digit characters except slash
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    // If user is deleting, allow it
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // If we have exactly 3 digits and no slash yet, add the slash
    if (digitsOnly.length == 3 && !text.contains('/')) {
      final formatted = '${digitsOnly}/';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // If we have more than 3 digits, format as systolic/diastolic
    if (digitsOnly.length > 3) {
      final systolic = digitsOnly.substring(0, 3);
      final diastolic = digitsOnly.substring(3, digitsOnly.length > 6 ? 6 : digitsOnly.length);
      final formatted = '$systolic/$diastolic';

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // For 1-3 digits, just show the digits
    return TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );
  }
}



class Page1PatientDataEntry extends StatefulWidget {
  const Page1PatientDataEntry({super.key});

  @override
  State<Page1PatientDataEntry> createState() => _Page1PatientDataEntryState();
}

class _Page1PatientDataEntryState extends State<Page1PatientDataEntry> {
  // Controllers for text fields
  final _chiefComplaintController = TextEditingController();
  final _historyController = TextEditingController();
  final _pastHistoryController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Vital controllers
  final _bpController = TextEditingController();
  final _hrController = TextEditingController();
  final _tempController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _rrController = TextEditingController();

  // Measurement controllers
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Search controller
  final _searchController = TextEditingController();
 // List<LabTestTemplate> _searchResults = [];

  // Auto-save variables
  Timer? _autoSaveTimer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();

    // Add listeners for auto-save
    _chiefComplaintController.addListener(_onTextChanged);
    _historyController.addListener(_onTextChanged);
    _pastHistoryController.addListener(_onTextChanged);
    _familyHistoryController.addListener(_onTextChanged);
    _allergiesController.addListener(_onTextChanged);
    _bpController.addListener(_onTextChanged);
    _hrController.addListener(_onTextChanged);
    _tempController.addListener(_onTextChanged);
    _spo2Controller.addListener(_onTextChanged);
    _rrController.addListener(_onTextChanged);
    _heightController.addListener(_onTextChanged);
    _weightController.addListener(_onTextChanged);
  }

  // Trigger auto-save on text change
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
              '• All clinical history\n'
              '• Vital signs\n'
              '• Measurements\n'
              '• Lab results\n\n'
              'Patient information will be kept.',
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
      _chiefComplaintController.clear();
      _historyController.clear();
      _pastHistoryController.clear();
      _familyHistoryController.clear();
      _allergiesController.clear();
      _bpController.clear();
      _hrController.clear();
      _tempController.clear();
      _spo2Controller.clear();
      _rrController.clear();
      _heightController.clear();
      _weightController.clear();

      // Clear data model
      data.updateChiefComplaint('');
      data.updateHistoryOfPresentIllness('');
      data.updatePastMedicalHistory('');
      data.familyHistory = '';
      data.allergies = '';
      data.updateVital('bloodPressure', '');
      data.updateVital('heartRate', '');
      data.updateVital('temperature', '');
      data.updateVital('spo2', '');
      data.updateVital('respiratoryRate', '');
      data.updateMeasurements(height: '', weight: '');
      data.labResults.clear();

      setState(() {});

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



  Future<void> _autoSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final data = Provider.of<ConsultationData>(context, listen: false);

      // Update data model
      data.updateChiefComplaint(_chiefComplaintController.text);
      data.updateHistoryOfPresentIllness(_historyController.text);
      data.updatePastMedicalHistory(_pastHistoryController.text);
      data.familyHistory = _familyHistoryController.text;
      data.allergies = _allergiesController.text;

      data.updateVital('bloodPressure', _bpController.text);
      data.updateVital('heartRate', _hrController.text);
      data.updateVital('temperature', _tempController.text);
      data.updateVital('spo2', _spo2Controller.text);
      data.updateVital('respiratoryRate', _rrController.text);

      data.updateMeasurements(
        height: _heightController.text,
        weight: _weightController.text,
      );

      // Save to database
      await DatabaseHelper.instance.saveDraftConsultation(
        data.patient.id,
        data.toDraftJson(),
      );

      // ✅ NEW: Also save to patient data service
      await PatientDataService.instance.updateFromConsultation(data);

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

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
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
    _searchController.dispose();
    super.dispose();
  }


  void _loadExistingData() async {
    final data = Provider.of<ConsultationData>(context, listen: false);

    // Load from ConsultationData
    _chiefComplaintController.text = data.chiefComplaint;
    _historyController.text = data.historyOfPresentIllness;
    _pastHistoryController.text = data.pastMedicalHistory;
    _familyHistoryController.text = data.familyHistory;
    _allergiesController.text = data.allergies;

    // Load vitals
    _bpController.text = data.vitals['bloodPressure'] ?? '';
    _hrController.text = data.vitals['heartRate'] ?? '';
    _tempController.text = data.vitals['temperature'] ?? '';
    _spo2Controller.text = data.vitals['spo2'] ?? '';
    _rrController.text = data.vitals['respiratoryRate'] ?? '';

    // Load measurements
    _heightController.text = data.height ?? '';
    _weightController.text = data.weight ?? '';

    // ✅ NEW: Check for previous patient data
    final snapshot = await PatientDataService.instance.getLatestPatientData(data.patient.id);

    if (snapshot != null && _isDataEmpty(data)) {
      // Show auto-fill dialog
      final shouldAutoFill = await PatientDataService.instance.showAutoFillDialog(
        context,
        patientName: data.patient.name,
        lastUpdated: snapshot.lastUpdated,
        updatedFrom: snapshot.updatedFrom,
      );

      if (shouldAutoFill) {
        await PatientDataService.instance.autoFillConsultationData(data);
        _loadExistingData(); // Reload with auto-filled data

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

// Helper to check if data is empty
  bool _isDataEmpty(ConsultationData data) {
    return data.chiefComplaint.isEmpty &&
        data.vitals.isEmpty &&
        data.height == null;
  }

  // Format time helper
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
      builder: (context, data, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto-save indicator
              if (_isSaving || data.hasUnsavedChanges)
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
                      if (data.lastSaved != null) ...[
                        Spacer(),
                        Text(
                          'Last saved: ${_formatTime(data.lastSaved!)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),

              // Page header with Reset button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Patient Data Entry',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetPage,
                    icon: Icon(Icons.restart_alt, size: 18),
                    label: Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Patient Info Card (Read-only)
              _buildPatientInfoCard(data),
              const SizedBox(height: 24),

              // Clinical History Section
              _buildSectionHeader('Clinical History', Icons.medical_information),
              const SizedBox(height: 12),
              _buildClinicalHistorySection(data),
              const SizedBox(height: 24),

              // Vitals Section
              _buildSectionHeader('Vital Signs', Icons.favorite),
              const SizedBox(height: 12),
              _buildVitalsSection(data),
              const SizedBox(height: 24),

              // Measurements Section
              _buildSectionHeader('Measurements', Icons.height),
              const SizedBox(height: 12),
              _buildMeasurementsSection(data),
              const SizedBox(height: 24),

              // Lab Results Section
              _buildSectionHeader('Lab Results', Icons.science),
              const SizedBox(height: 12),
              _buildLabResultsSection(data),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientInfoCard(ConsultationData data) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade700,
              child: Text(
                data.patient.name.substring(0, 1).toUpperCase(),
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
                    data.patient.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.patient.age} years • ${data.patient.phone}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
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

  Widget _buildSectionHeader(String title, IconData icon) {
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

  Widget _buildClinicalHistorySection(ConsultationData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(
              controller: _chiefComplaintController,
              label: 'Chief Complaint *',
              hint: 'Main reason for visit',
              icon: Icons.priority_high,
              onChanged: (value) => data.updateChiefComplaint(value),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _historyController,
              label: 'History of Present Illness',
              hint: 'Duration, severity, associated symptoms...',
              icon: Icons.history,
              onChanged: (value) => data.updateHistoryOfPresentIllness(value),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _pastHistoryController,
              label: 'Past Medical History',
              hint: 'Previous conditions, surgeries...',
              icon: Icons.folder_open,
              onChanged: (value) => data.updatePastMedicalHistory(value),
              maxLines: 2,
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
                    onChanged: (value) => data.familyHistory = value,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _allergiesController,
                    label: 'Allergies',
                    hint: 'Drug/food allergies',
                    icon: Icons.warning,
                    onChanged: (value) => data.allergies = value,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsSection(ConsultationData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    onChanged: (value) => data.updateVital('bloodPressure', value),
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
                    onChanged: (value) => data.updateVital('heartRate', value),
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
                    onChanged: (value) => data.updateVital('temperature', value),
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
                    onChanged: (value) => data.updateVital('spo2', value),
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
              onChanged: (value) => data.updateVital('respiratoryRate', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsSection(ConsultationData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    onChanged: (value) {
                      data.updateMeasurements(height: value);
                      setState(() {});
                    },
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
                    onChanged: (value) {
                      data.updateMeasurements(weight: value);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            if (data.bmi != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calculate, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'BMI: ${data.bmi}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _getBMICategory(double.tryParse(data.bmi!) ?? 0),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
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

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Widget _buildLabResultsSection(ConsultationData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.folder),
                    label: const Text('Add by System'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                    label: const Text('Search Test'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade600,
                    ),
                  ),
                ),
              ],
            ),
            if (data.labResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...data.labResults.asMap().entries.map((entry) {
                return _buildLabResultCard(data, entry.key, entry.value);
              }),
            ] else ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No lab results added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabResultCard(ConsultationData data, int index, LabResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: result.isAbnormal ? Colors.red.shade50 : Colors.green.shade50,
      child: ListTile(
        leading: Icon(
          result.isAbnormal ? Icons.warning : Icons.check_circle,
          color: result.isAbnormal ? Colors.red : Colors.green,
        ),
        title: Text(
          result.testName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${result.value} ${result.unit}',
          style: TextStyle(
            color: result.isAbnormal ? Colors.red.shade900 : Colors.green.shade900,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => data.removeLabResult(index),
            ),
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
      ),
      keyboardType: TextInputType.number,
      inputFormatters: label == 'Blood Pressure' ? [BloodPressureFormatter()] : null,
      onChanged: onChanged,
    );
  }
}