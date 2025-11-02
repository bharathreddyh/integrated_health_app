// ==================== THYROID MODULE DATA MODELS ====================
// lib/models/endocrine/endocrine_condition.dart

import 'package:flutter/material.dart';
import 'dart:convert';

// ==================== ENUM DEFINITIONS ====================

enum DiagnosisStatus {
  suspected,
  provisional,  // 🆕 ADDED
  confirmed,
  ruledOut,
}

enum DiseaseSeverity {
  mild,
  moderate,
  severe,
  critical,
}

enum AbnormalityType {
  low,
  normal,
  high,
}

enum FeatureType {
  symptom,
  sign,
}

// ==================== MAIN CONDITION MODEL ====================
class EndocrineCondition {
  final String id;
  final String patientId;
  final String patientName;

  // ✅ Patient Data Fields
  final String? chiefComplaint;
  final String? historyOfPresentIllness;
  final String? pastMedicalHistory;
  final String? familyHistory;
  final String? allergies;
  final Map<String, String>? vitals;
  final Map<String, String>? measurements;
  final List<Map<String, dynamic>>? orderedLabTests;
  final List<Map<String, dynamic>>? orderedInvestigations;
  final Map<String, dynamic>? additionalData;

  // 🆕 NEW FIELDS - Add these to support PatientDataTab
  final List<dynamic>? labTestResults;
  final List<dynamic>? investigationFindings;

  // 🆕 NEW FIELDS - Add these to support redesigned OverviewTab
  final List<String>? selectedSymptoms;
  final List<String>? selectedDiagnosticCriteria;
  final List<String>? selectedComplications;

  // Hierarchy
  final String gland; // "thyroid"
  final String category; // "hyperthyroidism"
  final String diseaseId; // "graves_disease"
  final String diseaseName; // "Graves' Disease"

  // Status
  final DiagnosisStatus status;
  final DateTime? diagnosisDate;
  final DiseaseSeverity? severity;

  // Clinical Data
  final List<LabReading> labReadings;
  final List<ClinicalFeature> clinicalFeatures;
  final List<Complication> complications;
  final List<Medication> medications;

  // Images and notes
  final List<MedicalImage> images;
  final String notes;
  final Map<String, dynamic>? canvasAnnotations;

  // Treatment plan
  final TreatmentPlan? treatmentPlan;

  // Follow-up
  final DateTime? nextVisit;
  final String followUpPlan;

  // Meta
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isActive;

