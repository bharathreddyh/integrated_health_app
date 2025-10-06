import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../../models/patient.dart';
import '../../models/marker.dart';
import '../../models/prescription.dart';
import '../../models/lab_test.dart';
import '../../services/pdf_generation_service.dart';
import '../../services/database_helper.dart';
import '../../services/save_export_service.dart';
import '../../services/user_service.dart';
import '../services/medical_dictation_service.dart';
import '../widgets/floating_voice_button.dart';

class PDFPreviewScreen extends StatefulWidget {
  final Patient patient;
  final List<Marker> markers;
  final Uint8List? canvasImage;
  final int? visitId;

  const PDFPreviewScreen({
    super.key,
    required this.patient,
    required this.markers,
    required this.canvasImage,
    this.visitId,
  });

  @override
  State<PDFPreviewScreen> createState() => _PDFPreviewScreenState();
}

class _PDFPreviewScreenState extends State<PDFPreviewScreen> {
  late TextEditingController _doctorNameController;
  late TextEditingController _clinicNameController;
  late TextEditingController _diagnosisController;
  late TextEditingController _treatmentController;
  late TextEditingController _followUpController;

  List<Prescription> _prescriptions = [];
  bool _loadingPrescriptions = true;

  List<LabTest> _labTests = [];
  bool _loadingLabTests = true;

  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _doctorNameController = TextEditingController(
        text: UserService.currentUser?.name ?? 'Dr. Smith'
    );
    _clinicNameController = TextEditingController(
        text: UserService.currentUser?.specialty ?? 'Clinic Clarity Suite'
    );
    _diagnosisController = TextEditingController();
    _treatmentController = TextEditingController();
    _followUpController = TextEditingController();

