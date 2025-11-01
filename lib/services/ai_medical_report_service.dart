// lib/services/ai_medical_report_service.dart
// ✅ FIXED VERSION - Resolves type '_ConstMap<String, dynamic>' is not a subtype of type 'String' error
// All Map values are now properly converted to Strings before being passed to helper methods

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/endocrine/endocrine_condition.dart';
import '../models/patient.dart';

class AIMedicalReportService {
  // ✅ IMPORTANT: Replace with your actual OpenAI API key
  static const String _apiKey = 'YOUR_OPENAI_API_KEY_HERE';
  static const String _openAiEndpoint = 'https://api.openai.com/v1/chat/completions';

  // Helper method to safely convert dynamic values to Strings
  static String _safeStringValue(dynamic value, [String defaultValue = 'N/A']) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }

  // Step 1: Collect all data from tabs
  static Future<Map<String, dynamic>> collectAllData({
    required EndocrineCondition condition,
    required Patient patient,
  }) async {
    print('📊 Step 1: Collecting all data from tabs...');

    final data = {
      'patient': {
        'id': patient.id,
        'name': patient.name,
        'age': patient.age,
        'phone': patient.phone,
        'date': patient.date,
      },
      'disease': {
        'id': condition.diseaseId,
        'name': condition.diseaseName,
        'gland': condition.gland,
        'category': condition.category,
        'status': condition.status.toString().split('.').last,
        'severity': condition.severity?.toString().split('.').last,
      },
      'clinicalHistory': {
        'chiefComplaint': condition.chiefComplaint ?? 'Not recorded',
        'historyOfPresentIllness': condition.historyOfPresentIllness ?? 'Not recorded',
        'pastMedicalHistory': condition.pastMedicalHistory ?? 'Not recorded',
        'familyHistory': condition.familyHistory ?? 'Not recorded',
        'allergies': condition.allergies ?? 'None reported',
      },
      'vitals': condition.vitals ?? {},
      'measurements': condition.measurements ?? {},
      'labReadings': condition.labReadings.map((lab) => {
        'testName': lab.testName,
        'value': lab.value,
        'unit': lab.unit,
        'testDate': lab.testDate.toIso8601String(),
        'status': lab.status,
        'isAbnormal': lab.isAbnormal,
        'normalMin': lab.normalMin,
        'normalMax': lab.normalMax,
        'notes': lab.notes,
      }).toList(),
      'images': condition.images.map((img) => {
        'type': img.type,
        'description': img.description,
        'captureDate': img.captureDate.toIso8601String(),
        'annotations': img.annotations,
      }).toList(),
      'treatmentPlan': condition.treatmentPlan != null ? {
        'approach': condition.treatmentPlan!.approach,
        'goal': condition.treatmentPlan!.goal,
        'targets': condition.treatmentPlan!.targets,
        'monitoringPlan': condition.treatmentPlan!.monitoringPlan,
        'patientEducation': condition.treatmentPlan!.patientEducation,
      } : null,
      'notes': condition.notes,
      'followUpPlan': condition.followUpPlan,
    };

    print('✅ Data collection complete!');
    return data;
  }

  // Step 2: Process with OpenAI GPT-4
  static Future<Map<String, dynamic>> processWithAI(Map<String, dynamic> data) async {
    print('🤖 Step 2: Processing with OpenAI GPT-4...');

    try {
      // Build the prompt
      final prompt = _buildPrompt(data);

      // Call OpenAI API
      final response = await http.post(
        Uri.parse(_openAiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(),
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 3000,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final aiContent = responseData['choices'][0]['message']['content'];

        print('✅ AI processing complete!');

        return _parseAIResponse(aiContent);
      } else {
        print('❌ OpenAI API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error processing with AI: $e');
      // Return fallback response if AI fails
      return {
        'summary': 'AI analysis unavailable. Please review the clinical data manually.',
        'clinicalAnalysis': 'Complete clinical analysis pending.',
        'labInterpretation': 'See clinical data above.',
        'imagingFindings': 'See clinical data above.',
        'treatmentRecommendations': 'Continue current management plan.',
        'prognosis': 'Prognosis depends on treatment adherence.',
        'criticalAlerts': [],
        'keyFindings': ['Review clinical data manually'],
        'followUpPlan': 'Follow-up as per treatment plan.',
      };
    }
  }

  // Step 3: Generate PDF using native Flutter PDF package
  static Future<String> generatePDF({
    required Map<String, dynamic> collectedData,
    required Map<String, dynamic> aiInsights,
  }) async {
    print('📄 Step 3: Generating PDF with native Flutter PDF library...');

    try {
      final pdf = pw.Document();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfPath = '${tempDir.path}/medical_report_$timestamp.pdf';

      // Extract data
      final patient = collectedData['patient'] as Map<String, dynamic>;
      final disease = collectedData['disease'] as Map<String, dynamic>;
      final history = collectedData['clinicalHistory'] as Map<String, dynamic>;
      final labReadings = collectedData['labReadings'] as List?;
      final treatmentPlan = collectedData['treatmentPlan'] as Map<String, dynamic>?;

      // Build PDF pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Title
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                gradient: const pw.LinearGradient(
                  colors: [PdfColors.blue400, PdfColors.purple400],
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    '🤖 AI-POWERED MEDICAL REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Generated: ${DateTime.now().toString().split('.')[0]}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Patient Information
            _buildSection(
              title: 'PATIENT INFORMATION',
              content: [
                // ✅ FIX: Use _safeStringValue to ensure all values are Strings
                _buildInfoRow('Name:', _safeStringValue(patient['name'])),
                _buildInfoRow('Patient ID:', _safeStringValue(patient['id'])),
                _buildInfoRow('Age:', '${_safeStringValue(patient['age'])} years'),
                _buildInfoRow('Contact:', _safeStringValue(patient['phone'])),
              ],
              bgColor: PdfColors.blue50,
              borderColor: PdfColors.blue300,
            ),

            pw.SizedBox(height: 16),

            // Diagnosis
            _buildSection(
              title: 'DIAGNOSIS',
              content: [
                // ✅ FIX: Use _safeStringValue for all disease fields
                _buildInfoRow('Disease:', _safeStringValue(disease['name'])),
                _buildInfoRow('Category:', _safeStringValue(disease['category'])),
                _buildInfoRow('Status:', _safeStringValue(disease['status'])),
                if (disease['severity'] != null)
                  _buildInfoRow('Severity:', _safeStringValue(disease['severity'])),
              ],
              bgColor: PdfColors.yellow50,
              borderColor: PdfColors.yellow300,
            ),

            pw.SizedBox(height: 16),

            // Clinical History
            if (history['chiefComplaint'] != null || history['historyOfPresentIllness'] != null)
              _buildSection(
                title: 'CLINICAL HISTORY',
                content: [
                  // ✅ FIX: Use _safeStringValue for all history fields
                  if (history['chiefComplaint'] != null)
                    _buildTextBlock('Chief Complaint:', _safeStringValue(history['chiefComplaint'])),
                  if (history['historyOfPresentIllness'] != null)
                    _buildTextBlock('Present Illness:', _safeStringValue(history['historyOfPresentIllness'])),
                  if (history['pastMedicalHistory'] != null)
                    _buildTextBlock('Past Medical History:', _safeStringValue(history['pastMedicalHistory'])),
                  if (history['familyHistory'] != null)
                    _buildTextBlock('Family History:', _safeStringValue(history['familyHistory'])),
                  if (history['allergies'] != null)
                    _buildTextBlock('Allergies:', _safeStringValue(history['allergies'])),
                ],
                bgColor: PdfColors.grey50,
                borderColor: PdfColors.grey300,
              ),

            pw.SizedBox(height: 16),

            // Lab Results
            if (labReadings != null && labReadings.isNotEmpty) ...[
              _buildSectionHeader('LABORATORY RESULTS'),
              pw.SizedBox(height: 8),
              _buildLabResultsTable(labReadings),
              pw.SizedBox(height: 16),
            ],

            // Treatment Plan
            if (treatmentPlan != null) ...[
              _buildSection(
                title: 'TREATMENT PLAN',
                content: [
                  // ✅ FIX: Use _safeStringValue for all treatment plan fields
                  if (treatmentPlan['approach'] != null)
                    _buildTextBlock('Approach:', _safeStringValue(treatmentPlan['approach'])),
                  if (treatmentPlan['goal'] != null)
                    _buildTextBlock('Goal:', _safeStringValue(treatmentPlan['goal'])),
                  if (treatmentPlan['targets'] != null)
                    _buildTextBlock('Targets:', _safeStringValue(treatmentPlan['targets'])),
                ],
                bgColor: PdfColors.orange50,
                borderColor: PdfColors.orange300,
              ),
              pw.SizedBox(height: 16),
            ],

            // New Page for AI Analysis
            pw.NewPage(),

            // AI Clinical Analysis
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: PdfColors.green300, width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green200,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          '🤖',
                          style: const pw.TextStyle(fontSize: 20),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        'AI CLINICAL ANALYSIS',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    // ✅ FIX: Safely convert AI insights to String
                    _safeStringValue(aiInsights['clinicalAnalysis'], 'No analysis available'),
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Treatment Recommendations
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: PdfColors.purple300, width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.purple200,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          '💊',
                          style: const pw.TextStyle(fontSize: 20),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        'TREATMENT RECOMMENDATIONS',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.purple900,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    // ✅ FIX: Safely convert treatment recommendations to String
                    _safeStringValue(aiInsights['treatmentRecommendations'], 'No recommendations available'),
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 32),

            // Disclaimer
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'This report was generated using AI assistance (OpenAI GPT-4o) and should be reviewed by a qualified '
                    'healthcare provider. AI insights are meant to support clinical decision-making but do not replace '
                    'professional medical judgment.',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      );

      // Save PDF
      final file = File(pdfPath);
      await file.writeAsBytes(await pdf.save());

      print('✅ PDF generated successfully: $pdfPath');
      return pdfPath;
    } catch (e) {
      print('❌ Error generating PDF: $e');
      rethrow;
    }
  }

  // Helper: Build section
  static pw.Widget _buildSection({
    required String title,
    required List<pw.Widget> content,
    required PdfColor bgColor,
    required PdfColor borderColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderColor, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
          pw.SizedBox(height: 12),
          ...content,
        ],
      ),
    );
  }

  // Helper: Build section header
  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue, width: 2),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  // Helper: Build info row
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Build text block
  static pw.Widget _buildTextBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  // Helper: Build lab results table
  static pw.Widget _buildLabResultsTable(List labResults) {
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
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _buildTableHeader('Test Name'),
            _buildTableHeader('Result'),
            _buildTableHeader('Normal Range'),
            _buildTableHeader('Status'),
          ],
        ),
        // Data rows
        ...labResults.map((lab) => pw.TableRow(
          decoration: lab['isAbnormal'] == true
              ? const pw.BoxDecoration(color: PdfColors.red50)
              : null,
          children: [
            // ✅ FIX: Safely convert all lab values to Strings
            _buildTableCell(_safeStringValue(lab['testName'])),
            _buildTableCell('${_safeStringValue(lab['value'])} ${_safeStringValue(lab['unit'], '')}'),
            _buildTableCell('${_safeStringValue(lab['normalMin'], '')} - ${_safeStringValue(lab['normalMax'], '')}'),
            _buildTableCell(lab['isAbnormal'] == true ? 'Abnormal' : 'Normal'),
          ],
        )).toList(),
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
          fontSize: 10,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  // System prompt for medical analysis
  static String _getSystemPrompt() {
    return '''You are an expert medical AI assistant helping to generate comprehensive medical reports for thyroid and endocrine conditions.

Your role is to:
1. Analyze all patient data (demographics, history, labs, imaging, treatment)
2. Generate intelligent insights and clinical interpretations
3. Identify trends, patterns, and abnormalities
4. Provide evidence-based treatment recommendations
5. Assess prognosis and suggest follow-up plans
6. Flag any critical or concerning findings

Provide clear, concise, and clinically relevant analysis that helps healthcare providers make informed decisions.''';
  }

  // Build prompt from collected data
  static String _buildPrompt(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    buffer.writeln('Please analyze the following patient data and provide comprehensive medical insights:\n');

    // Patient info
    final patient = data['patient'];
    buffer.writeln('PATIENT: ${patient['name']}, Age: ${patient['age']}, ID: ${patient['id']}\n');

    // Disease info
    final disease = data['disease'];
    buffer.writeln('DIAGNOSIS: ${disease['name']} (${disease['category']})');
    buffer.writeln('Status: ${disease['status']}, Severity: ${disease['severity'] ?? "Not specified"}\n');

    // Clinical history
    final history = data['clinicalHistory'];
    if (history['chiefComplaint'] != null) {
      buffer.writeln('CHIEF COMPLAINT: ${history['chiefComplaint']}');
    }
    if (history['historyOfPresentIllness'] != null) {
      buffer.writeln('PRESENT ILLNESS: ${history['historyOfPresentIllness']}');
    }

    // Lab results
    final labReadings = data['labReadings'] as List?;
    if (labReadings != null && labReadings.isNotEmpty) {
      buffer.writeln('\nLAB RESULTS:');
      for (var lab in labReadings) {
        buffer.writeln('- ${lab['testName']}: ${lab['value']} ${lab['unit']} (Normal: ${lab['normalMin']}-${lab['normalMax']})');
        if (lab['isAbnormal'] == true) {
          buffer.writeln('  ⚠️ ABNORMAL');
        }
      }
    }

    buffer.writeln('\nPlease provide:');
    buffer.writeln('1. Clinical Analysis');
    buffer.writeln('2. Lab Interpretation');
    buffer.writeln('3. Treatment Recommendations');
    buffer.writeln('4. Prognosis');
    buffer.writeln('5. Follow-up Plan');

    return buffer.toString();
  }

  // Parse AI response
  static Map<String, dynamic> _parseAIResponse(String aiContent) {
    return {
      'summary': 'AI-generated medical analysis',
      'clinicalAnalysis': aiContent,
      'labInterpretation': 'See clinical analysis above',
      'imagingFindings': 'See clinical analysis above',
      'treatmentRecommendations': 'See clinical analysis above',
      'prognosis': 'See clinical analysis above',
      'criticalAlerts': [],
      'keyFindings': ['See detailed analysis above'],
      'followUpPlan': 'See clinical analysis above',
    };
  }

  // Main entry point: Generate complete AI-powered PDF report
  static Future<String> generateAIPoweredReport({
    required EndocrineCondition condition,
    required Patient patient,
    Function(String)? onProgress,
  }) async {
    try {
      // Step 1: Collect data
      onProgress?.call('Collecting data from all tabs...');
      final collectedData = await collectAllData(
        condition: condition,
        patient: patient,
      );

      // Step 2: Process with AI
      onProgress?.call('Processing with OpenAI GPT-4...');
      final aiInsights = await processWithAI(collectedData);

      // Step 3: Generate PDF
      onProgress?.call('Generating professional PDF...');
      final pdfPath = await generatePDF(
        collectedData: collectedData,
        aiInsights: aiInsights,
      );

      onProgress?.call('Report generated successfully!');
      return pdfPath;
    } catch (e) {
      print('❌ Error generating AI-powered report: $e');
      rethrow;
    }
  }
}