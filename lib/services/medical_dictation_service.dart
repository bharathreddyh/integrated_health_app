// lib/services/medical_dictation_service.dart

import '../models/prescription.dart';
import '../models/lab_test.dart';

enum DictationType {
  vitals,
  prescription,
  labTest,
  diagnosis,
  treatment,
  notes,
  unknown,
}

class DictationResult {
  final DictationType type;
  final Map<String, dynamic> data;
  final String originalText;
  final String feedback;

  DictationResult({
    required this.type,
    required this.data,
    required this.originalText,
    required this.feedback,
  });
}

class MedicalDictationService {
  // Parse medical dictation and extract structured data
  static DictationResult parseDictation(String text) {
    final lowerText = text.toLowerCase().trim();
    print('🎤 Parsing dictation: "$text"');

    // VITALS
    if (_isVitalsCommand(lowerText)) {
      return _parseVitals(text, lowerText);
    }

    // PRESCRIPTION
    if (_isPrescriptionCommand(lowerText)) {
      return _parsePrescription(text, lowerText);
    }

    // LAB TEST
    if (_isLabTestCommand(lowerText)) {
      return _parseLabTest(text, lowerText);
    }

    // DIAGNOSIS
    if (_isDiagnosisCommand(lowerText)) {
      return _parseDiagnosis(text, lowerText);
    }

    // TREATMENT
    if (_isTreatmentCommand(lowerText)) {
      return _parseTreatment(text, lowerText);
    }

    // NOTES
    if (_isNotesCommand(lowerText)) {
      return _parseNotes(text, lowerText);
    }

    // UNKNOWN
    return DictationResult(
      type: DictationType.unknown,
      data: {'text': text},
      originalText: text,
      feedback: 'Could not parse command. Try: "Blood pressure 120/80" or "Add Metformin 500mg"',
    );
  }

  // ==================== VITALS PARSING ====================
  static bool _isVitalsCommand(String text) {
    return _containsAny(text, [
      'blood pressure', 'bp', 'systolic', 'diastolic',
      'heart rate', 'pulse', 'bpm',
      'temperature', 'temp', 'fever',
      'weight', 'kg', 'pounds',
      'height', 'cm', 'feet',
      'oxygen', 'spo2', 'saturation',
      'respiratory rate', 'breathing',
      'glucose', 'sugar', 'blood sugar',
    ]);
  }

  static DictationResult _parseVitals(String text, String lowerText) {
    final vitals = <String, String>{};

    // Blood Pressure (e.g., "140 over 90", "BP 120/80")
    final bpPattern = RegExp(r'(\d{2,3})\s*(?:over|/)\s*(\d{2,3})');
    final bpMatch = bpPattern.firstMatch(text);
    if (bpMatch != null) {
      vitals['bloodPressure'] = '${bpMatch.group(1)}/${bpMatch.group(2)}';
    }

    // Heart Rate (e.g., "heart rate 72", "pulse 80 bpm")
    final hrPattern = RegExp(r'(?:heart rate|pulse|hr)\s*(?:is|:)?\s*(\d{2,3})');
    final hrMatch = hrPattern.firstMatch(lowerText);
    if (hrMatch != null) {
      vitals['heartRate'] = hrMatch.group(1)!;
    }

    // Temperature (e.g., "temperature 98.6", "fever 101.5")
    final tempPattern = RegExp(r'(?:temperature|temp|fever)\s*(?:is|:)?\s*(\d{2,3}\.?\d*)');
    final tempMatch = tempPattern.firstMatch(lowerText);
    if (tempMatch != null) {
      vitals['temperature'] = tempMatch.group(1)!;
    }

    // Weight (e.g., "weight 70 kg", "weighs 155 pounds")
    final weightPattern = RegExp(r'(?:weight|weighs)\s*(?:is|:)?\s*(\d{2,3}\.?\d*)\s*(kg|pounds|lbs)?');
    final weightMatch = weightPattern.firstMatch(lowerText);
    if (weightMatch != null) {
      vitals['weight'] = '${weightMatch.group(1)} ${weightMatch.group(2) ?? 'kg'}';
    }

    // Height (e.g., "height 175 cm", "5 feet 8 inches")
    final heightPattern = RegExp(r'(?:height)\s*(?:is|:)?\s*(\d{2,3})\s*(cm|feet)');
    final heightMatch = heightPattern.firstMatch(lowerText);
    if (heightMatch != null) {
      vitals['height'] = '${heightMatch.group(1)} ${heightMatch.group(2)}';
    }

    // SpO2 (e.g., "oxygen 98%", "spo2 95")
    final spo2Pattern = RegExp(r'(?:oxygen|spo2|saturation)\s*(?:is|:)?\s*(\d{2,3})');
    final spo2Match = spo2Pattern.firstMatch(lowerText);
    if (spo2Match != null) {
      vitals['spo2'] = '${spo2Match.group(1)}%';
    }

    // Blood Sugar (e.g., "glucose 110", "blood sugar 95")
    final glucosePattern = RegExp(r'(?:glucose|sugar|blood sugar)\s*(?:is|:)?\s*(\d{2,3})');
    final glucoseMatch = glucosePattern.firstMatch(lowerText);
    if (glucoseMatch != null) {
      vitals['bloodSugar'] = glucoseMatch.group(1)!;
    }

    if (vitals.isEmpty) {
      return DictationResult(
        type: DictationType.unknown,
        data: {},
        originalText: text,
        feedback: 'Could not parse vitals. Try: "BP 120/80" or "Heart rate 72"',
      );
    }

    return DictationResult(
      type: DictationType.vitals,
      data: vitals,
      originalText: text,
      feedback: 'Added vitals: ${vitals.keys.join(", ")}',
    );
  }

