import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/patient.dart';
import '../models/marker.dart';
import '../models/prescription.dart';
import '../models/lab_test.dart';  // ADD THIS
import '../services/user_service.dart';

class PDFGenerationService {
  static Future<void> generatePatientSummary({
    required Patient patient,
    required List<Marker> markers,
    required Uint8List? canvasImage,
    List<Prescription>? prescriptions,
    List<LabTest>? labTests,  // ADD THIS
    String? doctorName,
    String? clinicName,
    String? diagnosis,
    String? treatment,
    String? followUp,
  }) async {
    final pdfBytes = await generatePDFBytes(
      patient: patient,
      markers: markers,
      canvasImage: canvasImage,
      prescriptions: prescriptions,
      labTests: labTests,  // ADD THIS
      doctorName: doctorName,
      clinicName: clinicName,
      diagnosis: diagnosis,
      treatment: treatment,
      followUp: followUp,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Patient_Summary_${patient.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<Uint8List> generatePDFBytes({
    required Patient patient,
    required List<Marker> markers,
    required Uint8List? canvasImage,
    List<Prescription>? prescriptions,
    List<LabTest>? labTests,  // ADD THIS
    String? doctorName,
    String? clinicName,
    String? diagnosis,
    String? treatment,
    String? followUp,
  }) async {
    final pdf = pw.Document();

    // ==================== PAGE 1: PATIENT INFO & VITALS ====================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(clinicName ?? 'Clinic Clarity Suite'),
              pw.SizedBox(height: 30),
              _buildSectionTitle('Patient Information'),
              pw.SizedBox(height: 15),
              _buildPatientInfo(patient),
              pw.SizedBox(height: 25),
              if (patient.conditions.isNotEmpty) ...[
                _buildSectionTitle('Preexisting Conditions'),
                pw.SizedBox(height: 10),
                _buildConditionsList(patient.conditions),
                pw.SizedBox(height: 25),
              ],
              _buildSectionTitle('Vitals & Measurements'),
              pw.SizedBox(height: 10),
              _buildVitalsSection(patient),
              pw.SizedBox(height: 25),
              if (patient.notes != null && patient.notes!.isNotEmpty) ...[
                _buildSectionTitle('Clinical History'),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    patient.notes!,
                    style: const pw.TextStyle(fontSize: 11),
                    maxLines: 10,
                  ),
                ),
              ],
              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated: ${DateTime.now().toString().split(' ')[0]}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page 1 of 3',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // ==================== PAGE 2: DIAGRAM & FINDINGS ====================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(clinicName ?? 'Clinic Clarity Suite'),
              pw.SizedBox(height: 30),
              _buildSectionTitle('Medical Diagram - Kidney Annotation'),
              pw.SizedBox(height: 15),
              if (canvasImage != null)
                pw.Container(
                  height: 280,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(canvasImage),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                )
              else
                pw.Container(
                  height: 280,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No diagram available',
                      style: pw.TextStyle(color: PdfColors.grey),
                    ),
                  ),
                ),
              pw.SizedBox(height: 20),
              if (markers.isNotEmpty) ...[
                _buildSectionTitle('Findings & Annotations'),
                pw.SizedBox(height: 10),
                _buildMarkersList(markers),
              ],
              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Patient: ${patient.name}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page 2 of 3',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // ==================== PAGE 3: CLINICAL SUMMARY ====================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(clinicName ?? 'Clinic Clarity Suite'),
              pw.SizedBox(height: 30),
              _buildSectionTitle('Clinical Summary'),
              pw.SizedBox(height: 20),

