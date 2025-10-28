// lib/services/ai_diagnosis_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/patient.dart';
import '../models/marker.dart';
import '../models/lab_test.dart';

class DiagnosisSuggestion {
  final String diagnosis;
  final double confidence; // 0.0 to 1.0
  final String reasoning;
  final List<String> supportingFactors;
  final List<String> recommendedTests;
  final List<String> differentialDiagnoses;
  final String urgency; // 'routine', 'urgent', 'emergency'
  final List<String> treatmentSuggestions;

  DiagnosisSuggestion({
    required this.diagnosis,
    required this.confidence,
    required this.reasoning,
    required this.supportingFactors,
    required this.recommendedTests,
    required this.differentialDiagnoses,
    required this.urgency,
    required this.treatmentSuggestions,
  });

  factory DiagnosisSuggestion.fromJson(Map<String, dynamic> json) {
    return DiagnosisSuggestion(
      diagnosis: json['diagnosis'] ?? '',
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      reasoning: json['reasoning'] ?? '',
      supportingFactors: List<String>.from(json['supporting_factors'] ?? []),
      recommendedTests: List<String>.from(json['recommended_tests'] ?? []),
      differentialDiagnoses: List<String>.from(json['differential_diagnoses'] ?? []),
      urgency: json['urgency'] ?? 'routine',
      treatmentSuggestions: List<String>.from(json['treatment_suggestions'] ?? []),
    );
  }
}

class AIDiagnosisService {
  static const String _openAiEndpoint = 'https://api.openai.com/v1/chat/completions';
  static final String _apiKey = ApiKeys.openAiApiKey;