  // ==================== PRESCRIPTION PARSING ====================
  static bool _isPrescriptionCommand(String text) {
    return _containsAny(text, [
      'add', 'prescribe', 'give', 'start',
      'tablet', 'capsule', 'syrup', 'injection',
      'mg', 'ml', 'dose',
      'morning', 'evening', 'night', 'breakfast', 'lunch', 'dinner',
      'once', 'twice', 'thrice', 'daily', 'weekly',
    ]) && !_containsAny(text, ['test', 'lab', 'order']);
  }

  static DictationResult _parsePrescription(String text, String lowerText) {
    // Extract medication name (usually first word or phrase before dosage)
    String medicationName = '';
    String dosage = '';
    String frequency = '';
    String duration = '';
    String instructions = '';

    // Medication name (look for word after "add", "prescribe", etc.)
    final medPattern = RegExp(r'(?:add|prescribe|give|start)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)', caseSensitive: false);
    final medMatch = medPattern.firstMatch(text);
    if (medMatch != null) {
      medicationName = medMatch.group(1)!.trim();
    } else {
      // Try to extract first capitalized word as medication
      final firstWordPattern = RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b');
      final firstMatch = firstWordPattern.firstMatch(text);
      if (firstMatch != null) {
        medicationName = firstMatch.group(1)!;
      }
    }

    // Dosage (e.g., "500 mg", "10 ml", "1 tablet")
    final dosagePattern = RegExp(r'(\d+\.?\d*)\s*(mg|ml|g|tablet|tablets|capsule|capsules|drop|drops)');
    final dosageMatch = dosagePattern.firstMatch(lowerText);
    if (dosageMatch != null) {
      dosage = '${dosageMatch.group(1)} ${dosageMatch.group(2)}';
    }

    // Frequency (e.g., "once daily", "twice a day", "three times")
    if (_containsAny(lowerText, ['once', '1 time', 'one time'])) {
      frequency = 'Once daily';
    } else if (_containsAny(lowerText, ['twice', '2 times', 'two times', 'bid'])) {
      frequency = 'Twice daily';
    } else if (_containsAny(lowerText, ['thrice', '3 times', 'three times', 'tid'])) {
      frequency = 'Three times daily';
    } else if (_containsAny(lowerText, ['four times', '4 times', 'qid'])) {
      frequency = 'Four times daily';
    }

    // Timing (before/after meals)
    if (_containsAny(lowerText, ['after breakfast', 'after morning'])) {
      instructions = 'After breakfast';
    } else if (_containsAny(lowerText, ['before breakfast', 'before morning'])) {
      instructions = 'Before breakfast';
    } else if (_containsAny(lowerText, ['after lunch', 'after afternoon'])) {
      instructions = 'After lunch';
    } else if (_containsAny(lowerText, ['after dinner', 'after evening', 'at night'])) {
      instructions = 'After dinner';
    } else if (_containsAny(lowerText, ['after meals', 'after eating'])) {
      instructions = 'After meals';
    } else if (_containsAny(lowerText, ['before meals', 'before eating'])) {
      instructions = 'Before meals';
    } else if (_containsAny(lowerText, ['with food'])) {
      instructions = 'With food';
    } else if (_containsAny(lowerText, ['empty stomach'])) {
      instructions = 'On empty stomach';
    }

    // Duration (e.g., "for 7 days", "for 2 weeks")
    final durationPattern = RegExp(r'for\s+(\d+)\s+(day|days|week|weeks|month|months)');
    final durationMatch = durationPattern.firstMatch(lowerText);
    if (durationMatch != null) {
      duration = '${durationMatch.group(1)} ${durationMatch.group(2)}';
    } else {
      duration = '7 days'; // Default
    }

    if (medicationName.isEmpty) {
      return DictationResult(
        type: DictationType.unknown,
        data: {},
        originalText: text,
        feedback: 'Could not identify medication. Try: "Add Metformin 500mg twice daily"',
      );
    }

    return DictationResult(
      type: DictationType.prescription,
      data: {
        'medicationName': medicationName,
        'dosage': dosage.isNotEmpty ? dosage : '1 tablet',
        'frequency': frequency.isNotEmpty ? frequency : 'Once daily',
        'duration': duration,
        'instructions': instructions,
      },
      originalText: text,
      feedback: 'Added prescription: $medicationName $dosage',
    );
  }

