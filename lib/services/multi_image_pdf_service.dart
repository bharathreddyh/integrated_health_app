// lib/services/multi_image_pdf_service.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/patient.dart';
import '../models/visit.dart';

class MultiImagePDFService {
  /// Generate PDF with multiple canvas images (max 4 images, no clinical details)
  static Future<void> generateDiagramsPDF({
    required Patient patient,
    required List<Visit> selectedVisits,
  }) async {
    if (selectedVisits.isEmpty) {
      throw Exception('No diagrams selected');
    }

    if (selectedVisits.length > 4) {
      throw Exception('Maximum 4 diagrams allowed per export');
    }

    final pdfBytes = await _generatePDFBytes(
      patient: patient,
      visits: selectedVisits,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Diagrams_${patient.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<Uint8List> _generatePDFBytes({
    required Patient patient,
    required List<Visit> visits,
  }) async {
    final pdf = pw.Document();

    // Determine layout: 1-2 images = 1 per page, 3-4 images = 2 per page
    if (visits.length <= 2) {
      // One image per page
      for (final visit in visits) {
        pdf.addPage(_buildSingleImagePage(patient, visit));
      }
    } else {
      // Two images per page (for 3-4 images)
      for (int i = 0; i < visits.length; i += 2) {
        final visit1 = visits[i];
        final visit2 = i + 1 < visits.length ? visits[i + 1] : null;
        pdf.addPage(_buildDoubleImagePage(patient, visit1, visit2));
      }
    }

    return pdf.save();
  }

  static pw.Page _buildSingleImagePage(Patient patient, Visit visit) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPatientHeader(patient),
            pw.SizedBox(height: 30),
            _buildImageSection(visit, isFullPage: true),
            pw.Spacer(),
            _buildFooter(patient, visit),
          ],
        );
      },
    );
  }

  static pw.Page _buildDoubleImagePage(Patient patient, Visit visit1, Visit? visit2) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPatientHeader(patient),
            pw.SizedBox(height: 20),

            // First image
            _buildImageSection(visit1, isFullPage: false),

            if (visit2 != null) ...[
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // Second image
              _buildImageSection(visit2, isFullPage: false),
            ],

            pw.Spacer(),
            _buildFooter(patient, visit1),
          ],
        );
      },
    );
  }

  static pw.Widget _buildPatientHeader(Patient patient) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
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
                'Medical Diagrams',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Patient: ${patient.name}',
                style: pw.TextStyle(
                  fontSize: 13,
                  color: PdfColor.fromInt(0xE6FFFFFF),
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'ID: ${patient.id}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xE6FFFFFF),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Age: ${patient.age}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xE6FFFFFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildImageSection(Visit visit, {required bool isFullPage}) {
    final height = isFullPage ? 500.0 : 280.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Diagram info
        pw.Row(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF9333EA),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                visit.system.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              _getDiagramDisplayName(visit.diagramType),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1E293B),
              ),
            ),
            pw.Spacer(),
            pw.Text(
              _formatDateTime(visit.createdAt),
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),

        // Canvas image
        if (visit.canvasImage != null)
          pw.Container(
            height: height,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 8,
              verticalRadius: 8,
              child: pw.Image(
                pw.MemoryImage(visit.canvasImage!),
                fit: pw.BoxFit.contain,
              ),
            ),
          )
        else
          pw.Container(
            height: height,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              color: PdfColors.grey100,
            ),
            child: pw.Center(
              child: pw.Text(
                'No image available',
                style: pw.TextStyle(color: PdfColors.grey600),
              ),
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildFooter(Patient patient, Visit visit) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated: ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Canvas Tool Export',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} • ${hour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  static String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  static String _getDiagramDisplayName(String diagramType) {
    final displayNames = {
      // Kidney
      'anatomical': 'Detailed Anatomy',
      'simple': 'Simple Diagram',
      'crossSection': 'Cross-Section View',
      'nephron': 'Nephron',
      'polycystic': 'Polycystic Kidney Disease',
      'pyelonephritis': 'Pyelonephritis',
      'glomerulonephritis': 'Glomerulonephritis',

      // Cardiac
      'anterior': 'Anterior View',
      'posterior': 'Posterior View',
      'coronary': 'Coronary Arteries',
      'myocardial_infarction': 'Myocardial Infarction',

      // Add more as needed
    };
    return displayNames[diagramType] ?? diagramType.replaceAll('_', ' ').toUpperCase();
  }
}