  /// Generate AI diagnosis suggestions based on patient data
  static Future<List<DiagnosisSuggestion>> getDiagnosisSuggestions({
    required Patient patient,
    required String chiefComplaint,
    Map<String, String>? vitals,
    List<String>? symptoms,
    List<Marker>? kidneyMarkers,
    List<LabTest>? labResults,
    String? patientHistory,
  }) async {
    try {
      // Build medical context
      final medicalContext = _buildMedicalContext(
        patient: patient,
        chiefComplaint: chiefComplaint,
        vitals: vitals,
        symptoms: symptoms,
        kidneyMarkers: kidneyMarkers,
        labResults: labResults,
        patientHistory: patientHistory,
      );

      print('🤖 Sending to AI: $medicalContext');

      // Call OpenAI API
      final response = await http.post(
        Uri.parse(_openAiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o', // Use GPT-4 for medical accuracy
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(),
            },
            {
              'role': 'user',
              'content': medicalContext,
            },
          ],
          'temperature': 0.3, // Lower temperature for consistent medical advice
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];

        print('🤖 AI Response: $aiResponse');

        // Parse AI response
        return _parseAIResponse(aiResponse);
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('AI API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting diagnosis: $e');
      rethrow;
    }
  }

  /// Build comprehensive medical context for AI
  static String _buildMedicalContext({
    required Patient patient,
    required String chiefComplaint,
    Map<String, String>? vitals,
    List<String>? symptoms,
    List<Marker>? kidneyMarkers,
    List<LabTest>? labResults,
    String? patientHistory,
  }) {
    final buffer = StringBuffer();

    // Patient demographics
    buffer.writeln('PATIENT INFORMATION:');
    buffer.writeln('Age: ${patient.age} years');
    buffer.writeln('Gender: ${_inferGender(patient.name)}');
    buffer.writeln('');

    // Chief complaint
    buffer.writeln('CHIEF COMPLAINT:');
    buffer.writeln(chiefComplaint);
    buffer.writeln('');

    // Vital signs
    if (vitals != null && vitals.isNotEmpty) {
      buffer.writeln('VITAL SIGNS:');
      vitals.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
      buffer.writeln('');
    }

    // Symptoms
    if (symptoms != null && symptoms.isNotEmpty) {
      buffer.writeln('SYMPTOMS:');
      for (var symptom in symptoms) {
        buffer.writeln('- $symptom');
      }
      buffer.writeln('');
    }

    // Kidney imaging findings
    if (kidneyMarkers != null && kidneyMarkers.isNotEmpty) {
      buffer.writeln('KIDNEY IMAGING FINDINGS:');
      final findings = _summarizeKidneyFindings(kidneyMarkers);
      for (var finding in findings) {
        buffer.writeln('- $finding');
      }
      buffer.writeln('');
    }


    // Lab results
    if (labResults != null && labResults.isNotEmpty) {
      buffer.writeln('LABORATORY RESULTS:');
      for (var test in labResults) {
        if (test.resultValue != null && test.resultValue!.isNotEmpty) {
          buffer.writeln('- ${test.testName}: ${test.resultValue} ${test.resultUnit ?? ''}');
        }
      }
      buffer.writeln('');
    }

    // Patient history
    if (patientHistory != null && patientHistory.isNotEmpty) {
      buffer.writeln('MEDICAL HISTORY:');
      buffer.writeln(patientHistory);
      buffer.writeln('');
    }

    buffer.writeln('Please provide diagnostic suggestions based on the above information.');

    return buffer.toString();
  }

  /// System prompt for medical AI
  static String _getSystemPrompt() {
    return '''You are an experienced medical AI assistant helping doctors with differential diagnosis. 

Your role is to:
1. Analyze patient symptoms, vitals, and test results
2. Suggest possible diagnoses with confidence levels
3. Explain your reasoning clearly
4. Recommend additional tests if needed
5. Provide treatment suggestions
6. Identify urgent cases

IMPORTANT DISCLAIMERS:
- You are an AI assistant, NOT a replacement for clinical judgment
- Always emphasize that final diagnosis must be made by the treating physician
- When in doubt, recommend further testing or specialist consultation
- Flag any potentially life-threatening conditions as URGENT

Response Format (JSON):
{
  "suggestions": [
    {
      "diagnosis": "Primary diagnosis name",
      "confidence": 0.85,
      "reasoning": "Detailed explanation of why this diagnosis fits",
      "supporting_factors": ["Factor 1", "Factor 2", "Factor 3"],
      "recommended_tests": ["Test 1", "Test 2"],
      "differential_diagnoses": ["Alternative 1", "Alternative 2"],
      "urgency": "routine|urgent|emergency",
      "treatment_suggestions": ["Treatment 1", "Treatment 2"]
    }
  ],
  "notes": "Additional important notes or red flags"
}

Provide 2-4 diagnosis suggestions, ordered by likelihood (highest confidence first).''';
  }

  /// Parse AI JSON response into DiagnosisSuggestion objects
  static List<DiagnosisSuggestion> _parseAIResponse(String aiResponse) {
    try {
      // Extract JSON from markdown code blocks if present
      String jsonText = aiResponse;
      if (aiResponse.contains('```json')) {
        final start = aiResponse.indexOf('```json') + 7;
        final end = aiResponse.indexOf('```', start);
        jsonText = aiResponse.substring(start, end).trim();
      } else if (aiResponse.contains('```')) {
        final start = aiResponse.indexOf('```') + 3;
        final end = aiResponse.indexOf('```', start);
        jsonText = aiResponse.substring(start, end).trim();
      }

      final parsed = jsonDecode(jsonText);
      final suggestions = parsed['suggestions'] as List;

      return suggestions
          .map((s) => DiagnosisSuggestion.fromJson(s))
          .toList();
    } catch (e) {
      print('❌ Error parsing AI response: $e');
      print('Raw response: $aiResponse');

      // Return fallback suggestion
      return [
        DiagnosisSuggestion(
          diagnosis: 'Unable to parse AI response',
          confidence: 0.0,
          reasoning: 'There was an error processing the AI suggestions. Please review manually.',
          supportingFactors: [],
          recommendedTests: [],
          differentialDiagnoses: [],
          urgency: 'routine',
          treatmentSuggestions: [],
        ),
      ];
    }
  }

  /// Summarize kidney imaging findings from markers
  static List<String> _summarizeKidneyFindings(List<Marker> markers) {
    final findings = <String>[];

    final calculi = markers.where((m) => m.type == 'calculi').toList();
    if (calculi.isNotEmpty) {
      final sizes = calculi.map((m) => m.size).join(', ');
      findings.add('Renal calculi detected (sizes: ${sizes}mm)');
    }

    final cysts = markers.where((m) => m.type == 'cyst').toList();
    if (cysts.isNotEmpty) {
      findings.add('${cysts.length} renal cyst(s) identified');
    }

    final tumors = markers.where((m) => m.type == 'tumor').toList();
    if (tumors.isNotEmpty) {
      findings.add('Mass lesion(s) detected - ${tumors.length} area(s) of concern');
    }

    final inflammation = markers.where((m) => m.type == 'inflammation').toList();
    if (inflammation.isNotEmpty) {
      findings.add('Signs of inflammation present');
    }

    final blockage = markers.where((m) => m.type == 'blockage').toList();
    if (blockage.isNotEmpty) {
      findings.add('Evidence of obstruction/blockage');
    }

    return findings;
  }

  /// Infer gender from name (simple heuristic - can be improved)
  /// Infer gender from name (simple heuristic - can be improved)
  static String _inferGender(String name) {
    // This is a simplification - in production, collect gender data directly
    final femaleSuffixes = ['a', 'i', 'e'];
    final lowerName = name.toLowerCase().trim();
    if (lowerName.isEmpty) return 'Unknown';
    final lastChar = lowerName.substring(lowerName.length - 1);
    return femaleSuffixes.contains(lastChar) ? 'Female' : 'Male';
  }

  /// Quick diagnosis for common conditions (offline fallback)
  static List<DiagnosisSuggestion> getQuickSuggestions({
    required String chiefComplaint,
    Map<String, String>? vitals,
  }) {
    final complaint = chiefComplaint.toLowerCase();

    // Kidney stone pattern
    if (complaint.contains('flank pain') || complaint.contains('kidney pain')) {
      return [
        DiagnosisSuggestion(
          diagnosis: 'Renal Calculi (Kidney Stones)',
          confidence: 0.75,
          reasoning: 'Classic presentation of flank pain suggests renal calculi',
          supportingFactors: ['Flank pain', 'Possible hematuria'],
          recommendedTests: ['Urinalysis', 'CT KUB', 'Ultrasound kidneys'],
          differentialDiagnoses: ['Pyelonephritis', 'Renal colic', 'Musculoskeletal pain'],
          urgency: 'urgent',
          treatmentSuggestions: ['Pain management', 'Hydration', 'Urology referral if needed'],
        ),
      ];
    }

    // Hypertension pattern
    if (vitals != null && vitals['bloodPressure'] != null) {
      final bp = vitals['bloodPressure']!;
      final parts = bp.split('/');
      if (parts.length == 2) {
        final systolic = int.tryParse(parts[0]) ?? 0;
        if (systolic > 140) {
          return [
            DiagnosisSuggestion(
              diagnosis: 'Hypertension',
              confidence: 0.85,
              reasoning: 'Elevated blood pressure reading of $bp',
              supportingFactors: ['Systolic BP > 140 mmHg'],
              recommendedTests: ['Repeat BP measurements', 'ECG', 'Renal function tests'],
              differentialDiagnoses: ['White coat hypertension', 'Secondary hypertension'],
              urgency: systolic > 180 ? 'urgent' : 'routine',
              treatmentSuggestions: [
                'Lifestyle modifications',
                'Consider antihypertensive therapy',
                'Follow-up in 1-2 weeks'
              ],
            ),
          ];
        }
      }
    }

    // Generic suggestion
    return [
      DiagnosisSuggestion(
        diagnosis: 'Insufficient data for AI analysis',
        confidence: 0.0,
        reasoning: 'Please provide more clinical information for accurate suggestions',
        supportingFactors: [],
        recommendedTests: ['Complete clinical evaluation', 'Relevant investigations'],
        differentialDiagnoses: [],
        urgency: 'routine',
        treatmentSuggestions: ['Complete patient assessment first'],
      ),
    ];
  }
}