    _loadPrescriptions();
    _loadLabTests();
    _loadVisitNotes();
    FloatingVoiceButtonState.registerDictationCallback(_handleVoiceDictation);

  }

  Future<void> _loadVisitNotes() async {
    if (widget.visitId != null) {
      try {
        final db = DatabaseHelper.instance;
        final result = await db.database;
        final maps = await result.query(
          'visits',
          where: 'id = ?',
          whereArgs: [widget.visitId],
        );

        if (maps.isNotEmpty) {
          final notes = maps.first['notes'] as String?;
          if (notes != null && notes.isNotEmpty) {
            final parsed = jsonDecode(notes);
            setState(() {
              _diagnosisController.text = parsed['diagnosis'] ?? '';
              _treatmentController.text = parsed['treatment'] ?? '';
              _followUpController.text = parsed['followUp'] ?? '';
            });
          }
        }
      } catch (e) {
        // Silent error - notes not critical
      }
    }
  }

  Future<void> _loadPrescriptions() async {
    if (widget.visitId != null) {
      try {
        final prescriptions = await DatabaseHelper.instance
            .getPrescriptionsByVisit(widget.visitId!);
        setState(() {
          _prescriptions = prescriptions;
          _loadingPrescriptions = false;
        });
      } catch (e) {
        setState(() {
          _loadingPrescriptions = false;
        });
      }
    } else {
      setState(() {
        _loadingPrescriptions = false;
      });
    }
  }

  Future<void> _loadLabTests() async {
    if (widget.visitId != null) {
      try {
        final labTests = await DatabaseHelper.instance.getLabTestsByVisit(widget.visitId!);
        setState(() {
          _labTests = labTests;
          _loadingLabTests = false;
        });
      } catch (e) {
        setState(() {
          _loadingLabTests = false;
        });
      }
    } else {
      setState(() {
        _loadingLabTests = false;
      });
    }
  }

  Future<void> _saveClinicalNotes() async {
    if (widget.visitId == null) return;

    try {
      final notes = jsonEncode({
        'diagnosis': _diagnosisController.text,
        'treatment': _treatmentController.text,
        'followUp': _followUpController.text,
      });

      final db = DatabaseHelper.instance;
      final result = await db.database;
      await result.update(
        'visits',
        {'notes': notes},
        where: 'id = ?',
        whereArgs: [widget.visitId],
      );
    } catch (e) {
      // Silent error - auto-save is not critical
    }
  }

  void _scheduleAutoSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveClinicalNotes);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Review & Generate Summary'),
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
                      title: 'Clinic Information',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _clinicNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Clinic Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _doctorNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Doctor Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      title: 'Patient Information',
                      child: Column(
                        children: [
                          _buildReadOnlyRow('Name:', widget.patient.name),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildReadOnlyRow('Age:', '${widget.patient.age} years')),
                              Expanded(child: _buildReadOnlyRow('Phone:', widget.patient.phone)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildReadOnlyRow('Patient ID:', widget.patient.id)),
                              Expanded(child: _buildReadOnlyRow('Date:', widget.patient.date)),
                            ],
                          ),
                          if (widget.patient.vitals != null) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            const Text(
                              'Vitals & Measurements',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildReadOnlyRow('BP:', '${widget.patient.vitals!.bpSystolic}/${widget.patient.vitals!.bpDiastolic} mmHg')),
                                Expanded(child: _buildReadOnlyRow('Pulse:', '${widget.patient.vitals!.pulse} bpm')),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildReadOnlyRow('Temp:', '${widget.patient.vitals!.temperature}°F')),
                                Expanded(child: _buildReadOnlyRow('SpO2:', '${widget.patient.vitals!.spo2}%')),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildReadOnlyRow('Height:', '${widget.patient.vitals!.height} cm')),
                                Expanded(child: _buildReadOnlyRow('Weight:', '${widget.patient.vitals!.weight} kg')),
                              ],
                            ),
                            if (widget.patient.vitals!.fbs != null || widget.patient.vitals!.ppbs != null || widget.patient.vitals!.hba1c != null) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Blood Sugar',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (widget.patient.vitals!.fbs != null)
                                    Expanded(child: _buildReadOnlyRow('FBS:', '${widget.patient.vitals!.fbs} mg/dL')),
                                  if (widget.patient.vitals!.ppbs != null)
                                    Expanded(child: _buildReadOnlyRow('PPBS:', '${widget.patient.vitals!.ppbs} mg/dL')),
                                ],
                              ),
                              if (widget.patient.vitals!.hba1c != null) ...[
                                const SizedBox(height: 8),
                                _buildReadOnlyRow('HbA1c:', '${widget.patient.vitals!.hba1c}%'),
                              ],
                            ],
                          ],
                          if (widget.patient.conditions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.patient.conditions.map((condition) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCEAFE),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      condition,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF1E40AF),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      title: 'Diagnosis',
                      child: TextField(
                        controller: _diagnosisController,
                        maxLines: 3,
                        onChanged: (_) => _scheduleAutoSave(),
                        decoration: InputDecoration(
                          hintText: 'Enter diagnosis based on findings...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      title: 'Treatment Plan',
                      child: TextField(
                        controller: _treatmentController,
                        maxLines: 4,
                        onChanged: (_) => _scheduleAutoSave(),
                        decoration: InputDecoration(
                          hintText: 'Medications, procedures, lifestyle changes...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      title: 'Follow-up Instructions',
                      child: TextField(
                        controller: _followUpController,
                        maxLines: 3,
                        onChanged: (_) => _scheduleAutoSave(),
                        decoration: InputDecoration(
                          hintText: 'Next appointment, tests to be done, precautions...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_loadingPrescriptions)
                      _buildSection(
                        title: 'Prescriptions',
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    else if (_prescriptions.isNotEmpty)
                      _buildSection(
                        title: 'Prescriptions (${_prescriptions.length} medications)',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _prescriptions.map((prescription) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.medication, size: 18, color: Colors.teal.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          prescription.medicationName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Dosage: ${prescription.dosage} | ${prescription.frequency} | ${prescription.duration}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                  if (prescription.instructions != null && prescription.instructions!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Instructions: ${prescription.instructions}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // LAB TESTS SECTION
                    if (_loadingLabTests)
                      _buildSection(
                        title: 'Lab Tests',
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    else if (_labTests.isNotEmpty)
                      _buildSection(
                        title: 'Lab Tests (${_labTests.length} tests)',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _labTests.map((test) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.cyan.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.cyan.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.science, size: 18, color: Colors.cyan.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          test.testName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Result: ${test.resultValue ?? "Pending"} ${test.resultUnit ?? ""}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                  Text(
                                    'Normal Range: ${test.normalRangeDisplay}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    if (widget.markers.isNotEmpty)
                      _buildSection(
                        title: 'Findings (${widget.markers.length} markers)',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.markers.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final marker = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _getMarkerColor(marker.type),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$index',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${marker.type.toUpperCase()}: ${marker.label.isNotEmpty ? marker.label : "No label"}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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
                      border: Border(
                        bottom: BorderSide(color: Colors.blue.shade200),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.description,
                          size: 48,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Summary Preview',
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
                          const Text(
                            'The PDF will include:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryItem(Icons.person, 'Patient Demographics'),
                          _buildSummaryItem(Icons.medical_services, 'Preexisting Conditions'),
                          _buildSummaryItem(Icons.favorite, 'Vitals & Measurements'),
                          _buildSummaryItem(Icons.image, 'Annotated Kidney Diagram'),
                          _buildSummaryItem(Icons.description, 'Clinical Findings'),
                          if (_prescriptions.isNotEmpty)
                            _buildSummaryItem(
                              Icons.medication,
                              'Prescriptions (${_prescriptions.length})',
                              color: Colors.teal,
                            ),
                          if (_labTests.isNotEmpty)
                            _buildSummaryItem(
                              Icons.science,
                              'Lab Tests (${_labTests.length})',
                              color: Colors.cyan,
                            ),
                          _buildSummaryItem(Icons.healing, 'Diagnosis & Treatment'),
                          _buildSummaryItem(Icons.calendar_today, 'Follow-up Instructions'),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade700),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Notes auto-save as you type',
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
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _saveClinicalNotes();
                            _generatePDF();
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('Generate PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _sharePDF,
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
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

  Widget _buildReadOnlyRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
        ],
      ),
    );
  }

  Color _getMarkerColor(String type) {
    switch (type) {
      case 'calculi':
        return Colors.grey;
      case 'cyst':
        return const Color(0xFF2563EB);
      case 'tumor':
        return const Color(0xFF7C2D12);
      case 'inflammation':
        return const Color(0xFFEA580C);
      case 'blockage':
        return const Color(0xFF9333EA);
      default:
        return Colors.grey;
    }
  }

  Future<void> _generatePDF() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfBytes = await PDFGenerationService.generatePDFBytes(
        patient: widget.patient,
        markers: widget.markers,
        canvasImage: widget.canvasImage,
        prescriptions: _prescriptions.isEmpty ? null : _prescriptions,
        labTests: _labTests.isEmpty ? null : _labTests,
        doctorName: _doctorNameController.text,
        clinicName: _clinicNameController.text,
        diagnosis: _diagnosisController.text.isEmpty ? null : _diagnosisController.text,
        treatment: _treatmentController.text.isEmpty ? null : _treatmentController.text,
        followUp: _followUpController.text.isEmpty ? null : _followUpController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFZoomViewer(pdfBytes: pdfBytes),
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF Generation Failed'),
            content: Text('Could not generate PDF.\n\nError: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _sharePDF() async {
    await _saveClinicalNotes();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await SaveExportService.shareGeneral(
        patient: widget.patient,
        markers: widget.markers,
        canvasImage: widget.canvasImage,
        prescriptions: _prescriptions.isEmpty ? null : _prescriptions,
        labTests: _labTests.isEmpty ? null : _labTests,
        doctorName: _doctorNameController.text,
        clinicName: _clinicNameController.text,
        diagnosis: _diagnosisController.text.isEmpty ? null : _diagnosisController.text,
        treatment: _treatmentController.text.isEmpty ? null : _treatmentController.text,
        followUp: _followUpController.text.isEmpty ? null : _followUpController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Opening share options...' : 'Failed to share'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on SaveExportException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share Failed'),
            content: Text(e.userMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    FloatingVoiceButtonState.registerDictationCallback(null);
    _saveTimer?.cancel();
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  void _handleVoiceDictation(DictationResult result) {
    setState(() {
      switch (result.type) {
        case DictationType.diagnosis:
          final diagnosis = result.data['diagnosis'] ?? '';
          if (_diagnosisController.text.isEmpty) {
            _diagnosisController.text = diagnosis;
          } else {
            _diagnosisController.text += '\n' + diagnosis;
          }
          _scheduleSave();
          break;

        case DictationType.treatment:
          final treatment = result.data['treatment'] ?? '';
          if (_treatmentController.text.isEmpty) {
            _treatmentController.text = treatment;
          } else {
            _treatmentController.text += '\n' + treatment;
          }
          _scheduleSave();
          break;

        case DictationType.notes:
          final notes = result.data['notes'] ?? '';
          if (_followUpController.text.isEmpty) {
            _followUpController.text = notes;
          } else {
            _followUpController.text += '\n' + notes;
          }
          _scheduleSave();
          break;

        case DictationType.prescription:
        // Navigate to prescription screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💡 Please add prescriptions from the main screen'),
              duration: Duration(seconds: 2),
            ),
          );
          break;

        case DictationType.labTest:
        // Navigate to lab test screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💡 Please add lab tests from the main screen'),
              duration: Duration(seconds: 2),
            ),
          );
          break;

        default:
          break;
      }
    });
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _saveClinicalNotes();
    });
  }


}

class PDFZoomViewer extends StatefulWidget {
  final Uint8List pdfBytes;

  const PDFZoomViewer({super.key, required this.pdfBytes});

  @override
  State<PDFZoomViewer> createState() => _PDFZoomViewerState();
}

class _PDFZoomViewerState extends State<PDFZoomViewer> {
  int? _zoomedPageIndex;

  @override
  Widget build(BuildContext context) {
    if (_zoomedPageIndex != null) {
      return _buildZoomedPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview - 3 Pages'),
        backgroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapX = details.globalPosition.dx;

          if (tapX < screenWidth / 3) {
            setState(() => _zoomedPageIndex = 0);
          } else if (tapX < (screenWidth * 2 / 3)) {
            setState(() => _zoomedPageIndex = 1);
          } else {
            setState(() => _zoomedPageIndex = 2);
          }
        },
        child: Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Page 1 - Patient Info',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PdfPreview(
                        build: (format) => widget.pdfBytes,
                        pages: const [0],
                        canChangeOrientation: false,
                        canDebug: false,
                        allowSharing: false,
                        allowPrinting: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        border: Border(bottom: BorderSide(color: Colors.purple.shade200)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 16, color: Colors.purple.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Page 2 - Diagram',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PdfPreview(
                        build: (format) => widget.pdfBytes,
                        pages: const [1],
                        canChangeOrientation: false,
                        canDebug: false,
                        allowSharing: false,
                        allowPrinting: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border(bottom: BorderSide(color: Colors.green.shade200)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Page 3 - Summary',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PdfPreview(
                        build: (format) => widget.pdfBytes,
                        pages: const [2],
                        canChangeOrientation: false,
                        canDebug: false,
                        allowSharing: false,
                        allowPrinting: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'Tap any page to zoom in',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomedPage() {
    final pageTitles = [
      'Page 1 - Patient Info & Vitals',
      'Page 2 - Medical Diagram',
      'Page 3 - Clinical Summary',
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(pageTitles[_zoomedPageIndex!]),
        actions: [
          IconButton(
            onPressed: () => setState(() => _zoomedPageIndex = null),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: PdfPreview(
            build: (format) => widget.pdfBytes,
            pages: [_zoomedPageIndex!],
            canChangeOrientation: false,
            canDebug: false,
            allowSharing: false,
            allowPrinting: false,
          ),
        ),
      ),
    );
  }
}