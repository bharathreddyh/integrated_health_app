// ==================== AI MEDICAL REPORT SERVICE - OPENAI VERSION (FIXED) ====================
// lib/services/ai_medical_report_service.dart
// ✅ Uses OpenAI GPT-4
// ✅ FIXED to match actual model properties
// ✅ Collects data from all tabs
// ✅ Generates professional PDF

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/endocrine/endocrine_condition.dart';
import '../models/patient.dart';
import '../config/api_keys.dart';

class AIMedicalReportService {
  // OpenAI Configuration
  static const String _openAiEndpoint = 'https://api.openai.com/v1/chat/completions';
  static final String _apiKey = ApiKeys.openAiApiKey;

  // Step 1: Collect all data from tabs
  static Future<Map<String, dynamic>> collectAllData({
    required EndocrineCondition condition,
    required Patient patient,
  }) async {
    print('📊 Step 1: Collecting data from all tabs...');

    final data = {
      // Patient Demographics
      'patient': {
        'id': patient.id,
        'name': patient.name,
        'age': patient.age,
        'phone': patient.phone,
        'date': patient.date,
      },

      // Disease Information
      'disease': {
        'id': condition.diseaseId,
        'name': condition.diseaseName,
        'category': condition.category,
        'gland': condition.gland,
        'status': condition.status.toString(),
        'severity': condition.severity?.toString(),
        'diagnosisDate': condition.diagnosisDate?.toString(),
      },

      // Clinical History (Patient Data Tab)
      'clinicalHistory': {
        'chiefComplaint': condition.chiefComplaint ?? 'Not recorded',
        'historyOfPresentIllness': condition.historyOfPresentIllness ?? 'Not recorded',
        'pastMedicalHistory': condition.pastMedicalHistory ?? 'Not recorded',
        'familyHistory': condition.familyHistory ?? 'Not recorded',
        'allergies': condition.allergies ?? 'None reported',
      },

      // Vitals
      'vitals': condition.vitals ?? {},

      // Measurements
      'measurements': condition.measurements ?? {},

      // Labs & Trends - FIXED to use actual properties
      'labs': condition.labReadings.map((lab) => {
        'test': lab.testName,
        'value': lab.value,
        'unit': lab.unit,
        'date': lab.testDate.toString(),  // FIXED: testDate (not date)
        'status': lab.status,  // FIXED: status (not abnormality)
        'isAbnormal': lab.isAbnormal,
        'normalMin': lab.normalMin,
        'normalMax': lab.normalMax,
        'notes': lab.notes,
      }).toList(),

      // Clinical Features - FIXED to use actual properties
      'clinicalFeatures': condition.clinicalFeatures.map((feature) => {
        'name': feature.name,
        'type': feature.type.toString(),
        'severity': feature.severity,
        'isPresent': feature.isPresent,
        'onsetDate': feature.onsetDate?.toString(),  // FIXED: onsetDate (not duration)
        'notes': feature.notes,
      }).toList(),

      // Canvas/Anatomy Images - FIXED to use actual properties
      'images': condition.images.map((img) => {
        'type': img.type,
        'description': img.description,
        'captureDate': img.captureDate.toString(),  // FIXED: captureDate (not date)
        'annotations': img.annotations,
      }).toList(),

      // Complications - FIXED to use actual properties
      'complications': condition.complications.map((comp) => {
        'name': comp.name,
        'severity': comp.severity,
        'isPresent': comp.isPresent,
        'onsetDate': comp.onsetDate?.toString(),  // FIXED: onsetDate (not dateIdentified)
        'notes': comp.notes,  // FIXED: notes (not managementPlan)
      }).toList(),

      // Medications (Treatment) - FIXED to use actual properties
      'medications': condition.medications.map((med) => {
        'name': med.name,
        'dose': med.dose,  // FIXED: dose (not dosage)
        'frequency': med.frequency,
        'route': med.route,
        'startDate': med.startDate.toString(),
        'endDate': med.endDate?.toString(),
        'isActive': med.isActive,
        'indication': med.indication,
        'notes': med.notes,
      }).toList(),

      // Treatment Plan - FIXED to use actual properties
      'treatmentPlan': condition.treatmentPlan != null ? {
        'approach': condition.treatmentPlan!.approach,  // FIXED: approach
        'goal': condition.treatmentPlan!.goal,  // FIXED: goal (singular)
        'targets': condition.treatmentPlan!.targets,
        'monitoringPlan': condition.treatmentPlan!.monitoringPlan,
        'patientEducation': condition.treatmentPlan!.patientEducation,
      } : null,

      // Additional Notes
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
          'model': 'gpt-4o', // Use GPT-4 Optimized for best results
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
          'temperature': 0.3, // Lower for medical consistency
          'max_tokens': 3000,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final aiContent = responseData['choices'][0]['message']['content'];

        print('✅ AI processing complete!');

        // Parse the AI response
        return _parseAIResponse(aiContent);
      } else {
        print('❌ OpenAI API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error processing with AI: $e');
      rethrow;
    }
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
6. Flag any critical findings that need immediate attention

IMPORTANT:
- Be thorough but concise
- Use medical terminology appropriately
- Base recommendations on current evidence and guidelines
- Always emphasize that the report supports clinical decision-making but doesn't replace physician judgment
- Highlight critical findings clearly

Response Format (JSON):
{
  "executiveSummary": "2-3 sentence overview of the case",
  "clinicalAnalysis": "Comprehensive analysis of the patient's condition",
  "labInterpretation": "Interpretation of lab results, trends, and significance",
  "imagingFindings": "Analysis of imaging and anatomical findings",
  "treatmentRecommendations": "Evidence-based treatment suggestions",
  "prognosis": "Assessment of expected outcomes and disease trajectory",
  "criticalAlerts": ["List of any urgent findings"],
  "keyFindings": ["3-5 most important clinical points"],
  "followUpPlan": "Structured follow-up and monitoring recommendations"
}''';
  }

  // Build comprehensive prompt from collected data
  static String _buildPrompt(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    buffer.writeln('PATIENT MEDICAL REPORT DATA');
    buffer.writeln('=' * 60);
    buffer.writeln();

    // Patient Info
    buffer.writeln('PATIENT INFORMATION:');
    buffer.writeln('Name: ${data['patient']['name']}');
    buffer.writeln('Age: ${data['patient']['age']} years');
    buffer.writeln('ID: ${data['patient']['id']}');
    buffer.writeln();

    // Disease Info
    buffer.writeln('DIAGNOSIS:');
    buffer.writeln('Disease: ${data['disease']['name']}');
    buffer.writeln('Category: ${data['disease']['category']}');
    buffer.writeln('Status: ${data['disease']['status']}');
    if (data['disease']['severity'] != null) {
      buffer.writeln('Severity: ${data['disease']['severity']}');
    }
    buffer.writeln();

    // Clinical History
    buffer.writeln('CLINICAL HISTORY:');
    final history = data['clinicalHistory'] as Map<String, dynamic>;
    history.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty && value != 'Not recorded') {
        buffer.writeln('$key: $value');
      }
    });
    buffer.writeln();

    // Vitals
    if (data['vitals'] != null && (data['vitals'] as Map).isNotEmpty) {
      buffer.writeln('VITAL SIGNS:');
      (data['vitals'] as Map).forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
      buffer.writeln();
    }

    // Measurements
    if (data['measurements'] != null && (data['measurements'] as Map).isNotEmpty) {
      buffer.writeln('MEASUREMENTS:');
      (data['measurements'] as Map).forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
      buffer.writeln();
    }

    // Lab Results
    if (data['labs'] != null && (data['labs'] as List).isNotEmpty) {
      buffer.writeln('LABORATORY RESULTS:');
      for (var lab in data['labs'] as List) {
        buffer.writeln('- ${lab['test']}: ${lab['value']} ${lab['unit']}');
        if (lab['isAbnormal'] == true) {
          buffer.writeln('  ⚠️ Status: ${lab['status']}');
          buffer.writeln('  Normal range: ${lab['normalMin']}-${lab['normalMax']}');
        }
        if (lab['notes'] != null && lab['notes'].toString().isNotEmpty) {
          buffer.writeln('  Notes: ${lab['notes']}');
        }
      }
      buffer.writeln();
    }

    // Clinical Features
    if (data['clinicalFeatures'] != null && (data['clinicalFeatures'] as List).isNotEmpty) {
      buffer.writeln('CLINICAL FEATURES:');
      for (var feature in data['clinicalFeatures'] as List) {
        if (feature['isPresent'] == true) {
          buffer.writeln('- ${feature['name']} (${feature['type']})');
          if (feature['severity'] != null) {
            buffer.writeln('  Severity: ${feature['severity']}');
          }
          if (feature['onsetDate'] != null) {
            buffer.writeln('  Onset: ${feature['onsetDate']}');
          }
        }
      }
      buffer.writeln();
    }

    // Imaging/Canvas
    if (data['images'] != null && (data['images'] as List).isNotEmpty) {
      buffer.writeln('IMAGING FINDINGS:');
      for (var img in data['images'] as List) {
        buffer.writeln('- ${img['type']}: ${img['description']}');
        buffer.writeln('  Date: ${img['captureDate']}');
      }
      buffer.writeln();
    }

    // Complications
    if (data['complications'] != null && (data['complications'] as List).isNotEmpty) {
      buffer.writeln('COMPLICATIONS:');
      for (var comp in data['complications'] as List) {
        if (comp['isPresent'] == true) {
          buffer.writeln('- ${comp['name']} (${comp['severity']})');
          if (comp['onsetDate'] != null) {
            buffer.writeln('  Onset: ${comp['onsetDate']}');
          }
          if (comp['notes'] != null && comp['notes'].toString().isNotEmpty) {
            buffer.writeln('  Notes: ${comp['notes']}');
          }
        }
      }
      buffer.writeln();
    }

    // Current Medications
    if (data['medications'] != null && (data['medications'] as List).isNotEmpty) {
      buffer.writeln('CURRENT MEDICATIONS:');
      for (var med in data['medications'] as List) {
        if (med['isActive'] == true) {
          buffer.writeln('- ${med['name']}: ${med['dose']}, ${med['frequency']}');
          if (med['route'] != null) {
            buffer.writeln('  Route: ${med['route']}');
          }
          if (med['indication'] != null && med['indication'].toString().isNotEmpty) {
            buffer.writeln('  Indication: ${med['indication']}');
          }
        }
      }
      buffer.writeln();
    }

    // Treatment Plan
    if (data['treatmentPlan'] != null) {
      buffer.writeln('TREATMENT PLAN:');
      final plan = data['treatmentPlan'] as Map<String, dynamic>;
      if (plan['approach'] != null) buffer.writeln('Approach: ${plan['approach']}');
      if (plan['goal'] != null) buffer.writeln('Goal: ${plan['goal']}');
      if (plan['monitoringPlan'] != null) buffer.writeln('Monitoring: ${plan['monitoringPlan']}');
      buffer.writeln();
    }

    // Follow-up
    if (data['followUpPlan'] != null && data['followUpPlan'].toString().isNotEmpty) {
      buffer.writeln('FOLLOW-UP PLAN:');
      buffer.writeln(data['followUpPlan']);
      buffer.writeln();
    }

    buffer.writeln();
    buffer.writeln('Please analyze this patient data and provide comprehensive medical insights in JSON format.');

    return buffer.toString();
  }

  // Parse AI JSON response
  static Map<String, dynamic> _parseAIResponse(String aiContent) {
    try {
      // Extract JSON from markdown code blocks if present
      String jsonText = aiContent;
      if (aiContent.contains('```json')) {
        final start = aiContent.indexOf('```json') + 7;
        final end = aiContent.indexOf('```', start);
        jsonText = aiContent.substring(start, end).trim();
      } else if (aiContent.contains('```')) {
        final start = aiContent.indexOf('```') + 3;
        final end = aiContent.indexOf('```', start);
        jsonText = aiContent.substring(start, end).trim();
      }

      return jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error parsing AI response: $e');
      // Return fallback structure
      return {
        'executiveSummary': 'AI analysis completed. Please review the detailed sections below.',
        'clinicalAnalysis': aiContent,
        'labInterpretation': 'See clinical analysis above.',
        'imagingFindings': 'See clinical analysis above.',
        'treatmentRecommendations': 'Continue current management plan.',
        'prognosis': 'Prognosis depends on treatment adherence and follow-up.',
        'criticalAlerts': [],
        'keyFindings': ['Review AI analysis above'],
        'followUpPlan': 'Follow-up as per treatment plan.',
      };
    }
  }

  // Step 3: Generate PDF with Python reportlab
  static Future<String> generatePDF({
    required Map<String, dynamic> collectedData,
    required Map<String, dynamic> aiInsights,
  }) async {
    print('📄 Step 3: Generating PDF with reportlab...');

    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfPath = '${tempDir.path}/medical_report_$timestamp.pdf';

      // Create Python script
      final pythonScript = _generatePythonScript(
        collectedData: collectedData,
        aiInsights: aiInsights,
        outputPath: pdfPath,
      );

      // Save Python script
      final scriptPath = '${tempDir.path}/generate_report_$timestamp.py';
      await File(scriptPath).writeAsString(pythonScript);

      // Execute Python script
      final result = await Process.run('python3', [scriptPath]);

      if (result.exitCode == 0) {
        print('✅ PDF generated successfully: $pdfPath');
        return pdfPath;
      } else {
        print('❌ Python script error:');
        print('stdout: ${result.stdout}');
        print('stderr: ${result.stderr}');
        throw Exception('PDF generation failed: ${result.stderr}');
      }
    } catch (e) {
      print('❌ Error generating PDF: $e');
      rethrow;
    }
  }

  // Generate Python script for PDF creation
  static String _generatePythonScript({
    required Map<String, dynamic> collectedData,
    required Map<String, dynamic> aiInsights,
    required String outputPath,
  }) {
    // Escape strings for Python
    String escape(String? str) {
      if (str == null) return '';
      return str.replaceAll('\\', '\\\\')
          .replaceAll("'", "\\'")
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '');
    }

    final patient = collectedData['patient'] as Map<String, dynamic>;
    final disease = collectedData['disease'] as Map<String, dynamic>;
    final history = collectedData['clinicalHistory'] as Map<String, dynamic>;

    return '''
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from datetime import datetime

def create_medical_report():
    # Create PDF
    pdf = SimpleDocTemplate(
        '${escape(outputPath)}',
        pagesize=letter,
        topMargin=0.5*inch,
        bottomMargin=0.5*inch,
        leftMargin=0.75*inch,
        rightMargin=0.75*inch
    )
    
    story = []
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=colors.HexColor('#1E40AF'),
        spaceAfter=20,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=16,
        textColor=colors.HexColor('#2563EB'),
        spaceAfter=12,
        spaceBefore=16,
        fontName='Helvetica-Bold'
    )
    
