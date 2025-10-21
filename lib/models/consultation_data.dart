import 'package:flutter/foundation.dart';
import 'patient.dart';
import 'prescription.dart';
import 'lab_result.dart';
import 'visit.dart';
import '../services/database_helper.dart';

class ConsultationData extends ChangeNotifier {
  // ============================================
  // PATIENT INFO
  // ============================================
  final Patient patient;

  // ============================================
  // PAGE 1: PATIENT DATA ENTRY
  // ============================================
  String chiefComplaint = '';
  String historyOfPresentIllness = '';
  String pastMedicalHistory = '';
  String familyHistory = '';
  String allergies = '';

  Map<String, String> vitals = {};
  String? height;
  String? weight;
  String? bmi;

  List<LabResult> labResults = [];

  // ============================================
  // PAGE 2: VISUAL CONTENT SELECTION
  // ============================================
  List<int> selectedDiagramIds = [];                      // Saved diagrams from canvas
  List<Map<String, dynamic>> completedTemplates = [];     // Completed disease templates
  List<Map<String, dynamic>> annotatedAnatomies = [];     // Annotated anatomy diagrams

  // Legacy support (if needed)
  List<String> selectedTemplateIds = [];
  List<dynamic> selectedAnatomies = [];

  // ============================================
  // PAGE 3: DIAGNOSIS & TREATMENT
  // ============================================
  String diagnosis = '';
  List<Prescription> prescriptions = [];
  String dietPlan = '';
  String lifestylePlan = '';
  String followUpInstructions = '';

  // Lab tests and investigations
  List<Map<String, dynamic>> orderedLabTests = [];
  List<Map<String, dynamic>> orderedInvestigations = [];

  // ============================================
  // AUTO-SAVE TRACKING
  // ============================================
  DateTime? lastSaved;
  bool hasUnsavedChanges = false;

  // ============================================
  // CONSTRUCTOR
  // ============================================
  ConsultationData({required this.patient});

