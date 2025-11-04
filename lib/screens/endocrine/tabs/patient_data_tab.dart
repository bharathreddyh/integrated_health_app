// lib/screens/endocrine/tabs/patient_data_tab.dart
// COMPLETE VERSION WITH LAB TESTS SECTION

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../models/endocrine/lab_test_result.dart';
import '../../../config/thyroid_disease_config.dart';
import '../../../services/patient_data_service.dart';
import '../../../services/database_helper.dart';
import '../../../services/user_service.dart';
import '../../../widgets/lab_test_result_card.dart';
import '../../../dialogs/add_lab_test_dialog.dart';
import '../../../models/endocrine/investigation_finding.dart';
import '../../../widgets/investigation_finding_card.dart';
import '../../../config/investigation_library.dart';

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

  // Lab test results
  List<LabTestResult> _labTestResults = [];
  List<InvestigationFinding> _investigationFindings = [];
  // Auto-save
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _loadLabTestResults();
    _loadInvestigationFindings(); // 🆕 ADD THIS LINE
    // Add listeners for BMI calculation
    _heightController.addListener(_calculateBMI);
    _weightController.addListener(_calculateBMI);
  }
  @override
  void didUpdateWidget(PatientDataTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    print('');
    print('🔄 ═══════════════════════════════════════');
    print('🔄 PatientDataTab didUpdateWidget');
    print('   Old condition ID: ${oldWidget.condition.id}');
    print('   New condition ID: ${widget.condition.id}');
    print('   Old Chief Complaint: "${oldWidget.condition.chiefComplaint ?? "empty"}"');
    print('   New Chief Complaint: "${widget.condition.chiefComplaint ?? "empty"}"');
    print('   Condition changed: ${oldWidget.condition.id != widget.condition.id}');
    print('   Data changed: ${oldWidget.condition.chiefComplaint != widget.condition.chiefComplaint}');

    // ✅ FIX: Reload data whenever condition changes OR condition object is different
    if (oldWidget.condition.id != widget.condition.id ||
        oldWidget.condition != widget.condition) {
      print('   ✅ Reloading data because condition changed');
      _loadExistingData();
      _loadLabTestResults();
      _loadInvestigationFindings();
    } else {
      print('   ℹ️  No changes detected - keeping current state');
    }
    print('🔄 ═══════════════════════════════════════');
    print('');
  }

  void _loadExistingData() async {
    print('');
    print('📝 ═══════════════════════════════════════');
    print('📝 LOADING EXISTING DATA IN PATIENT DATA TAB');
    print('   Condition ID: ${widget.condition.id}');
    print('   Patient: ${widget.condition.patientName}');
    print('   Disease: ${widget.condition.diseaseName}');
    print('📝 ═══════════════════════════════════════');

    // ✅ FIX: Force update text controllers even if they have text
    print('   Loading text fields...');
    _chiefComplaintController.text = widget.condition.chiefComplaint ?? '';
    _historyController.text = widget.condition.historyOfPresentIllness ?? '';
    _pastHistoryController.text = widget.condition.pastMedicalHistory ?? '';
    _familyHistoryController.text = widget.condition.familyHistory ?? '';
    _allergiesController.text = widget.condition.allergies ?? '';

    print('   ✅ Chief Complaint: "${widget.condition.chiefComplaint ?? "empty"}"');
    print('   ✅ History: "${widget.condition.historyOfPresentIllness ?? "empty"}"');

    // Load vitals
    if (widget.condition.vitals != null && widget.condition.vitals!.isNotEmpty) {
      print('   ✅ Loading vitals: ${widget.condition.vitals!.keys.toList()}');
      _bpController.text = widget.condition.vitals!['bloodPressure'] ?? '';
      _hrController.text = widget.condition.vitals!['heartRate'] ?? '';
      _tempController.text = widget.condition.vitals!['temperature'] ?? '';
      _spo2Controller.text = widget.condition.vitals!['spo2'] ?? '';
      _rrController.text = widget.condition.vitals!['respiratoryRate'] ?? '';
      print('   ✅ Vitals loaded: BP=${_bpController.text}, HR=${_hrController.text}');
    } else {
      print('   ⚠️  No vitals found - clearing fields');
      _bpController.clear();
      _hrController.clear();
      _tempController.clear();
      _spo2Controller.clear();
      _rrController.clear();
    }

    // Load measurements
    if (widget.condition.measurements != null && widget.condition.measurements!.isNotEmpty) {
      print('   ✅ Loading measurements: ${widget.condition.measurements!.keys.toList()}');
      _heightController.text = widget.condition.measurements!['height'] ?? '';
      _weightController.text = widget.condition.measurements!['weight'] ?? '';
      _calculateBMI();
      print('   ✅ Measurements loaded: Height=${_heightController.text}, Weight=${_weightController.text}');
    } else {
      print('   ⚠️  No measurements found - clearing fields');
      _heightController.clear();
      _weightController.clear();
      _calculatedBMI = null;
    }

    print('📝 ═══════════════════════════════════════');
    print('📝 LOAD COMPLETE - Controllers updated');
    print('   Chief Complaint Controller: "${_chiefComplaintController.text}"');
    print('   BP Controller: "${_bpController.text}"');
    print('📝 ═══════════════════════════════════════');
    print('');

    // ✅ CRITICAL: Force UI rebuild to show updated values
    if (mounted) {
      setState(() {});
    }

    // ✅ FIXED: Only check for auto-fill if data is truly empty
    // AND only do this on first load, not on updates
    if (mounted &&
        (widget.condition.chiefComplaint == null || widget.condition.chiefComplaint!.isEmpty) &&
        (widget.condition.vitals == null || widget.condition.vitals!.isEmpty)) {

      print('   ℹ️  Data is empty - checking for auto-fill...');

      final snapshot = await PatientDataService.instance
          .getLatestPatientData(widget.condition.patientId);

      if (snapshot != null && mounted) {
        final shouldAutoFill =
        await PatientDataService.instance.showAutoFillDialog(
          context,
          patientName: widget.condition.patientName,
          lastUpdated: snapshot.lastUpdated,
          updatedFrom: snapshot.updatedFrom,
        );

        if (shouldAutoFill && mounted) {
          final updatedCondition = await PatientDataService.instance
              .autoFillEndocrineCondition(widget.condition);

          // ✅ FIXED: Update parent first, then reload
          widget.onUpdate(updatedCondition);

          // The didUpdateWidget will handle reloading when parent updates
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
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
    } else {
      print('   ✅ Data already present - skipping auto-fill check');
    }
  }

  void _loadLabTestResults() {
    setState(() {
      _labTestResults = List.from(widget.condition.labTestResults ?? []);
    });
  }
  void _loadInvestigationFindings() {
    setState(() {
      _investigationFindings = List.from(widget.condition.investigationFindings ?? []);
    });
  }
  Future<void> _addLabTestResult() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AddLabTestDialog(
        onResultAdded: (result) {
          // 🆕 Add result immediately when created
          setState(() {
            _labTestResults.add(result);
          });

          // Auto-save
          _onDataChanged();

          // Show brief notification in parent
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('${result.testName} result added'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _editLabTestResult(int index) async {
    final result = await showDialog<LabTestResult>(
      context: context,
      builder: (context) => AddLabTestDialog(
        existingResult: _labTestResults[index],
      ),
    );

    if (result != null) {
      setState(() => _labTestResults[index] = result);
      _onDataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Lab test result updated'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteLabTestResult(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lab Test Result'),
        content: Text(
          'Are you sure you want to delete ${_labTestResults[index].testName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _labTestResults.removeAt(index));
      _onDataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Lab test result deleted'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  Future<void> _addInvestigationFinding() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => _QuickAddInvestigationDialog(
        onFindingAdded: (finding) {
          // 🆕 Add finding immediately when created
          setState(() {
            _investigationFindings.add(finding);
          });

          // Auto-save
          _saveData();

          // Show brief notification in parent
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('${finding.investigationName} added'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editInvestigationFinding(int index) async {
    final result = await showDialog<InvestigationFinding>(
      context: context,
      builder: (context) => _QuickAddInvestigationDialog(
        existingFinding: _investigationFindings[index],
        // Don't pass onFindingAdded for editing
      ),
    );

    if (result != null) {
      setState(() {
        _investigationFindings[index] = result;
      });

      // Auto-save
      _saveData();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Investigation finding updated'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteInvestigationFinding(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investigation Finding'),
        content: Text(
          'Are you sure you want to delete ${_investigationFindings[index].investigationName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _investigationFindings.removeAt(index));
      _onDataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Investigation finding deleted'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _viewTrend(String testName) {
    final trendData = _labTestResults
        .where((r) => r.testName == testName)
        .toList()
      ..sort((a, b) => a.testDate.compareTo(b.testDate));

    showDialog(
      context: context,
      builder: (context) => _TrendChartDialog(
        testName: testName,
        results: trendData,
      ),
    );
  }

  void _onDataChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  Future<void> _autoSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      print('');
      print('🔄 ═════════════════════════════════════════════════════════════');
      print('🔄 AUTO-SAVE TRIGGERED');
      print('🔄 ═════════════════════════════════════════════════════════════');
      print('📍 CURRENT STATE:');
      print('   Condition ID: ${widget.condition.id}');
      print('   Patient ID: ${widget.condition.patientId}');
      print('   Patient Name: ${widget.condition.patientName}');
      print('   Disease: ${widget.condition.diseaseName}');
      print('');
      print('📝 DATA TO SAVE:');
      print('   Chief Complaint: "${_chiefComplaintController.text}"');
      print('   History: "${_historyController.text.substring(0, _historyController.text.length > 50 ? 50 : _historyController.text.length)}${_historyController.text.length > 50 ? "..." : ""}"');
      print('   Blood Pressure: "${_bpController.text}"');
      print('   Heart Rate: "${_hrController.text}"');
      print('   Temperature: "${_tempController.text}"');
      print('   SpO2: "${_spo2Controller.text}"');
      print('   Respiratory Rate: "${_rrController.text}"');
      print('   Height: "${_heightController.text}"');
      print('   Weight: "${_weightController.text}"');
      print('   BMI: "${_calculatedBMI ?? "not calculated"}"');
      print('   Lab Test Results Count: ${_labTestResults.length}');
      print('   Investigation Findings Count: ${_investigationFindings.length}');

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
        labTestResults: _labTestResults,
        investigationFindings: _investigationFindings,
      );

      print('');
      print('💾 SAVING TO DATABASE...');
      print('   Updated Condition ID: ${updatedCondition.id}');
      print('   Updated Chief Complaint: "${updatedCondition.chiefComplaint}"');
      print('   Updated Vitals: ${updatedCondition.vitals}');
      print('   Updated Measurements: ${updatedCondition.measurements}');

      // ✅ FIX: Save to BOTH tables to keep them in sync
      await DatabaseHelper.instance.saveEndocrineCondition(updatedCondition);
      print('   ✅ Saved to endocrine_conditions table');

      // ✅ ALSO save to visits table for history
      final doctorId = UserService.currentUserId ?? 'unknown';
      await DatabaseHelper.instance.saveEndocrineVisit(updatedCondition, doctorId);
      print('   ✅ Saved to endocrine_visits table (doctorId: $doctorId)');

      widget.onUpdate(updatedCondition);
      print('   ✅ Updated parent state');

      await PatientDataService.instance.updateFromEndocrine(updatedCondition);
      print('   ✅ Updated patient data snapshot');

      setState(() => _lastSaved = DateTime.now());

      print('');
      print('✅ AUTO-SAVE COMPLETE at ${DateTime.now()}');
      print('🔄 ═════════════════════════════════════════════════════════════');
      print('');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Patient data auto-saved (ID: ${updatedCondition.id.substring(0, 8)}...)'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('');
      print('❌ ═════════════════════════════════════════════════════════════');
      print('❌ AUTO-SAVE ERROR');
      print('❌ ═════════════════════════════════════════════════════════════');
      print('Error: $e');
      print('Stack trace:');
      print(stackTrace.toString().split('\n').take(10).join('\n'));
      print('❌ ═════════════════════════════════════════════════════════════');
      print('');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _calculateBMI() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (height != null && weight != null && height > 0) {
      final heightInMeters = height / 100;
      final bmi = weight / (heightInMeters * heightInMeters);
      setState(() => _calculatedBMI = bmi.toStringAsFixed(1));
    } else {
      setState(() => _calculatedBMI = null);
    }
  }

  void _saveData() async {
    print('');
    print('💾 ═════════════════════════════════════════════════════════════');
    print('💾 MANUAL SAVE TRIGGERED');
    print('💾 ═════════════════════════════════════════════════════════════');
    print('📍 CURRENT STATE:');
    print('   Condition ID: ${widget.condition.id}');
    print('   Patient ID: ${widget.condition.patientId}');
    print('   Patient Name: ${widget.condition.patientName}');
    print('   Disease: ${widget.condition.diseaseName}');
    print('');
    print('📝 DATA TO SAVE:');
    print('   Chief Complaint: "${_chiefComplaintController.text}"');
    print('   History: "${_historyController.text.substring(0, _historyController.text.length > 50 ? 50 : _historyController.text.length)}${_historyController.text.length > 50 ? "..." : ""}"');
    print('   Past Medical History: "${_pastHistoryController.text.substring(0, _pastHistoryController.text.length > 50 ? 50 : _pastHistoryController.text.length)}${_pastHistoryController.text.length > 50 ? "..." : ""}"');
    print('   Vitals:');
    print('     Blood Pressure: "${_bpController.text}"');
    print('     Heart Rate: "${_hrController.text}"');
    print('     Temperature: "${_tempController.text}"');
    print('     SpO2: "${_spo2Controller.text}"');
    print('     Respiratory Rate: "${_rrController.text}"');
    print('   Measurements:');
    print('     Height: "${_heightController.text}"');
    print('     Weight: "${_weightController.text}"');
    print('     BMI: "${_calculatedBMI ?? "not calculated"}"');

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
      labTestResults: _labTestResults,
      investigationFindings: _investigationFindings,
    );

    print('');
    print('💾 SAVING TO DATABASE...');
    print('   Updated Condition ID: ${updatedCondition.id}');
    print('   Updated Chief Complaint: "${updatedCondition.chiefComplaint}"');
    print('   Updated Vitals: ${updatedCondition.vitals}');
    print('   Updated Measurements: ${updatedCondition.measurements}');

    // ✅ FIX 1: Save to database (both tables to keep them in sync)
    try {
      await DatabaseHelper.instance.saveEndocrineCondition(updatedCondition);
      print('   ✅ Saved to endocrine_conditions table');

      // ✅ ALSO save to visits table for history
      final doctorId = UserService.currentUserId ?? 'unknown';
      await DatabaseHelper.instance.saveEndocrineVisit(updatedCondition, doctorId);
      print('   ✅ Saved to endocrine_visits table (doctorId: $doctorId)');
    } catch (e, stackTrace) {
      print('   ❌ Error saving to database: $e');
      print('   Stack trace:');
      print(stackTrace.toString().split('\n').take(5).join('\n'));
    }

    // ✅ FIX 2: Update parent state
    widget.onUpdate(updatedCondition);
    print('   ✅ Updated parent state');

    // ✅ FIX 3: Update patient data snapshot
    await PatientDataService.instance.updateFromEndocrine(updatedCondition);
    print('   ✅ Updated patient data snapshot');

    print('');
    print('✅ MANUAL SAVE COMPLETE at ${DateTime.now()}');
    print('💾 ═════════════════════════════════════════════════════════════');
    print('');
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
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientInfoCard(),
          const SizedBox(height: 20),
          _buildSectionHeader('Clinical History', Icons.medical_information),
          const SizedBox(height: 12),
          _buildClinicalHistorySection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Vital Signs', Icons.favorite),
          const SizedBox(height: 12),
          _buildVitalsSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Measurements', Icons.height),
          const SizedBox(height: 12),
          _buildMeasurementsSection(),
          const SizedBox(height: 24),
          _buildLabTestsSection(),
          const SizedBox(height: 24),
          _buildInvestigationsSection(),
          const SizedBox(height: 24),
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

  Widget _buildLabTestsSection() {
    final resultsByCategory = <String, List<LabTestResult>>{};
    for (final result in _labTestResults) {
      resultsByCategory.putIfAbsent(result.category, () => []).add(result);
    }

    for (final category in resultsByCategory.keys) {
      resultsByCategory[category]!.sort((a, b) => b.testDate.compareTo(a.testDate));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.science, color: Colors.purple.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LAB TEST RESULTS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      SizedBox(height: 2),
                      Text('Record results of tests already performed', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addLabTestResult,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Result'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_labTestResults.isEmpty) _buildEmptyState() else _buildLabResultsList(resultsByCategory),
          ],
        ),
      ),
    );
  }
  Widget _buildInvestigationsSection() {
    // Group findings by type
    final findingsByType = <String, List<InvestigationFinding>>{};
    for (final finding in _investigationFindings) {
      findingsByType.putIfAbsent(finding.investigationType, () => []).add(finding);
    }

    // Sort each type by date (newest first)
    for (final type in findingsByType.keys) {
      findingsByType[type]!.sort((a, b) => b.performedDate.compareTo(a.performedDate));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.medical_information, color: Colors.teal.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INVESTIGATION FINDINGS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      SizedBox(height: 2),
                      Text('Record findings from imaging, biopsies, and other tests', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addInvestigationFinding,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Finding'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            if (_investigationFindings.isEmpty)
              _buildInvestigationsEmptyState()
            else
              _buildInvestigationsList(findingsByType),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestigationsEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.medical_information_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No investigation findings recorded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Add findings from USG, CT, MRI, FNAC, and other investigations', style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _addInvestigationFinding,
              icon: const Icon(Icons.add),
              label: const Text('Add First Finding'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: const BorderSide(color: Colors.teal),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestigationsList(Map<String, List<InvestigationFinding>> findingsByType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary stats
        _buildInvestigationSummaryStats(),
        const SizedBox(height: 20),

        // Findings by type
        ...findingsByType.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type header
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getInvestigationTypeIcon(entry.key), size: 16, color: Colors.teal.shade700),
                      const SizedBox(width: 6),
                      Text(_getInvestigationTypeLabel(entry.key), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.teal.shade700, borderRadius: BorderRadius.circular(10)),
                        child: Text('${entry.value.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),

              // Investigation findings in this type
              ...entry.value.map((finding) {
                final globalIndex = _investigationFindings.indexOf(finding);
                return InvestigationFindingCard(
                  id: finding.id,
                  investigationType: finding.investigationType,
                  investigationName: finding.investigationName,
                  performedDate: finding.performedDate,
                  findings: finding.findings,
                  impression: finding.impression,
                  structuredData: finding.structuredData,
                  performedBy: finding.performedBy,
                  onEdit: () => _editInvestigationFinding(globalIndex),
                  onDelete: () => _deleteInvestigationFinding(globalIndex),
                );
              }).toList(),

              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInvestigationSummaryStats() {
    final totalInvestigations = _investigationFindings.length;
    final types = _investigationFindings.map((f) => f.investigationType).toSet().length;
    final recentCount = _investigationFindings.where((f) => f.performedDate.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.cyan.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem(icon: Icons.assignment, label: 'Total', value: totalInvestigations.toString(), color: Colors.teal.shade700)),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(child: _buildStatItem(icon: Icons.category, label: 'Types', value: types.toString(), color: Colors.cyan.shade700)),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(child: _buildStatItem(icon: Icons.schedule, label: 'Recent (30d)', value: recentCount.toString(), color: Colors.blue.shade700)),
        ],
      ),
    );
  }

  IconData _getInvestigationTypeIcon(String type) {
    switch (type) {
      case 'ultrasound':
        return Icons.waves;
      case 'ct':
        return Icons.scanner;
      case 'mri':
        return Icons.medical_services;
      case 'biopsy':
        return Icons.biotech;
      case 'nuclear_medicine':
        return Icons.science;
      case 'cardiac':
        return Icons.favorite;
      default:
        return Icons.description;
    }
  }

  String _getInvestigationTypeLabel(String type) {
    switch (type) {
      case 'ultrasound':
        return 'Ultrasound';
      case 'ct':
        return 'CT Scans';
      case 'mri':
        return 'MRI Scans';
      case 'biopsy':
        return 'Biopsies';
      case 'nuclear_medicine':
        return 'Nuclear Medicine';
      case 'cardiac':
        return 'Cardiac Tests';
      default:
        return 'Other';
    }
  }
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.science_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No lab test results recorded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Add results of tests that have already been performed', style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _addLabTestResult,
              icon: const Icon(Icons.add),
              label: const Text('Add First Result'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabResultsList(Map<String, List<LabTestResult>> resultsByCategory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryStats(),
        const SizedBox(height: 20),
        ...resultsByCategory.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder, size: 16, color: Colors.purple.shade700),
                      const SizedBox(width: 6),
                      Text(entry.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.purple.shade700, borderRadius: BorderRadius.circular(10)),
                        child: Text('${entry.value.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
              ...entry.value.map((result) {
                final globalIndex = _labTestResults.indexOf(result);
                return LabTestResultCard(
                  result: result,
                  onEdit: () => _editLabTestResult(globalIndex),
                  onDelete: () => _deleteLabTestResult(globalIndex),
                  onViewTrend: _labTestResults.where((r) => r.testName == result.testName).length > 1 ? () => _viewTrend(result.testName) : null,
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSummaryStats() {
    final totalTests = _labTestResults.length;
    final abnormalTests = _labTestResults.where((r) => r.isAbnormal).length;
    final normalTests = totalTests - abnormalTests;
    final categories = _labTestResults.map((r) => r.category).toSet().length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.blue.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem(icon: Icons.assignment, label: 'Total Tests', value: totalTests.toString(), color: Colors.blue.shade700)),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(child: _buildStatItem(icon: Icons.check_circle, label: 'Normal', value: normalTests.toString(), color: Colors.green.shade700)),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(child: _buildStatItem(icon: Icons.warning, label: 'Abnormal', value: abnormalTests.toString(), color: Colors.red.shade700)),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(child: _buildStatItem(icon: Icons.category, label: 'Categories', value: categories.toString(), color: Colors.purple.shade700)),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFF2563EB).withOpacity(0.1), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF2563EB),
              child: Text(widget.condition.patientName?.substring(0, 1).toUpperCase() ?? 'P', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.condition.patientName ?? 'Patient', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.badge, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(widget.condition.patientId, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      const SizedBox(width: 16),
                      const Icon(Icons.medical_services, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(widget.diseaseConfig.name, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _getStatusColor(widget.condition.status), borderRadius: BorderRadius.circular(16)),
              child: Text(_getStatusText(widget.condition.status), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
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
          decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
            _buildTextField(controller: _chiefComplaintController, label: 'Chief Complaint *', hint: 'Main reason for visit', icon: Icons.priority_high, maxLines: 2, onChanged: (value) => _onDataChanged()),
            const SizedBox(height: 16),
            _buildTextField(controller: _historyController, label: 'History of Present Illness', hint: 'Duration, severity, associated symptoms...', icon: Icons.history, maxLines: 3, onChanged: (value) => _onDataChanged()),
            const SizedBox(height: 16),
            _buildTextField(controller: _pastHistoryController, label: 'Past Medical History', hint: 'Previous conditions, surgeries...', icon: Icons.folder_open, maxLines: 2, onChanged: (value) => _onDataChanged()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(controller: _familyHistoryController, label: 'Family History', hint: 'Hereditary conditions', icon: Icons.people, maxLines: 2, onChanged: (value) => _onDataChanged())),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(controller: _allergiesController, label: 'Allergies', hint: 'Drug/food allergies', icon: Icons.warning, maxLines: 2, onChanged: (value) => _onDataChanged())),
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
                Expanded(child: _buildVitalField(controller: _bpController, label: 'Blood Pressure', hint: '120/80', unit: 'mmHg', icon: Icons.favorite, onChanged: (value) => _onDataChanged())),
                const SizedBox(width: 12),
                Expanded(child: _buildVitalField(controller: _hrController, label: 'Heart Rate', hint: '72', unit: 'bpm', icon: Icons.monitor_heart, onChanged: (value) => _onDataChanged())),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildVitalField(controller: _tempController, label: 'Temperature', hint: '98.6', unit: '°F', icon: Icons.thermostat, onChanged: (value) => _onDataChanged())),
                const SizedBox(width: 12),
                Expanded(child: _buildVitalField(controller: _spo2Controller, label: 'SpO2', hint: '98', unit: '%', icon: Icons.air, onChanged: (value) => _onDataChanged())),
              ],
            ),
            const SizedBox(height: 12),
            _buildVitalField(controller: _rrController, label: 'Respiratory Rate', hint: '16', unit: '/min', icon: Icons.wind_power, onChanged: (value) => _onDataChanged()),
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
                Expanded(child: _buildVitalField(controller: _heightController, label: 'Height', hint: '170', unit: 'cm', icon: Icons.height, onChanged: (value) => _onDataChanged())),
                const SizedBox(width: 12),
                Expanded(child: _buildVitalField(controller: _weightController, label: 'Weight', hint: '70', unit: 'kg', icon: Icons.monitor_weight, onChanged: (value) => _onDataChanged())),
              ],
            ),
            if (_calculatedBMI != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getBMIColor(double.parse(_calculatedBMI!)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getBMIColor(double.parse(_calculatedBMI!)), width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _getBMIColor(double.parse(_calculatedBMI!)), shape: BoxShape.circle),
                      child: const Icon(Icons.calculate, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Body Mass Index', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(_calculatedBMI!, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _getBMIColor(double.parse(_calculatedBMI!)))),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: _getBMIColor(double.parse(_calculatedBMI!)), borderRadius: BorderRadius.circular(12)),
                                child: Text(_getBMICategory(double.parse(_calculatedBMI!)), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, required Function(String) onChanged, int maxLines = 1}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  Widget _buildVitalField({required TextEditingController controller, required String label, required String hint, required String unit, required IconData icon, required Function(String) onChanged}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: label == 'Blood Pressure' ? TextInputType.text : TextInputType.number,
      inputFormatters: label == 'Blood Pressure' ? [BloodPressureFormatter()] : null,
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
      case DiagnosisStatus.provisional:  // 🆕 ADD
        return Colors.blue;
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
      case DiagnosisStatus.provisional:  // 🆕 ADD
        return 'Provisional';
      case DiagnosisStatus.confirmed:
        return 'Confirmed';
      case DiagnosisStatus.ruledOut:
        return 'Ruled Out';
    }
  }
}

// TREND CHART DIALOG
class _TrendChartDialog extends StatelessWidget {
  final String testName;
  final List<LabTestResult> results;

  const _TrendChartDialog({required this.testName, required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return AlertDialog(
        title: Text('Trend: $testName'),
        content: const Text('No historical data available'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      );
    }

    final unit = results.first.unit;
    final normalMin = results.first.normalMin;
    final normalMax = results.first.normalMax;

    return Dialog(
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.purple.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trend Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(testName, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: _buildSimpleChart(normalMin, normalMax, unit),
            ),
            const SizedBox(height: 16),
            const Text('Historical Values', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1)},
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade200),
                      children: [_buildTableCell('Date', isHeader: true), _buildTableCell('Value', isHeader: true), _buildTableCell('Status', isHeader: true)],
                    ),
                    ...results.reversed.map((result) {
                      return TableRow(
                        children: [
                          _buildTableCell('${result.testDate.day}/${result.testDate.month}/${result.testDate.year}'),
                          _buildTableCell('${result.value} $unit'),
                          _buildTableCell(result.status.toUpperCase(), color: result.status == 'normal' ? Colors.green : Colors.red),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text('Normal Range: $normalMin - $normalMax $unit', style: TextStyle(fontSize: 14, color: Colors.blue.shade900, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, color: color)),
    );
  }

  Widget _buildSimpleChart(double normalMin, double normalMax, String unit) {
    final values = results.map((r) => r.value).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final chartMin = (dataMin < normalMin ? dataMin : normalMin) * 0.9;
    final chartMax = (dataMax > normalMax ? dataMax : normalMax) * 1.1;
    final range = chartMax - chartMin;

    return CustomPaint(
      painter: _TrendChartPainter(results: results, normalMin: normalMin, normalMax: normalMax, chartMin: chartMin, chartMax: chartMax, range: range, unit: unit),
      child: Container(),
    );
  }
}

// TREND CHART PAINTER
class _TrendChartPainter extends CustomPainter {
  final List<LabTestResult> results;
  final double normalMin;
  final double normalMax;
  final double chartMin;
  final double chartMax;
  final double range;
  final String unit;

  _TrendChartPainter({required this.results, required this.normalMin, required this.normalMax, required this.chartMin, required this.chartMax, required this.range, required this.unit});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 2..style = PaintingStyle.stroke;

    final normalMinY = size.height - ((normalMin - chartMin) / range * size.height);
    final normalMaxY = size.height - ((normalMax - chartMin) / range * size.height);

    canvas.drawRect(Rect.fromLTRB(0, normalMaxY, size.width, normalMinY), Paint()..color = Colors.green.withOpacity(0.1));

    paint.color = Colors.green.withOpacity(0.5);
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;

    _drawDashedLine(canvas, Offset(0, normalMinY), Offset(size.width, normalMinY), paint);
    _drawDashedLine(canvas, Offset(0, normalMaxY), Offset(size.width, normalMaxY), paint);

    if (results.length > 1) {
      paint.color = Colors.purple.shade700;
      paint.strokeWidth = 3;
      paint.style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < results.length; i++) {
        final x = (i / (results.length - 1)) * size.width;
        final y = size.height - ((results[i].value - chartMin) / range * size.height);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    for (int i = 0; i < results.length; i++) {
      final x = results.length > 1 ? (i / (results.length - 1)) * size.width : size.width / 2;
      final y = size.height - ((results[i].value - chartMin) / range * size.height);

      canvas.drawCircle(Offset(x, y), 6, Paint()..color = results[i].isAbnormal ? Colors.red : Colors.green..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double distance = (end - start).distance;
    double totalDash = dashWidth + dashSpace;
    int count = (distance / totalDash).floor();

    for (int i = 0; i < count; i++) {
      double startX = start.dx + (end.dx - start.dx) * (i * totalDash) / distance;
      double startY = start.dy + (end.dy - start.dy) * (i * totalDash) / distance;
      double endX = start.dx + (end.dx - start.dx) * (i * totalDash + dashWidth) / distance;
      double endY = start.dy + (end.dy - start.dy) * (i * totalDash + dashWidth) / distance;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _QuickAddInvestigationDialog extends StatefulWidget {
  final InvestigationFinding? existingFinding;
  final Function(InvestigationFinding)? onFindingAdded;

  const _QuickAddInvestigationDialog({
    this.existingFinding,
    this.onFindingAdded,
  });

  @override
  State<_QuickAddInvestigationDialog> createState() => _QuickAddInvestigationDialogState();
}

class _QuickAddInvestigationDialogState extends State<_QuickAddInvestigationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController(); // 🆕 Add scroll controller
  String? _selectedCategory;
  String? _selectedInvestigation;
  DateTime _performedDate = DateTime.now();
  final _findingsController = TextEditingController();
  final _impressionController = TextEditingController();
  final _performedByController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingFinding != null) {
      _selectedCategory = InvestigationLibrary.categories.firstWhere(
            (cat) => InvestigationLibrary.getInvestigationsForCategory(cat).contains(widget.existingFinding!.investigationName),
        orElse: () => InvestigationLibrary.categories.first,
      );
      _selectedInvestigation = widget.existingFinding!.investigationName;
      _performedDate = widget.existingFinding!.performedDate;
      _findingsController.text = widget.existingFinding!.findings;
      _impressionController.text = widget.existingFinding!.impression;
      _performedByController.text = widget.existingFinding!.performedBy ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 Get screen height to make dialog responsive
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.85; // Use 85% of screen height

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: dialogHeight, // 🆕 Fixed height based on screen
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (Fixed at top)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_information, color: Colors.teal.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingFinding == null ? 'Add Investigation Finding' : 'Edit Investigation Finding',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // 🆕 Required fields indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All fields marked with * are required. Scroll down to see all fields.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // 🆕 Add controller
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          helperText: 'Select investigation category',
                        ),
                        items: InvestigationLibrary.categories
                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (value) => setState(() {
                          _selectedCategory = value;
                          _selectedInvestigation = null;
                        }),
                        validator: (value) => value == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 16),

                      // Investigation
                      DropdownButtonFormField<String>(
                        value: _selectedInvestigation,
                        decoration: const InputDecoration(
                          labelText: 'Investigation *',
                          border: OutlineInputBorder(),
                          helperText: 'Select specific investigation',
                        ),
                        items: _selectedCategory == null
                            ? []
                            : InvestigationLibrary.getInvestigationsForCategory(_selectedCategory!)
                            .map((inv) => DropdownMenuItem(value: inv, child: Text(inv)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedInvestigation = value),
                        validator: (value) => value == null ? 'Please select an investigation' : null,
                      ),
                      const SizedBox(height: 16),

                      // Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _performedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setState(() => _performedDate = date);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Performed Date *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text('${_performedDate.day}/${_performedDate.month}/${_performedDate.year}'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Findings
                      TextFormField(
                        controller: _findingsController,
                        decoration: const InputDecoration(
                          labelText: 'Findings *',
                          border: OutlineInputBorder(),
                          helperText: 'Describe the main findings',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter findings' : null,
                      ),
                      const SizedBox(height: 16),

                      // 🆕 IMPRESSION - Made more visible
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange.shade300, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextFormField(
                          controller: _impressionController,
                          decoration: InputDecoration(
                            labelText: 'Impression *',
                            labelStyle: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                            border: const OutlineInputBorder(),
                            helperText: 'Clinical impression/summary (REQUIRED)',
                            helperStyle: TextStyle(color: Colors.orange.shade700),
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Colors.orange.shade50,
                          ),
                          maxLines: 3,
                          validator: (value) => value == null || value.isEmpty ? 'Impression is required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Performed By (Optional but visible)
                      TextFormField(
                        controller: _performedByController,
                        decoration: const InputDecoration(
                          labelText: 'Performed By (Optional)',
                          border: OutlineInputBorder(),
                          helperText: 'Name of doctor/technician',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 24), // 🆕 Extra space at bottom
                    ],
                  ),
                ),
              ),
            ),

            // Footer (Fixed at bottom)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🆕 Scroll hint for mobile
                  if (MediaQuery.of(context).size.height < 700)
                    Row(
                      children: [
                        Icon(Icons.swipe_vertical, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Scroll to see all fields',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),

                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Create the finding
                            final finding = InvestigationFinding(
                              id: widget.existingFinding?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              investigationType: InvestigationLibrary.getInvestigationType(_selectedInvestigation!) ?? 'other',
                              investigationName: _selectedInvestigation!,
                              performedDate: _performedDate,
                              findings: _findingsController.text,
                              impression: _impressionController.text,
                              performedBy: _performedByController.text.isEmpty ? null : _performedByController.text,
                            );

                            // 🆕 If editing existing finding, just close
                            if (widget.existingFinding != null) {
                              Navigator.pop(context, finding);
                              return;
                            }

                            // 🆕 Show "Add More?" dialog
                            final shouldAddMore = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(child: Text('Finding Added Successfully!')),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Investigation: ${_selectedInvestigation!}',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Date: ${_performedDate.day}/${_performedDate.month}/${_performedDate.year}',
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                    SizedBox(height: 16),
                                    Text('Would you like to add another investigation finding?'),
                                  ],
                                ),
                                actions: [
                                  TextButton.icon(
                                    onPressed: () => Navigator.pop(context, false),
                                    icon: Icon(Icons.close, size: 18),
                                    label: Text('Close'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.pop(context, true),
                                    icon: Icon(Icons.add_circle_outline, size: 18),
                                    label: Text('Add More'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            // 🆕 Call the callback to add finding to list
                            if (widget.onFindingAdded != null) {
                              widget.onFindingAdded!(finding);
                            }

                            if (shouldAddMore == true) {
                              // 🆕 Clear form for next entry
                              setState(() {
                                _selectedCategory = null;
                                _selectedInvestigation = null;
                                _performedDate = DateTime.now();
                                _findingsController.clear();
                                _impressionController.clear();
                                _performedByController.clear();
                              });

                              // Scroll to top
                              _scrollController.animateTo(
                                0,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );

                              // Show brief success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Ready to add another finding'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              // Close the dialog
                              Navigator.pop(context, true); // Return true to indicate findings were added
                            }
                          } else {
                            // Validation failed
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text('Please fill all required fields (marked with *)'),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );

                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(widget.existingFinding == null ? 'Add Finding' : 'Update Finding'),
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 🆕 Dispose controller
    _findingsController.dispose();
    _impressionController.dispose();
    _performedByController.dispose();
    super.dispose();
  }
}
// BLOOD PRESSURE FORMATTER
class BloodPressureFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    if (newValue.text.length < oldValue.text.length) return newValue;

    if (digitsOnly.length == 3 && !text.contains('/')) {
      final formatted = '$digitsOnly/';
      return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
    }

    if (digitsOnly.length > 3) {
      final systolic = digitsOnly.substring(0, 3);
      final diastolic = digitsOnly.substring(3, digitsOnly.length > 6 ? 6 : digitsOnly.length);
      final formatted = '$systolic/$diastolic';
      return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
    }

    return TextEditingValue(text: digitsOnly, selection: TextSelection.collapsed(offset: digitsOnly.length));
  }
}