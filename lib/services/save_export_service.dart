import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/patient.dart';
import '../models/marker.dart';
import '../models/prescription.dart';
import 'pdf_generation_service.dart';

class SaveExportService {
  /// Save PDF to device storage and return file path
  static Future<String?> savePDFToDevice({
    required Patient patient,
    required List<Marker> markers,
    required Uint8List? canvasImage,
    List<Prescription>? prescriptions,
    String? doctorName,
    String? clinicName,
    String? diagnosis,
    String? treatment,
    String? followUp,
  }) async {
    try {
      // Generate PDF bytes
      final pdfBytes = await PDFGenerationService.generatePDFBytes(
        patient: patient,
        markers: markers,
        canvasImage: canvasImage,
        prescriptions: prescriptions,
        doctorName: doctorName,
        clinicName: clinicName,
        diagnosis: diagnosis,
        treatment: treatment,
        followUp: followUp,
      );

      // Get directory to save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Patient_${patient.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';

      // Write PDF to file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      return filePath;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  /// Share PDF via WhatsApp
  static Future<bool> shareViaWhatsApp({
    required Patient patient,
    required List<Marker> markers,
    required Uint8List? canvasImage,
    List<Prescription>? prescriptions,
    String? doctorName,
    String? clinicName,
    String? diagnosis,
    String? treatment,
    String? followUp,
  }) async {
    try {
      // Save PDF to device first
      final filePath = await savePDFToDevice(
        patient: patient,
        markers: markers,
        canvasImage: canvasImage,
        prescriptions: prescriptions,
        doctorName: doctorName,
        clinicName: clinicName,
        diagnosis: diagnosis,
        treatment: treatment,
        followUp: followUp,
      );

      if (filePath == null) {
        return false;
      }

      // Create message text
      final message = '''Hello ${patient.name},

Your medical summary from ${clinicName ?? 'Clinic Clarity Suite'} is attached.

Doctor: ${doctorName ?? 'Dr. Smith'}
Date: ${DateTime.now().toString().split(' ')[0]}

Please review and keep for your records.''';

      // Try to open WhatsApp first
      final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(whatsappUrl);

      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          // Small delay to allow WhatsApp to open
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print('Could not launch WhatsApp: $e');
      }

      // Share the PDF file
      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        text: message,
        subject: 'Medical Summary - ${patient.name}',
      );

      return true;
    } catch (e) {
      print('Error sharing via WhatsApp: $e');
      return false;
    }
  }

  /// General share - opens share sheet (Email, Messages, etc.)
  static Future<bool> shareGeneral({
    required Patient patient,
    required List<Marker> markers,
    required Uint8List? canvasImage,
    List<Prescription>? prescriptions,
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
        doctorName: doctorName,
        clinicName: clinicName,
        diagnosis: diagnosis,
        treatment: treatment,
        followUp: followUp,
      );

      if (filePath == null) {
        return false;
      }

      final file = XFile(filePath);
      final message = 'Medical summary for ${patient.name} - ${DateTime.now().toString().split(' ')[0]}';

      await Share.shareXFiles(
        [file],
        text: message,
        subject: 'Patient Medical Summary - ${patient.name}',
      );

      return true;
    } catch (e) {
      print('Error sharing PDF: $e');
      return false;
    }
  }

  /// Share via Email with pre-filled subject and body
  static Future<bool> shareViaEmail({
    required Patient patient,
    required List<Marker> markers,
    required Uint8List? canvasImage,
    List<Prescription>? prescriptions,
    String? doctorName,
    String? clinicName,
    String? diagnosis,
    String? treatment,
    String? followUp,
    String? recipientEmail,
  }) async {
    try {
      final filePath = await savePDFToDevice(
        patient: patient,
        markers: markers,
        canvasImage: canvasImage,
        prescriptions: prescriptions,
        doctorName: doctorName,
        clinicName: clinicName,
        diagnosis: diagnosis,
        treatment: treatment,
        followUp: followUp,
      );

      if (filePath == null) {
        return false;
      }

      final subject = Uri.encodeComponent('Medical Summary - ${patient.name}');
      final body = Uri.encodeComponent('''Dear ${patient.name},

Please find attached your medical summary from your recent consultation.

Clinic: ${clinicName ?? 'Clinic Clarity Suite'}
Doctor: ${doctorName ?? 'Dr. Smith'}
Date: ${DateTime.now().toString().split(' ')[0]}

Best regards,
${doctorName ?? 'Dr. Smith'}''');

      final emailUrl = recipientEmail != null && recipientEmail.isNotEmpty
          ? 'mailto:$recipientEmail?subject=$subject&body=$body'
          : 'mailto:?subject=$subject&body=$body';

      final uri = Uri.parse(emailUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        // Small delay then share the file
        await Future.delayed(const Duration(milliseconds: 500));

        final file = XFile(filePath);
        await Share.shareXFiles([file]);

        return true;
      } else {
        // Fallback to general share
        return await shareGeneral(
          patient: patient,
          markers: markers,
          canvasImage: canvasImage,
          prescriptions: prescriptions,
          doctorName: doctorName,
          clinicName: clinicName,
          diagnosis: diagnosis,
          treatment: treatment,
          followUp: followUp,
        );
      }
    } catch (e) {
      print('Error sharing via email: $e');
      return false;
    }
  }
}