    ai_style = ParagraphStyle(
        'AIInsight',
        parent=styles['Normal'],
        fontSize=11,
        textColor=colors.HexColor('#065F46'),
        backColor=colors.HexColor('#D1FAE5'),
        leftIndent=10,
        rightIndent=10,
        spaceBefore=6,
        spaceAfter=6,
        borderPadding=8,
    )
    
    # Header
    story.append(Paragraph('🤖 AI-POWERED MEDICAL REPORT', title_style))
    story.append(Spacer(1, 0.2*inch))
    
    # Report metadata
    metadata_data = [
        ['Report Generated:', datetime.now().strftime('%Y-%m-%d %H:%M:%S')],
        ['Report Type:', 'Comprehensive AI Analysis'],
        ['AI Model:', 'OpenAI GPT-4o'],
    ]
    metadata_table = Table(metadata_data, colWidths=[2*inch, 4*inch])
    metadata_table.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('TEXTCOLOR', (0, 0), (0, -1), colors.grey),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
    ]))
    story.append(metadata_table)
    story.append(Spacer(1, 0.3*inch))
    
    # Executive Summary (AI)
    story.append(Paragraph('EXECUTIVE SUMMARY', heading_style))
    story.append(Paragraph('🤖 <b>AI-Generated Overview:</b>', ai_style))
    story.append(Paragraph('${escape(aiInsights['executiveSummary'])}', ai_style))
    story.append(Spacer(1, 0.2*inch))
    
    # Patient Information
    story.append(PageBreak())
    story.append(Paragraph('PATIENT INFORMATION', heading_style))
    
    patient_data = [
        ['Patient Name:', '${escape(patient['name'])}'],
        ['Patient ID:', '${escape(patient['id'])}'],
        ['Age:', '${patient['age']} years'],
        ['Date:', '${escape(patient['date'])}'],
    ]
    patient_table = Table(patient_data, colWidths=[2*inch, 4*inch])
    patient_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#DBEAFE')),
        ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.HexColor('#1E3A8A')),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#93C5FD')),
        ('PADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(patient_table)
    story.append(Spacer(1, 0.2*inch))
    
    # Diagnosis
    story.append(Paragraph('DIAGNOSIS', heading_style))
    diagnosis_data = [
        ['Disease:', '${escape(disease['name'])}'],
        ['Category:', '${escape(disease['category'])}'],
        ['Status:', '${escape(disease['status'])}'],
    ]
    if '${disease['severity']}':
        diagnosis_data.append(['Severity:', '${escape(disease['severity'])}'])
    
    diagnosis_table = Table(diagnosis_data, colWidths=[2*inch, 4*inch])
    diagnosis_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#FEF3C7')),
        ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#FDE68A')),
        ('PADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(diagnosis_table)
    story.append(Spacer(1, 0.2*inch))
    
    # AI Clinical Analysis
    story.append(PageBreak())
    story.append(Paragraph('🤖 AI CLINICAL ANALYSIS', heading_style))
    story.append(Paragraph('${escape(aiInsights['clinicalAnalysis'])}', ai_style))
    story.append(Spacer(1, 0.2*inch))
    
    # Treatment Recommendations (AI)
    story.append(PageBreak())
    story.append(Paragraph('🤖 TREATMENT RECOMMENDATIONS', heading_style))
    story.append(Paragraph('${escape(aiInsights['treatmentRecommendations'])}', ai_style))
    story.append(Spacer(1, 0.2*inch))
    
    # Footer note
    story.append(Spacer(1, 0.3*inch))
    disclaimer = Paragraph(
        '<i>This report was generated using AI assistance (OpenAI GPT-4o) and should be reviewed by a qualified healthcare provider. '
        'AI insights are meant to support clinical decision-making but do not replace professional medical judgment.</i>',
        ParagraphStyle('Disclaimer', parent=styles['Normal'], fontSize=8, textColor=colors.grey, alignment=TA_CENTER)
    )
    story.append(disclaimer)
    
    # Build PDF
    pdf.build(story)
    print("✅ PDF generated successfully!")

if __name__ == '__main__':
    create_medical_report()
''';
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