  EndocrineCondition({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.gland,
    required this.category,
    required this.diseaseId,
    required this.diseaseName,
    this.status = DiagnosisStatus.suspected,
    this.canvasAnnotations,
    this.diagnosisDate,
    this.severity,
    this.chiefComplaint,
    this.historyOfPresentIllness,
    this.pastMedicalHistory,
    this.familyHistory,
    this.allergies,
    this.vitals,
    this.measurements,
    this.orderedLabTests,
    this.orderedInvestigations,
    this.additionalData,
    this.labTestResults = const [],
    this.investigationFindings = const [],
    // NEW FIELDS for redesigned overview tab
    this.selectedSymptoms = const [],
    this.selectedDiagnosticCriteria = const [],
    this.selectedComplications = const [],
    // Existing fields
    this.labReadings = const [],
    this.clinicalFeatures = const [],
    this.complications = const [],
    this.medications = const [],
    this.images = const [],
    this.notes = '',
    this.treatmentPlan,
    this.nextVisit,
    this.followUpPlan = '',
    DateTime? createdAt,
    DateTime? lastUpdated,
    this.isActive = true,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  // ==================== COMPLETION TRACKING GETTERS ====================

  /// Check if Patient Data tab is complete
  bool get isPatientDataComplete {
    return chiefComplaint != null &&
        chiefComplaint!.isNotEmpty &&
        vitals != null &&
        vitals!.isNotEmpty &&
        vitals!['bloodPressure'] != null &&
        vitals!['heartRate'] != null;
  }

  /// Check if Overview tab is complete (updated for redesigned tab)
  bool get isOverviewComplete {
    return selectedSymptoms != null &&
        selectedSymptoms!.isNotEmpty &&
        selectedDiagnosticCriteria != null &&
        selectedDiagnosticCriteria!.isNotEmpty &&
        severity != null;
  }

  /// Check if Labs tab is complete (at least 3 lab readings)
  bool get isLabsComplete {
    return labReadings.length >= 3;
  }

  /// Check if Clinical Features tab is complete (at least 5 documented)
  bool get isClinicalComplete {
    return clinicalFeatures.where((f) => f.isPresent).length >= 5;
  }

  /// Check if Investigations tab has some data
  bool get isInvestigationsComplete {
    return images.isNotEmpty ||
        notes.isNotEmpty ||
        (orderedLabTests != null && orderedLabTests!.isNotEmpty) ||
        (orderedInvestigations != null && orderedInvestigations!.isNotEmpty);
  }

  /// Check if Treatment tab is complete
  bool get isTreatmentComplete {
    return medications.isNotEmpty || treatmentPlan != null;
  }

  /// Calculate overall completion percentage (out of 7 tabs)
  double get completionPercentage {
    int completed = 0;

    if (isPatientDataComplete) completed++;
    if (isOverviewComplete) completed++;
    // Anatomy tab is informational, not required for completion
    if (isLabsComplete) completed++;
    if (isClinicalComplete) completed++;
    if (isInvestigationsComplete) completed++;
    if (isTreatmentComplete) completed++;

    // Out of 6 completable tabs (Anatomy is excluded)
    return (completed / 6) * 100;
  }

  /// Check if enough data is present to generate PDF
  bool get canGeneratePDF {
    return isPatientDataComplete &&
        isOverviewComplete &&
        (labReadings.isNotEmpty || clinicalFeatures.isNotEmpty) &&
        (medications.isNotEmpty || notes.isNotEmpty);
  }

  /// Get list of incomplete sections for user feedback
  List<String> get incompleteSections {
    List<String> incomplete = [];

    if (!isPatientDataComplete) {
      incomplete.add('Patient Data: Enter vitals and chief complaint');
    }
    if (!isOverviewComplete) {
      incomplete.add('Overview: Select symptoms, diagnostic criteria, and severity');
    }
    if (!isLabsComplete) {
      incomplete.add('Labs: Add at least 3 lab readings');
    }
    if (!isClinicalComplete) {
      incomplete.add('Clinical: Document at least 5 clinical features');
    }
    if (!isInvestigationsComplete) {
      incomplete.add('Investigations: Order lab tests or imaging');
    }
    if (!isTreatmentComplete) {
      incomplete.add('Treatment: Add medications or treatment plan');
    }

    return incomplete;
  }

  /// Get tab completion status map
  Map<String, bool> get tabCompletionStatus {
    return {
      'patientData': isPatientDataComplete,
      'overview': isOverviewComplete,
      'anatomy': true, // Informational only
      'labs': isLabsComplete,
      'clinical': isClinicalComplete,
      'investigations': isInvestigationsComplete,
      'treatment': isTreatmentComplete,
    };
  }

  // ==================== COPY WITH ====================

  EndocrineCondition copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? gland,
    String? category,
    String? diseaseId,
    String? diseaseName,
    DiagnosisStatus? status,
    DateTime? diagnosisDate,
    DiseaseSeverity? severity,
    String? chiefComplaint,
    String? historyOfPresentIllness,
    String? pastMedicalHistory,
    String? familyHistory,
    String? allergies,
    Map<String, dynamic>? canvasAnnotations,
    Map<String, String>? vitals,
    Map<String, String>? measurements,
    List<Map<String, dynamic>>? orderedLabTests,
    List<Map<String, dynamic>>? orderedInvestigations,
    Map<String, dynamic>? additionalData,
    List<dynamic>? labTestResults,
    List<dynamic>? investigationFindings,
    // NEW PARAMETERS for redesigned overview tab
    List<String>? selectedSymptoms,
    List<String>? selectedDiagnosticCriteria,
    List<String>? selectedComplications,
    // Existing parameters
    List<LabReading>? labReadings,
    List<ClinicalFeature>? clinicalFeatures,
    List<Complication>? complications,
    List<Medication>? medications,
    List<MedicalImage>? images,
    String? notes,
    TreatmentPlan? treatmentPlan,
    DateTime? nextVisit,
    String? followUpPlan,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return EndocrineCondition(
      canvasAnnotations: canvasAnnotations ?? this.canvasAnnotations,
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      gland: gland ?? this.gland,
      category: category ?? this.category,
      diseaseId: diseaseId ?? this.diseaseId,
      diseaseName: diseaseName ?? this.diseaseName,
      status: status ?? this.status,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      severity: severity ?? this.severity,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      historyOfPresentIllness: historyOfPresentIllness ?? this.historyOfPresentIllness,
      pastMedicalHistory: pastMedicalHistory ?? this.pastMedicalHistory,
      familyHistory: familyHistory ?? this.familyHistory,
      allergies: allergies ?? this.allergies,
      vitals: vitals ?? this.vitals,
      measurements: measurements ?? this.measurements,
      orderedLabTests: orderedLabTests ?? this.orderedLabTests,
      orderedInvestigations: orderedInvestigations ?? this.orderedInvestigations,
      additionalData: additionalData ?? this.additionalData,
      labTestResults: labTestResults ?? this.labTestResults,
      investigationFindings: investigationFindings ?? this.investigationFindings,
      // NEW ASSIGNMENTS for redesigned overview tab
      selectedSymptoms: selectedSymptoms ?? this.selectedSymptoms,
      selectedDiagnosticCriteria: selectedDiagnosticCriteria ?? this.selectedDiagnosticCriteria,
      selectedComplications: selectedComplications ?? this.selectedComplications,
      // Existing assignments
      labReadings: labReadings ?? this.labReadings,
      clinicalFeatures: clinicalFeatures ?? this.clinicalFeatures,
      complications: complications ?? this.complications,
      medications: medications ?? this.medications,
      images: images ?? this.images,
      notes: notes ?? this.notes,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      nextVisit: nextVisit ?? this.nextVisit,
      followUpPlan: followUpPlan ?? this.followUpPlan,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  // ==================== JSON SERIALIZATION ====================

  Map<String, dynamic> toJson() {
    return {
      'canvasAnnotations': canvasAnnotations,
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'gland': gland,
      'category': category,
      'diseaseId': diseaseId,
      'diseaseName': diseaseName,
      'status': status.toString().split('.').last,
      'diagnosisDate': diagnosisDate?.toIso8601String(),
      'severity': severity?.toString().split('.').last,
      'chiefComplaint': chiefComplaint,
      'historyOfPresentIllness': historyOfPresentIllness,
      'pastMedicalHistory': pastMedicalHistory,
      'familyHistory': familyHistory,
      'allergies': allergies,
      'vitals': vitals,
      'measurements': measurements,
      'orderedLabTests': orderedLabTests,
      'orderedInvestigations': orderedInvestigations,
      'additionalData': additionalData,
      'labTestResults': labTestResults,
      'investigationFindings': investigationFindings,
      // NEW JSON FIELDS for redesigned overview tab
      'selectedSymptoms': selectedSymptoms,
      'selectedDiagnosticCriteria': selectedDiagnosticCriteria,
      'selectedComplications': selectedComplications,
      // Existing JSON fields
      'labReadings': labReadings.map((x) => x.toJson()).toList(),
      'clinicalFeatures': clinicalFeatures.map((x) => x.toJson()).toList(),
      'complications': complications.map((x) => x.toJson()).toList(),
      'medications': medications.map((x) => x.toJson()).toList(),
      'images': images.map((x) => x.toJson()).toList(),
      'notes': notes,
      'treatmentPlan': treatmentPlan?.toJson(),
      'nextVisit': nextVisit?.toIso8601String(),
      'followUpPlan': followUpPlan,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory EndocrineCondition.fromJson(Map<String, dynamic> json) {
    return EndocrineCondition(
      canvasAnnotations: json['canvasAnnotations'] as Map<String, dynamic>?,
      id: json['id'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      gland: json['gland'],
      category: json['category'],
      diseaseId: json['diseaseId'],
      diseaseName: json['diseaseName'],
      status: DiagnosisStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => DiagnosisStatus.suspected,
      ),
      diagnosisDate: json['diagnosisDate'] != null ? DateTime.parse(json['diagnosisDate']) : null,
      severity: json['severity'] != null
          ? DiseaseSeverity.values.firstWhere(
            (e) => e.toString().split('.').last == json['severity'],
        orElse: () => DiseaseSeverity.mild,
      )
          : null,
      chiefComplaint: json['chiefComplaint'],
      historyOfPresentIllness: json['historyOfPresentIllness'],
      pastMedicalHistory: json['pastMedicalHistory'],
      familyHistory: json['familyHistory'],
      allergies: json['allergies'],
      vitals: json['vitals'] != null ? Map<String, String>.from(json['vitals']) : null,
      measurements: json['measurements'] != null ? Map<String, String>.from(json['measurements']) : null,
      orderedLabTests: json['orderedLabTests'] != null ? List<Map<String, dynamic>>.from(json['orderedLabTests']) : null,
      orderedInvestigations: json['orderedInvestigations'] != null ? List<Map<String, dynamic>>.from(json['orderedInvestigations']) : null,
      additionalData: json['additionalData'] != null ? Map<String, dynamic>.from(json['additionalData']) : null,
      labTestResults: json['labTestResults'] ?? [],
      investigationFindings: json['investigationFindings'] ?? [],
      // NEW JSON PARSING for redesigned overview tab
      selectedSymptoms: json['selectedSymptoms'] != null ? List<String>.from(json['selectedSymptoms']) : [],
      selectedDiagnosticCriteria: json['selectedDiagnosticCriteria'] != null ? List<String>.from(json['selectedDiagnosticCriteria']) : [],
      selectedComplications: json['selectedComplications'] != null ? List<String>.from(json['selectedComplications']) : [],
      // Existing JSON parsing
      labReadings: json['labReadings'] != null
          ? (json['labReadings'] as List).map((x) => LabReading.fromJson(x)).toList()
          : [],
      clinicalFeatures: json['clinicalFeatures'] != null
          ? (json['clinicalFeatures'] as List).map((x) => ClinicalFeature.fromJson(x)).toList()
          : [],
      complications: json['complications'] != null
          ? (json['complications'] as List).map((x) => Complication.fromJson(x)).toList()
          : [],
      medications: json['medications'] != null
          ? (json['medications'] as List).map((x) => Medication.fromJson(x)).toList()
          : [],
      images: json['images'] != null
          ? (json['images'] as List).map((x) => MedicalImage.fromJson(x)).toList()
          : [],
      notes: json['notes'] ?? '',
      treatmentPlan: json['treatmentPlan'] != null ? TreatmentPlan.fromJson(json['treatmentPlan']) : null,
      nextVisit: json['nextVisit'] != null ? DateTime.parse(json['nextVisit']) : null,
      followUpPlan: json['followUpPlan'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      isActive: json['isActive'] ?? true,
    );
  }
}

// ==================== LAB READING MODEL (UPDATED) ====================

class LabReading {
  final String id;
  final String testName;
  final double value;
  final String unit;
  final double normalMin;
  final double normalMax;
  final DateTime testDate;  // 🔧 FIXED: was named 'date' in some files
  final String? notes;

  LabReading({
    required this.id,
    required this.testName,
    required this.value,
    required this.unit,
    required this.normalMin,
    required this.normalMax,
    required this.testDate,  // 🔧 FIXED: parameter name matches field
    this.notes,
  });

  // 🆕 ADDED: Getter for backward compatibility
  DateTime get date => testDate;

  bool get isAbnormal => value < normalMin || value > normalMax;

  String get status {
    if (value < normalMin) return 'low';
    if (value > normalMax) return 'high';
    return 'normal';
  }

  // 🆕 ADDED: AbnormalityType getter
  AbnormalityType get abnormalityType {
    if (value < normalMin) return AbnormalityType.low;
    if (value > normalMax) return AbnormalityType.high;
    return AbnormalityType.normal;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'testName': testName,
    'value': value,
    'unit': unit,
    'normalMin': normalMin,
    'normalMax': normalMax,
    'testDate': testDate.toIso8601String(),
    'notes': notes,
  };

  factory LabReading.fromJson(Map<String, dynamic> json) {
    return LabReading(
      id: json['id'],
      testName: json['testName'],
      value: json['value'].toDouble(),
      unit: json['unit'],
      normalMin: json['normalMin'].toDouble(),
      normalMax: json['normalMax'].toDouble(),
      testDate: DateTime.parse(json['testDate']),
      notes: json['notes'],
    );
  }
}

// ==================== CLINICAL FEATURE MODEL (UPDATED) ====================

class ClinicalFeature {
  final String id;
  final String name;
  final bool isPresent;
  final String severity; // "mild", "moderate", "severe"
  final String notes;
  final DateTime? onsetDate;
  final FeatureType type;  // 🆕 ADDED: Feature type field

  ClinicalFeature({
    required this.id,
    required this.name,
    required this.isPresent,
    this.severity = 'mild',
    this.notes = '',
    this.onsetDate,
    this.type = FeatureType.symptom,  // 🆕 ADDED: with default
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isPresent': isPresent,
    'severity': severity,
    'notes': notes,
    'onsetDate': onsetDate?.toIso8601String(),
    'type': type.toString().split('.').last,  // 🆕 ADDED
  };

  factory ClinicalFeature.fromJson(Map<String, dynamic> json) {
    return ClinicalFeature(
      id: json['id'],
      name: json['name'],
      isPresent: json['isPresent'],
      severity: json['severity'] ?? 'mild',
      notes: json['notes'] ?? '',
      onsetDate: json['onsetDate'] != null ? DateTime.parse(json['onsetDate']) : null,
      type: json['type'] != null
          ? FeatureType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => FeatureType.symptom,
      )
          : FeatureType.symptom,  // 🆕 ADDED
    );
  }
}

// ==================== COMPLICATION MODEL ====================

class Complication {
  final String id;
  final String name;
  final bool isPresent;
  final String? severity;
  final String notes;
  final DateTime? onsetDate;

  Complication({
    required this.id,
    required this.name,
    required this.isPresent,
    this.severity,
    this.notes = '',
    this.onsetDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isPresent': isPresent,
    'severity': severity,
    'notes': notes,
    'onsetDate': onsetDate?.toIso8601String(),
  };

  factory Complication.fromJson(Map<String, dynamic> json) {
    return Complication(
      id: json['id'],
      name: json['name'],
      isPresent: json['isPresent'],
      severity: json['severity'],
      notes: json['notes'] ?? '',
      onsetDate: json['onsetDate'] != null ? DateTime.parse(json['onsetDate']) : null,
    );
  }
}

// ==================== MEDICATION MODEL ====================

class Medication {
  final String id;
  final String name;
  final String dose;
  final String frequency;
  final String route;
  final DateTime startDate;
  final DateTime? endDate;
  final String indication;
  final bool isActive;
  final String notes;

  Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.frequency,
    this.route = 'Oral',
    required this.startDate,
    this.endDate,
    this.indication = '',
    this.isActive = true,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dose': dose,
    'frequency': frequency,
    'route': route,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'indication': indication,
    'isActive': isActive,
    'notes': notes,
  };

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      dose: json['dose'],
      frequency: json['frequency'],
      route: json['route'] ?? 'Oral',
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      indication: json['indication'] ?? '',
      isActive: json['isActive'] ?? true,
      notes: json['notes'] ?? '',
    );
  }
}

// ==================== MEDICAL IMAGE MODEL ====================

class MedicalImage {
  final String id;
  final String type; // "ultrasound", "ct", "clinical_photo"
  final String imagePath;
  final String description;
  final DateTime captureDate;
  final List<String> annotations;

  MedicalImage({
    required this.id,
    required this.type,
    required this.imagePath,
    this.description = '',
    DateTime? captureDate,
    this.annotations = const [],
  }) : captureDate = captureDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'imagePath': imagePath,
    'description': description,
    'captureDate': captureDate.toIso8601String(),
    'annotations': annotations,
  };

  factory MedicalImage.fromJson(Map<String, dynamic> json) {
    return MedicalImage(
      id: json['id'],
      type: json['type'],
      imagePath: json['imagePath'],
      description: json['description'] ?? '',
      captureDate: DateTime.parse(json['captureDate']),
      annotations: List<String>.from(json['annotations'] ?? []),
    );
  }
}

// ==================== TREATMENT PLAN MODEL ====================

class TreatmentPlan {
  final String approach; // "medical", "radioactive_iodine", "surgery"
  final String goal;
  final Map<String, dynamic> targets; // e.g., {"TSH": "0.4-2.5"}
  final String monitoringPlan;
  final List<String> patientEducation;
  final DateTime? nextReviewDate;
  final String dietPlan;
  final String lifestylePlan;

  TreatmentPlan({
    required this.approach,
    required this.goal,
    this.targets = const {},
    this.monitoringPlan = '',
    this.patientEducation = const [],
    this.nextReviewDate,
    this.dietPlan = '',
    this.lifestylePlan = '',
  });

  Map<String, dynamic> toJson() => {
    'approach': approach,
    'goal': goal,
    'targets': targets,
    'monitoringPlan': monitoringPlan,
    'patientEducation': patientEducation,
    'nextReviewDate': nextReviewDate?.toIso8601String(),
    'dietPlan': dietPlan,
    'lifestylePlan': lifestylePlan,
  };

  factory TreatmentPlan.fromJson(Map<String, dynamic> json) {
    return TreatmentPlan(
      approach: json['approach'],
      goal: json['goal'],
      targets: Map<String, dynamic>.from(json['targets'] ?? {}),
      monitoringPlan: json['monitoringPlan'] ?? '',
      patientEducation: List<String>.from(json['patientEducation'] ?? []),
      nextReviewDate:
      json['nextReviewDate'] != null ? DateTime.parse(json['nextReviewDate']) : null,
      dietPlan: json['dietPlan'] ?? '',
      lifestylePlan: json['lifestylePlan'] ?? '',
    );
  }
}

// ==================== THYROID SPECIFIC MODELS ====================

class ThyroidExamination {
  final bool goiterPresent;
  final String? goiterGrade; // "1a", "1b", "2", "3"
  final String? consistency; // "soft", "firm", "hard"
  final bool nodulesPresent;
  final bool bruitPresent;
  final double? widthCm;
  final double? heightCm;

  ThyroidExamination({
    required this.goiterPresent,
    this.goiterGrade,
    this.consistency,
    this.nodulesPresent = false,
    this.bruitPresent = false,
    this.widthCm,
    this.heightCm,
  });

  Map<String, dynamic> toJson() => {
    'goiterPresent': goiterPresent,
    'goiterGrade': goiterGrade,
    'consistency': consistency,
    'nodulesPresent': nodulesPresent,
    'bruitPresent': bruitPresent,
    'widthCm': widthCm,
    'heightCm': heightCm,
  };

  factory ThyroidExamination.fromJson(Map<String, dynamic> json) {
    return ThyroidExamination(
      goiterPresent: json['goiterPresent'],
      goiterGrade: json['goiterGrade'],
      consistency: json['consistency'],
      nodulesPresent: json['nodulesPresent'] ?? false,
      bruitPresent: json['bruitPresent'] ?? false,
      widthCm: json['widthCm']?.toDouble(),
      heightCm: json['heightCm']?.toDouble(),
    );
  }
}

class ThyroidEyeDisease {
  final bool present;
  final double? proptosismm;
  final bool lidRetraction;
  final bool lidLag;
  final bool diplopia;
  final bool chemosis;
  final bool cornealInvolvement;
  final int? nospecsScore;
  final int? casScore;

  ThyroidEyeDisease({
    required this.present,
    this.proptosismm,
    this.lidRetraction = false,
    this.lidLag = false,
    this.diplopia = false,
    this.chemosis = false,
    this.cornealInvolvement = false,
    this.nospecsScore,
    this.casScore,
  });

  Map<String, dynamic> toJson() => {
    'present': present,
    'proptosismm': proptosismm,
    'lidRetraction': lidRetraction,
    'lidLag': lidLag,
    'diplopia': diplopia,
    'chemosis': chemosis,
    'cornealInvolvement': cornealInvolvement,
    'nospecsScore': nospecsScore,
    'casScore': casScore,
  };

  factory ThyroidEyeDisease.fromJson(Map<String, dynamic> json) {
    return ThyroidEyeDisease(
      present: json['present'],
      proptosismm: json['proptosismm']?.toDouble(),
      lidRetraction: json['lidRetraction'] ?? false,
      lidLag: json['lidLag'] ?? false,
      diplopia: json['diplopia'] ?? false,
      chemosis: json['chemosis'] ?? false,
      cornealInvolvement: json['cornealInvolvement'] ?? false,
      nospecsScore: json['nospecsScore'],
      casScore: json['casScore'],
    );
  }
}