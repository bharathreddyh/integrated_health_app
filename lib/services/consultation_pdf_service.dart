// lib/services/consultation_pdf_service.dart
// ✅ FIXED VERSION - Updated for Page 2 Integration

import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/consultation_data.dart';
import '../models/disease_template.dart';
import '../services/database_helper.dart';

class ConsultationPDFService {
  static Future<void> generateConsultationPDF(
      ConsultationData data,
      String outputPath,
      ) async {
    final pdf = pw.Document();

    // ==================== PAGE 1: PATIENT DATA ====================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('Page 1 - Patient Info', PdfColors.blue),
            pw.SizedBox(height: 20),

            // Patient Information
            _buildSection('PATIENT INFORMATION', [
              _buildInfoRow('Name', data.patient.name),
              _buildInfoRow('Age', '${data.patient.age} years'),
              _buildInfoRow('Phone', data.patient.phone),
              _buildInfoRow('Date', data.patient.date),
            ]),

            pw.SizedBox(height: 15),

            // Clinical History
            _buildSection('CLINICAL HISTORY', [
              _buildInfoRow('Chief Complaint', data.chiefComplaint),
              if (data.historyOfPresentIllness.isNotEmpty)
                _buildInfoRow('History of Present Illness', data.historyOfPresentIllness),
              if (data.pastMedicalHistory.isNotEmpty)
                _buildInfoRow('Past Medical History', data.pastMedicalHistory),
              if (data.familyHistory.isNotEmpty)
                _buildInfoRow('Family History', data.familyHistory),
              if (data.allergies.isNotEmpty)
                _buildInfoRow('Allergies', data.allergies),
            ]),

            pw.SizedBox(height: 15),

            // Vital Signs
            if (data.vitals.isNotEmpty)
              _buildSection('VITAL SIGNS',
                  data.vitals.entries.map((e) =>
                      _buildInfoRow(_formatVitalName(e.key), e.value)
                  ).toList()
              ),

            pw.SizedBox(height: 15),

            // Measurements
            if (data.height != null || data.weight != null)
              _buildSection('MEASUREMENTS', [
                if (data.height != null && data.height!.isNotEmpty)
                  _buildInfoRow('Height', '${data.height} cm'),
                if (data.weight != null && data.weight!.isNotEmpty)
                  _buildInfoRow('Weight', '${data.weight} kg'),
                if (data.bmi != null)
                  _buildInfoRow('BMI', data.bmi!),
              ]),

            pw.Spacer(),
            _buildPageFooter(1, 3),
          ],
        ),
      ),
    );

    // ==================== PAGE 2: VISUAL CONTENT ====================
    // ✅ UPDATED: Check for completed templates and annotated anatomies
    final hasVisualContent = data.selectedDiagramIds.isNotEmpty ||
        data.completedTemplates.isNotEmpty ||
        data.annotatedAnatomies.isNotEmpty;

    if (hasVisualContent) {
      // ✅ FIXED: Load actual diagram images from database
      List<pw.Widget> diagramImages = [];

      // Load saved diagrams
      if (data.selectedDiagramIds.isNotEmpty) {
        for (var diagramId in data.selectedDiagramIds) {
          try {
            final visit = await DatabaseHelper.instance.getVisitById(diagramId); // ✅ FIXED: Already int
            if (visit != null && visit.canvasImage != null) {
              diagramImages.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${visit.system} - ${visit.diagramType}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        height: 200,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(
                            pw.MemoryImage(visit.canvasImage!),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          } catch (e) {
            print('Error loading diagram $diagramId: $e');
          }
        }
      }

      // ✅ NEW: Load annotated anatomies
      if (data.annotatedAnatomies.isNotEmpty) {
        for (var anatomy in data.annotatedAnatomies) {
          try {
            final visitId = anatomy['visitId'] as int?;
            if (visitId != null) {
              final visit = await DatabaseHelper.instance.getVisitById(visitId);
              if (visit != null && visit.canvasImage != null) {
                diagramImages.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 15),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${anatomy['systemName']} - ${anatomy['viewType']}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Container(
                          height: 200,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.ClipRRect(
                            horizontalRadius: 8,
                            verticalRadius: 8,
                            child: pw.Image(
                              pw.MemoryImage(visit.canvasImage!),
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            print('Error loading anatomy: $e');
          }
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPageHeader('Page 2 - Visual Content', PdfColors.purple),
              pw.SizedBox(height: 20),

              // ✅ Show actual diagram images (saved + annotated)
              if (diagramImages.isNotEmpty) ...[
                _buildSectionTitle('ANNOTATED DIAGRAMS'),
                pw.SizedBox(height: 10),
                ...diagramImages,
                pw.SizedBox(height: 15),
              ],

              // ✅ NEW: Completed Disease Templates
              if (data.completedTemplates.isNotEmpty) ...[
                _buildSectionTitle('COMPLETED DISEASE TEMPLATES'),
                pw.SizedBox(height: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: data.completedTemplates.map((template) {
                    final templateName = template['templateName'] ?? 'Unknown Template';
                    final templateData = template['data'] as Map<String, dynamic>? ?? {};

                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 12),
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.purple50,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.purple200),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            templateName,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.purple900,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          // Display template data
                          ...templateData.entries.map((entry) {
                            if (entry.value != null && entry.value.toString().isNotEmpty) {
                              return pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 3),
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Container(
                                      width: 120,
                                      child: pw.Text(
                                        '${entry.key}:',
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    pw.Expanded(
                                      child: pw.Text(
                                        entry.value.toString(),
                                        style: const pw.TextStyle(fontSize: 9),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return pw.SizedBox();
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 15),
              ],

              pw.Spacer(),
              _buildPageFooter(2, 3),
            ],
          ),
        ),
      );
    }

    // ==================== PAGE 3: DIAGNOSIS & TREATMENT ====================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader('Page 3 - Clinical Summary', PdfColors.green),
            pw.SizedBox(height: 20),

            // Diagnosis
            _buildSection('DIAGNOSIS', [
              pw.Text(
                data.diagnosis.isNotEmpty ? data.diagnosis : 'Not specified',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ]),

            pw.SizedBox(height: 15),

            // Lab Tests Ordered
            if (data.orderedLabTests.isNotEmpty) ...[
              _buildSectionTitle('LAB TESTS ORDERED'),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.purple100),
                    children: [
                      _buildTableCell('Test Name', bold: true),
                      _buildTableCell('Category', bold: true),
                      _buildTableCell('Priority', bold: true),
                    ],
                  ),
                  // Data rows
                  ...data.orderedLabTests.map((testMap) {
                    final isUrgent = testMap['isUrgent'] as bool? ?? false;
                    return pw.TableRow(
                      decoration: isUrgent
                          ? const pw.BoxDecoration(color: PdfColors.red50)
                          : null,
                      children: [
                        _buildTableCell(testMap['name'] as String),
                        _buildTableCell(testMap['category'] as String),
                        _buildTableCell(isUrgent ? 'URGENT' : 'Routine'),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 15),
            ],

            // Investigations Ordered
            if (data.orderedInvestigations.isNotEmpty) ...[
              _buildSectionTitle('INVESTIGATIONS ORDERED'),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      _buildTableCell('Investigation', bold: true),
                      _buildTableCell('Category', bold: true),
                      _buildTableCell('Priority', bold: true),
                    ],
                  ),
                  // Data rows
                  ...data.orderedInvestigations.map((invMap) {
                    final isUrgent = invMap['isUrgent'] as bool? ?? false;
                    return pw.TableRow(
                      decoration: isUrgent
                          ? const pw.BoxDecoration(color: PdfColors.red50)
                          : null,
                      children: [
                        _buildTableCell(invMap['name'] as String),
                        _buildTableCell(invMap['category'] as String),
                        _buildTableCell(isUrgent ? 'URGENT' : 'Routine'),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 15),
            ],

            // Medications
            if (data.prescriptions.isNotEmpty) ...[
              _buildSectionTitle('MEDICATIONS'),
              pw.SizedBox(height: 10),
              ...data.prescriptions.map((rx) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '• ${rx.medicationName}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '  ${rx.dosage} • ${rx.frequency} • ${rx.duration}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                    if (rx.instructions?.isNotEmpty ?? false) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '  Instructions: ${rx.instructions}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ],
                ),
              )),
              pw.SizedBox(height: 15),
            ],

            // Diet Plan
            if (data.dietPlan.isNotEmpty) ...[
              _buildSectionTitle('DIET PLAN'),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  data.dietPlan,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 15),
            ],

            // Lifestyle Modifications
            if (data.lifestylePlan.isNotEmpty) ...[
              _buildSectionTitle('LIFESTYLE MODIFICATIONS'),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  data.lifestylePlan,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],

            pw.Spacer(),
            _buildPageFooter(hasVisualContent ? 3 : 2, hasVisualContent ? 3 : 2),
          ],
        ),
      ),
    );

    // Save PDF
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
  }

  // ==================== HELPER METHODS ====================

  static String _formatVitalName(String key) {
    final Map<String, String> nameMap = {
      'bloodPressure': 'Blood Pressure',
      'heartRate': 'Heart Rate',
      'temperature': 'Temperature',
      'spo2': 'SpO₂',
      'respiratoryRate': 'Respiratory Rate',
    };
    return nameMap[key] ?? key;
  }

  static pw.Widget _buildPageHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildSection(String title, List<pw.Widget> content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: content,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue900,
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 140,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isNotEmpty ? value : 'Not specified',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildPageFooter(int currentPage, int totalPages) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated: ${DateTime.now().toString().split(' ')[0]}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page $currentPage of $totalPages',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}