              // DIAGNOSIS
              if (diagnosis != null && diagnosis.isNotEmpty) ...[
                pw.Text(
                  'Diagnosis',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFEF3C7),
                    border: pw.Border.all(color: PdfColor.fromInt(0xFFF59E0B)),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    diagnosis,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // PRESCRIPTIONS
              if (prescriptions != null && prescriptions.isNotEmpty) ...[
                pw.Text(
                  'Prescriptions',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildPrescriptionsTable(prescriptions),
                pw.SizedBox(height: 20),
              ],
// LAB TESTS
              if (labTests != null && labTests.isNotEmpty) ...[
                pw.Text(
                  'Lab Tests',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildLabTestsTable(labTests),
                pw.SizedBox(height: 20),
              ],

              // TREATMENT PLAN
              if (treatment != null && treatment.isNotEmpty) ...[
                pw.Text(
                  'Treatment Plan',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    treatment,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // FOLLOW-UP INSTRUCTIONS
              if (followUp != null && followUp.isNotEmpty) ...[
                pw.Text(
                  'Follow-up Instructions',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFDCFCE7),
                    border: pw.Border.all(color: PdfColor.fromInt(0xFF10B981)),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    followUp,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ],

              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 15),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Doctor: ${doctorName ?? UserService.currentUser?.name ?? 'Dr. Smith'}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Signature',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Page 3 of 3',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ==================== HELPER METHODS ====================
  static pw.Widget _buildLabTestsTable(List<LabTest> labTests) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFDCEAFE),
          ),
          children: [
            _buildTableHeader('Test Name'),
            _buildTableHeader('Result'),
            _buildTableHeader('Normal Range'),
            _buildTableHeader('Status'),
          ],
        ),
        // Data
        ...labTests.map((test) => pw.TableRow(
          decoration: test.isAbnormal
              ? pw.BoxDecoration(color: PdfColor.fromInt(0xFFFEE2E2))
              : null,
          children: [
            _buildTableCell(test.testName),
            _buildTableCell(
              test.resultValue != null
                  ? '${test.resultValue} ${test.resultUnit ?? ""}'
                  : 'Pending',
            ),
            _buildTableCell(test.normalRangeDisplay),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: test.isAbnormal
                      ? PdfColor.fromInt(0xFFDC2626)
                      : test.status.toString().contains('completed')
                      ? PdfColor.fromInt(0xFF10B981)
                      : PdfColor.fromInt(0xFFF59E0B),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  test.isAbnormal
                      ? 'ABNORMAL'
                      : test.status.toString().split('.').last.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ],
        )),
      ],
    );
  }
  static pw.Widget _buildHeader(String clinicName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            PdfColor.fromInt(0xFF3B82F6),
            PdfColor.fromInt(0xFF1E40AF),
          ],
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                clinicName,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Patient Medical Summary',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xE6FFFFFF),
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0x33FFFFFF),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Icon(
              pw.IconData(0xe0f0),
              size: 30,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF3B82F6), width: 2),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF1E293B),
        ),
      ),
    );
  }

  static pw.Widget _buildPatientInfo(Patient patient) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildInfoRow('Patient Name:', patient.name),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildInfoRow('Patient ID:', patient.id)),
              pw.Expanded(child: _buildInfoRow('Age:', '${patient.age} years')),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildInfoRow('Phone:', patient.phone)),
              pw.Expanded(child: _buildInfoRow('Date:', patient.date)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildConditionsList(List<String> conditions) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: conditions.map((condition) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFDCEAFE),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            condition,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromInt(0xFF1E40AF),
            ),
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildVitalsSection(Patient patient) {
    if (patient.vitals == null) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          'No vitals recorded',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
        ),
      );
    }

    final v = patient.vitals!;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          // Row 1: BP and Pulse
          pw.Row(
            children: [
              if (v.bpSystolic != null && v.bpDiastolic != null)
                pw.Expanded(
                  child: _buildVitalItem('Blood Pressure', '${v.bpSystolic}/${v.bpDiastolic} mmHg'),
                ),
              if (v.pulse != null)
                pw.Expanded(
                  child: _buildVitalItem('Pulse', '${v.pulse} bpm'),
                ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Row 2: Temperature and SpO2
          pw.Row(
            children: [
              if (v.temperature != null)
                pw.Expanded(
                  child: _buildVitalItem('Temperature', '${v.temperature}°F'),
                ),
              if (v.spo2 != null)
                pw.Expanded(
                  child: _buildVitalItem('SpO2', '${v.spo2}%'),
                ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Row 3: Height, Weight, BMI
          pw.Row(
            children: [
              if (v.height != null)
                pw.Expanded(
                  child: _buildVitalItem('Height', '${v.height} cm'),
                ),
              if (v.weight != null)
                pw.Expanded(
                  child: _buildVitalItem('Weight', '${v.weight} kg'),
                ),
              if (v.bmi != null)
                pw.Expanded(
                  child: _buildVitalItem('BMI', v.bmi!.toStringAsFixed(1)),
                ),
            ],
          ),

          // Blood Sugar (if any values exist)
          if (v.fbs != null || v.ppbs != null || v.hba1c != null) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Blood Sugar Levels',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      if (v.fbs != null)
                        pw.Expanded(
                          child: _buildVitalItem('FBS', '${v.fbs} mg/dL'),
                        ),
                      if (v.ppbs != null)
                        pw.Expanded(
                          child: _buildVitalItem('PPBS', '${v.ppbs} mg/dL'),
                        ),
                      if (v.hba1c != null)
                        pw.Expanded(
                          child: _buildVitalItem('HbA1c', '${v.hba1c}%'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildVitalItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMarkersList(List<Marker> markers) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: markers.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final marker = entry.value;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 20,
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: _pdfColorFromMarker(marker.type),
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '$index',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    '${marker.type.toUpperCase()}: ${marker.label.isNotEmpty ? marker.label : "No label"}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildPrescriptionsTable(List<Prescription> prescriptions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFDCEAFE),
          ),
          children: [
            _buildTableHeader('Medication'),
            _buildTableHeader('Dosage'),
            _buildTableHeader('Frequency'),
            _buildTableHeader('Duration'),
          ],
        ),
        // Data rows
        ...prescriptions.map((prescription) => pw.TableRow(
          children: [
            _buildTableCell(prescription.medicationName),
            _buildTableCell(prescription.dosage),
            _buildTableCell(prescription.frequency),
            _buildTableCell(prescription.duration),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
          color: PdfColor.fromInt(0xFF1E40AF),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static PdfColor _pdfColorFromMarker(String type) {
    switch (type) {
      case 'calculi':
        return PdfColors.grey;
      case 'cyst':
        return PdfColor.fromInt(0xFF2563EB);
      case 'tumor':
        return PdfColor.fromInt(0xFF7C2D12);
      case 'inflammation':
        return PdfColor.fromInt(0xFFEA580C);
      case 'blockage':
        return PdfColor.fromInt(0xFF9333EA);
      default:
        return PdfColors.grey;
    }
  }
}