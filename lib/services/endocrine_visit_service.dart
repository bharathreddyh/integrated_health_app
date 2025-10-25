// ==================== ENDOCRINE VISIT SERVICE ====================
// lib/services/endocrine_visit_service.dart

import '../models/endocrine/endocrine_condition.dart';
import '../database/database_helper.dart';

class EndocrineVisitService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Save a complete visit
  Future<String> saveVisit({
    required EndocrineCondition condition,
    required String doctorId,
  }) async {
    return await _db.saveEndocrineVisit(condition, doctorId);
  }

  // Get all visits for a patient
  Future<List<EndocrineCondition>> getPatientVisits(String patientId) async {
    return await _db.getEndocrineVisitsByPatient(patientId);
  }

  // Get visits for a specific disease
  Future<List<EndocrineCondition>> getDiseaseVisits(String patientId, String diseaseId) async {
    return await _db.getEndocrineVisitsByDisease(patientId, diseaseId);
  }

  // Load previous visit data for comparison
  Future<EndocrineCondition?> getLastVisit(String patientId, String diseaseId) async {
    return await _db.getLatestEndocrineVisit(patientId, diseaseId);
  }

  // Get comparison between current and previous visit
  Future<Map<String, dynamic>> getVisitComparison(String patientId, String diseaseId) async {
    return await _db.getComparisonData(patientId, diseaseId);
  }

  // Get lab trends over time for a specific test
  Future<List<Map<String, dynamic>>> getLabTrends(String patientId, String testName) async {
    return await _db.getLabTrendsForPatient(patientId, testName);
  }

  // Get visit timeline summary
  Future<List<Map<String, dynamic>>> getVisitTimeline(String patientId) async {
    final visits = await getPatientVisits(patientId);

    return visits.map((visit) => {
      'id': visit.id,
      'date': visit.createdAt,
      'disease': visit.diseaseName,
      'status': visit.status,
      'severity': visit.severity,
      'labCount': visit.labReadings.length,
      'medicationCount': visit.medications.where((m) => m.isActive).length,
      'complicationCount': visit.complications.length,
    }).toList();
  }

  // Pre-fill form with previous visit data
  Future<EndocrineCondition?> prepareNewVisitFromPrevious({
    required String patientId,
    required String diseaseId,
    required String patientName,
  }) async {
    final lastVisit = await getLastVisit(patientId, diseaseId);

    if (lastVisit == null) return null;

    // Create new visit with some data carried over
    return EndocrineCondition(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: patientId,
      patientName: patientName,
      gland: lastVisit.gland,
      category: lastVisit.category,
      diseaseId: lastVisit.diseaseId,
      diseaseName: lastVisit.diseaseName,
      status: lastVisit.status,

      // Carry over stable patient data
      pastMedicalHistory: lastVisit.pastMedicalHistory,
      familyHistory: lastVisit.familyHistory,
      allergies: lastVisit.allergies,

      // Carry over active medications (for review)
      medications: lastVisit.medications.where((m) => m.isActive).toList(),

      // Reset visit-specific data
      chiefComplaint: null,
      historyOfPresentIllness: null,
      vitals: null,
      measurements: null,
      labReadings: [],
      clinicalFeatures: [],
      images: [],
      complications: [],
      notes: '',
      followUpPlan: '',

      severity: null,
      diagnosisDate: null,
      treatmentPlan: null,
      nextVisit: null,

      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      isActive: true,
    );
  }

  // Generate visit summary for reports
  Future<Map<String, dynamic>> generateVisitSummary(String visitId) async {
    // Implementation would load visit and generate summary
    return {};
  }
}