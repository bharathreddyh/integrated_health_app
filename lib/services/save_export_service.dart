import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/patient.dart';
import '../models/marker.dart';
import '../models/prescription.dart';
import '../models/lab_test.dart';  // ADD THIS
import 'pdf_generation_service.dart';

class SaveExportException implements Exception {
  final String message;
  final String userMessage;

  SaveExportException(this.message, this.userMessage);

  @override
  String toString() => userMessage;
}

class SaveExportService {
  static Future<String?> savePDFToDevice({
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
    try {
      final pdfBytes = await PDFGenerationService.generatePDFBytes(
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

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Patient_${patient.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      return filePath;
    } on FileSystemException catch (e) {
      throw SaveExportException(
        e.toString(),
        'Storage permission denied. Please enable storage access in settings.',
      );
    } catch (e) {
      throw SaveExportException(
        e.toString(),
        'Failed to save PDF: ${e.toString()}',
      );
    }
  }

  static Future<bool> shareViaWhatsApp({
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
    try {
      final filePath = await savePDFToDevice(
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

      if (filePath == null) {
        throw SaveExportException('File save failed', 'Could not save PDF file');
      }

      final message = '''Hello ${patient.name},

Your medical summary from ${clinicName ?? 'Clinic Clarity Suite'} is attached.

Doctor: ${doctorName ?? 'Dr. Smith'}
Date: ${DateTime.now().toString().split(' ')[0]}

Please review and keep for your records.''';

      final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(whatsappUrl);

      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        // WhatsApp not available, continue with file share
        print('WhatsApp launch failed: $e');
      }

      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        text: message,
        subject: 'Medical Summary - ${patient.name}',
      );

      return true;
    } on SaveExportException {
      rethrow;
    } catch (e) {
      throw SaveExportException(
        e.toString(),
        'Failed to share via WhatsApp. Make sure WhatsApp is installed.',
      );
    }
  }

  static Future<bool> shareGeneral({
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
    try {
      final filePath = await savePDFToDevice(
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

      if (filePath == null) {
        throw SaveExportException('File save failed', 'Could not save PDF file');
      }

      final file = XFile(filePath);
      final message = 'Medical summary for ${patient.name} - ${DateTime.now().toString().split(' ')[0]}';

      await Share.shareXFiles(
        [file],
        text: message,
        subject: 'Patient Medical Summary - ${patient.name}',
      );

      return true;
    } on SaveExportException {
      rethrow;
    } catch (e) {
      throw SaveExportException(
        e.toString(),
        'Failed to share PDF: ${e.toString()}',
      );
    }
  }
}