  // ============================================
  // PAGE 1 METHODS
  // ============================================
  void updateChiefComplaint(String value) {
    chiefComplaint = value;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateHistoryOfPresentIllness(String value) {
    historyOfPresentIllness = value;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void updatePastMedicalHistory(String value) {
    pastMedicalHistory = value;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateVital(String key, String value) {
    vitals[key] = value;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateMeasurements({String? height, String? weight}) {
    if (height != null) this.height = height;
    if (weight != null) this.weight = weight;

    // Calculate BMI if both height and weight are available
    if (this.height != null &&
        this.weight != null &&
        this.height!.isNotEmpty &&
        this.weight!.isNotEmpty) {
      try {
        final h = double.parse(this.height!) / 100; // cm to m
        final w = double.parse(this.weight!);
        bmi = (w / (h * h)).toStringAsFixed(1);
      } catch (e) {
        bmi = null;
      }
    } else {
      bmi = null;
    }

    hasUnsavedChanges = true;
    notifyListeners();
  }

  void addLabResult(LabResult result) {
    labResults.add(result);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void removeLabResult(int index) {
    if (index >= 0 && index < labResults.length) {
      labResults.removeAt(index);
      hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void updateLabResult(int index, LabResult result) {
    if (index >= 0 && index < labResults.length) {
      labResults[index] = result;
      hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // ============================================
  // PAGE 2 METHODS - SAVED DIAGRAMS
  // ============================================
  void addSavedDiagram(int visitId) {
    if (!selectedDiagramIds.contains(visitId)) {
      selectedDiagramIds.add(visitId);
      hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void removeSavedDiagram(int visitId) {
    selectedDiagramIds.remove(visitId);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  // ============================================
  // PAGE 2 METHODS - COMPLETED TEMPLATES
  // ============================================
  void addCompletedTemplate(Map<String, dynamic> template) {
    // Ensure template has required fields
    final templateData = {
      'templateId': template['templateId'],
      'templateName': template['templateName'],
      'data': template['data'],
      'createdAt': template['createdAt'] ?? DateTime.now().toIso8601String(),
    };

    completedTemplates.add(templateData);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void removeCompletedTemplate(int index) {
    if (index >= 0 && index < completedTemplates.length) {
      completedTemplates.removeAt(index);
      hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void updateCompletedTemplate(int index, Map<String, dynamic> template) {
    if (index >= 0 && index < completedTemplates.length) {
      completedTemplates[index] = template;
      hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // ============================================
  // PAGE 2 METHODS - ANNOTATED ANATOMIES
  // ============================================
  void addAnnotatedAnatomy(Map<String, dynamic> anatomy) {
    // Ensure anatomy has required fields
    final anatomyData = {
      'visitId': anatomy['visitId'],
      'systemName': anatomy['systemName'],
      'systemId': anatomy['systemId'],
      'viewType': anatomy['viewType'],
      'createdAt': anatomy['createdAt'] ?? DateTime.now().toIso8601String(),
      'hasAnnotations': anatomy['hasAnnotations'] ?? false,
    };

    annotatedAnatomies.add(anatomyData);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void removeAnnotatedAnatomy(int index) {
    if (index >= 0 && index < annotatedAnatomies.length) {
      annotatedAnatomies.removeAt(index);
      hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void updateAnnotatedAnatomy(int index, Map<String, dynamic> anatomy) {
    if (index >= 0 && index < annotatedAnatomies.length) {
      annotatedAnatomies[index] = anatomy;
      hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // ============================================
  // PAGE 3 METHODS
  // ============================================
  void updateDiagnosis(String value) {
    diagnosis = value;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void addPrescription(Prescription prescription) {
    prescriptions.add(prescription);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void removePrescription(int index) {
    if (index >= 0 && index < prescriptions.length) {
      prescriptions.removeAt(index);
      hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void updatePrescription(int index, Prescription prescription) {
    if (index >= 0 && index < prescriptions.length) {
      prescriptions[index] = prescription;
      hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void updateDietPlan(String value) {
    dietPlan = value;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateLifestylePlan(String value) {
    lifestylePlan = value;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateFollowUpInstructions(String value) {
    followUpInstructions = value;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateOrderedLabTests(List<Map<String, dynamic>> tests) {
    orderedLabTests = tests;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateOrderedInvestigations(List<Map<String, dynamic>> investigations) {
    orderedInvestigations = investigations;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  // ============================================
  // COMPLETION CHECKS
  // ============================================
  bool get isPage1Complete {
    return chiefComplaint.isNotEmpty && vitals.isNotEmpty;
  }

  bool get isPage2Complete {
    return selectedDiagramIds.isNotEmpty ||
        completedTemplates.isNotEmpty ||
        annotatedAnatomies.isNotEmpty;
  }

  bool get isPage3Complete {
    return diagnosis.isNotEmpty;
  }

  bool get canGeneratePDF {
    return isPage1Complete && isPage3Complete;
  }

  double get completionPercentage {
    int completed = 0;
    int total = 3;

    if (isPage1Complete) completed++;
    if (isPage2Complete) completed++;
    if (isPage3Complete) completed++;

    return (completed / total) * 100;
  }

  // ============================================
  // PAGE 2 SUMMARY FOR DISPLAY
  // ============================================
  Map<String, int> get page2Summary {
    return {
      'diagrams': selectedDiagramIds.length,
      'templates': completedTemplates.length,
      'anatomies': annotatedAnatomies.length,
    };
  }

  int get totalPage2Items {
    return selectedDiagramIds.length +
        completedTemplates.length +
        annotatedAnatomies.length;
  }

  // ============================================
  // PDF GENERATION HELPER
  // ============================================
  Future<List<Visit>> getVisitsForPDF() async {
    final List<Visit> visits = [];

    // Get saved diagrams
    for (final diagramId in selectedDiagramIds) {
      final visit = await DatabaseHelper.instance.getVisitById(diagramId);
      if (visit != null) visits.add(visit);
    }

    // Get annotated anatomies
    for (final anatomy in annotatedAnatomies) {
      final visitId = anatomy['visitId'] as int?;
      if (visitId != null) {
        final visit = await DatabaseHelper.instance.getVisitById(visitId);
        if (visit != null) visits.add(visit);
      }
    }

    return visits;
  }

  // ============================================
  // AUTO-SAVE TRACKING
  // ============================================
  void markAsSaved() {
    lastSaved = DateTime.now();
    hasUnsavedChanges = false;
    notifyListeners();
  }

  void markAsChanged() {
    hasUnsavedChanges = true;
    notifyListeners();
  }

  // ============================================
  // DRAFT SAVE/LOAD
  // ============================================
  Map<String, dynamic> toDraftJson() {
    return {
      // Patient Info
      'patientId': patient.id,

      // Page 1 Data
      'chiefComplaint': chiefComplaint,
      'historyOfPresentIllness': historyOfPresentIllness,
      'pastMedicalHistory': pastMedicalHistory,
      'familyHistory': familyHistory,
      'allergies': allergies,
      'vitals': vitals,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'labResults': labResults.map((r) => r.toJson()).toList(),

      // Page 2 Data
      'selectedDiagramIds': selectedDiagramIds,
      'completedTemplates': completedTemplates,
      'annotatedAnatomies': annotatedAnatomies,

      // Page 3 Data
      'diagnosis': diagnosis,
      'prescriptions': prescriptions.map((p) => p.toJson()).toList(),
      'dietPlan': dietPlan,
      'lifestylePlan': lifestylePlan,
      'followUpInstructions': followUpInstructions,
      'orderedLabTests': orderedLabTests,
      'orderedInvestigations': orderedInvestigations,

      // Metadata
      'lastSaved': DateTime.now().toIso8601String(),
    };
  }

  void loadFromDraft(Map<String, dynamic> draft) {
    // Page 1 Data
    chiefComplaint = draft['chiefComplaint'] ?? '';
    historyOfPresentIllness = draft['historyOfPresentIllness'] ?? '';
    pastMedicalHistory = draft['pastMedicalHistory'] ?? '';
    familyHistory = draft['familyHistory'] ?? '';
    allergies = draft['allergies'] ?? '';
    vitals = Map<String, String>.from(draft['vitals'] ?? {});
    height = draft['height'];
    weight = draft['weight'];
    bmi = draft['bmi'];

    if (draft['labResults'] != null) {
      labResults = (draft['labResults'] as List)
          .map((r) => LabResult.fromJson(r))
          .toList();
    }

    // Page 2 Data
    if (draft['selectedDiagramIds'] != null) {
      selectedDiagramIds = List<int>.from(draft['selectedDiagramIds']);
    }

    if (draft['completedTemplates'] != null) {
      completedTemplates = List<Map<String, dynamic>>.from(
          draft['completedTemplates']
      );
    }

    if (draft['annotatedAnatomies'] != null) {
      annotatedAnatomies = List<Map<String, dynamic>>.from(
          draft['annotatedAnatomies']
      );
    }

    // Page 3 Data
    diagnosis = draft['diagnosis'] ?? '';

    if (draft['prescriptions'] != null) {
      prescriptions = (draft['prescriptions'] as List)
          .map((p) => Prescription.fromJson(p))
          .toList();
    }

    dietPlan = draft['dietPlan'] ?? '';
    lifestylePlan = draft['lifestylePlan'] ?? '';
    followUpInstructions = draft['followUpInstructions'] ?? '';

    if (draft['orderedLabTests'] != null) {
      orderedLabTests = List<Map<String, dynamic>>.from(
          draft['orderedLabTests']
      );
    }

    if (draft['orderedInvestigations'] != null) {
      orderedInvestigations = List<Map<String, dynamic>>.from(
          draft['orderedInvestigations']
      );
    }

    // Metadata
    if (draft['lastSaved'] != null) {
      lastSaved = DateTime.parse(draft['lastSaved']);
    }

    hasUnsavedChanges = false;
    notifyListeners();
  }

  // ============================================
  // RESET/CLEAR METHODS
  // ============================================
  void clearPage1() {
    chiefComplaint = '';
    historyOfPresentIllness = '';
    pastMedicalHistory = '';
    familyHistory = '';
    allergies = '';
    vitals.clear();
    height = null;
    weight = null;
    bmi = null;
    labResults.clear();
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void clearPage2() {
    selectedDiagramIds.clear();
    completedTemplates.clear();
    annotatedAnatomies.clear();
    selectedTemplateIds.clear();
    selectedAnatomies.clear();
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void clearPage3() {
    diagnosis = '';
    prescriptions.clear();
    dietPlan = '';
    lifestylePlan = '';
    followUpInstructions = '';
    orderedLabTests.clear();
    orderedInvestigations.clear();
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void clearAll() {
    clearPage1();
    clearPage2();
    clearPage3();
    lastSaved = null;
    hasUnsavedChanges = false;
    notifyListeners();
  }

  // ============================================
  // VALIDATION HELPERS
  // ============================================
  List<String> getValidationErrors() {
    final errors = <String>[];

    // Page 1 validation
    if (chiefComplaint.isEmpty) {
      errors.add('Chief complaint is required');
    }
    if (vitals.isEmpty) {
      errors.add('At least one vital sign is required');
    }

    // Page 3 validation
    if (diagnosis.isEmpty) {
      errors.add('Diagnosis is required');
    }

    return errors;
  }

  bool get isValid {
    return getValidationErrors().isEmpty;
  }

  // ============================================
  // DEBUG/LOGGING
  // ============================================
  void printSummary() {
    print('═══════════════════════════════════════');
    print('CONSULTATION DATA SUMMARY');
    print('═══════════════════════════════════════');
    print('Patient: ${patient.name} (${patient.id})');
    print('');
    print('PAGE 1:');
    print('  Chief Complaint: ${chiefComplaint.isNotEmpty ? '✓' : '✗'}');
    print('  Vitals: ${vitals.length} recorded');
    print('  Lab Results: ${labResults.length}');
    print('');
    print('PAGE 2:');
    print('  Saved Diagrams: ${selectedDiagramIds.length}');
    print('  Completed Templates: ${completedTemplates.length}');
    print('  Annotated Anatomies: ${annotatedAnatomies.length}');
    print('  Total Items: $totalPage2Items');
    print('');
    print('PAGE 3:');
    print('  Diagnosis: ${diagnosis.isNotEmpty ? '✓' : '✗'}');
    print('  Prescriptions: ${prescriptions.length}');
    print('  Lab Tests Ordered: ${orderedLabTests.length}');
    print('  Investigations Ordered: ${orderedInvestigations.length}');
    print('');
    print('STATUS:');
    print('  Completion: ${completionPercentage.toInt()}%');
    print('  Can Generate PDF: ${canGeneratePDF ? 'Yes' : 'No'}');
    print('  Unsaved Changes: ${hasUnsavedChanges ? 'Yes' : 'No'}');
    if (lastSaved != null) {
      print('  Last Saved: $lastSaved');
    }
    print('═══════════════════════════════════════');
  }
}