  // ==================== LAB TEST PARSING ====================
  static bool _isLabTestCommand(String text) {
    return _containsAny(text, [
      'order', 'test', 'lab', 'check', 'blood test',
      'cbc', 'hemoglobin', 'blood sugar', 'hba1c',
      'creatinine', 'lipid', 'cholesterol',
      'x-ray', 'ultrasound', 'ct scan', 'mri',
      'ecg', 'ekg', 'echo',
    ]) && _containsAny(text, ['order', 'test', 'check', 'lab']);
  }

  static DictationResult _parseLabTest(String text, String lowerText) {
    String testName = '';
    String category = 'General';

    // Common test patterns
    final testMappings = {
      'cbc': 'Complete Blood Count',
      'complete blood count': 'Complete Blood Count',
      'hemoglobin': 'Hemoglobin',
      'blood sugar': 'Fasting Blood Sugar',
      'fasting sugar': 'Fasting Blood Sugar',
      'hba1c': 'HbA1c',
      'creatinine': 'Creatinine',
      'lipid profile': 'Lipid Profile',
      'cholesterol': 'Total Cholesterol',
      'thyroid': 'Thyroid Profile',
      'tsh': 'TSH',
      'liver function': 'Liver Function Test',
      'kidney function': 'Kidney Function Test',
      'urine': 'Urine Analysis',
      'x-ray': 'X-Ray',
      'ultrasound': 'Ultrasound',
      'ct scan': 'CT Scan',
      'mri': 'MRI',
      'ecg': 'ECG',
      'echo': 'Echocardiogram',
    };

    for (var entry in testMappings.entries) {
      if (lowerText.contains(entry.key)) {
        testName = entry.value;
        break;
      }
    }

    // Determine category
    if (_containsAny(lowerText, ['blood', 'cbc', 'hemoglobin'])) {
      category = 'Hematology';
    } else if (_containsAny(lowerText, ['sugar', 'glucose', 'hba1c', 'cholesterol', 'lipid', 'creatinine'])) {
      category = 'Biochemistry';
    } else if (_containsAny(lowerText, ['x-ray', 'ultrasound', 'ct', 'mri'])) {
      category = 'Radiology';
    } else if (_containsAny(lowerText, ['ecg', 'echo'])) {
      category = 'Cardiology';
    }

    if (testName.isEmpty) {
      return DictationResult(
        type: DictationType.unknown,
        data: {},
        originalText: text,
        feedback: 'Could not identify test. Try: "Order CBC" or "Check blood sugar"',
      );
    }

    return DictationResult(
      type: DictationType.labTest,
      data: {
        'testName': testName,
        'category': category,
      },
      originalText: text,
      feedback: 'Ordered test: $testName',
    );
  }

  // ==================== DIAGNOSIS PARSING ====================
  static bool _isDiagnosisCommand(String text) {
    return _containsAny(text, [
      'diagnosis', 'diagnosed with', 'has', 'suffering from',
      'complains of', 'presenting with', 'symptoms of',
    ]);
  }

  static DictationResult _parseDiagnosis(String text, String lowerText) {
    // Extract diagnosis after trigger words
    String diagnosis = '';

    final patterns = [
      r'diagnosis[:\s]+(.+)',
      r'diagnosed with\s+(.+)',
      r'has\s+(.+)',
      r'suffering from\s+(.+)',
      r'complains of\s+(.+)',
      r'presenting with\s+(.+)',
    ];

    for (var pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        diagnosis = match.group(1)!.trim();
        break;
      }
    }

    if (diagnosis.isEmpty) {
      diagnosis = text; // Use full text as diagnosis
    }

    return DictationResult(
      type: DictationType.diagnosis,
      data: {'diagnosis': diagnosis},
      originalText: text,
      feedback: 'Added diagnosis',
    );
  }

  // ==================== TREATMENT PARSING ====================
  static bool _isTreatmentCommand(String text) {
    return _containsAny(text, [
      'treatment', 'plan', 'therapy', 'recommend',
      'advised', 'suggested', 'continue',
    ]);
  }

  static DictationResult _parseTreatment(String text, String lowerText) {
    String treatment = '';

    final patterns = [
      r'treatment[:\s]+(.+)',
      r'plan[:\s]+(.+)',
      r'recommend[:\s]+(.+)',
      r'advised[:\s]+(.+)',
    ];

    for (var pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        treatment = match.group(1)!.trim();
        break;
      }
    }

    if (treatment.isEmpty) {
      treatment = text; // Use full text as treatment
    }

    return DictationResult(
      type: DictationType.treatment,
      data: {'treatment': treatment},
      originalText: text,
      feedback: 'Added treatment plan',
    );
  }

  // ==================== NOTES PARSING ====================
  static bool _isNotesCommand(String text) {
    return _containsAny(text, [
      'note', 'notes', 'patient has', 'patient reports',
      'complaining', 'since', 'for the past',
    ]) || text.split(' ').length > 5; // Long sentences are likely notes
  }

  static DictationResult _parseNotes(String text, String lowerText) {
    return DictationResult(
      type: DictationType.notes,
      data: {'notes': text},
      originalText: text,
      feedback: 'Added to clinical notes',
    );
  }

  // ==================== HELPER METHODS ====================
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}