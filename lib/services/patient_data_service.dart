// lib/services/patient_data_service.dart
// ✅ CENTRALIZED PATIENT DATA SERVICE
// Auto-fills vitals, clinical history, and measurements across all screens

import 'package:flutter/material.dart';
import '../models/consultation_data.dart';
import '../models/endocrine/endocrine_condition.dart';
import 'database_helper.dart';

class PatientDataService {
  static final PatientDataService instance = PatientDataService._init();
  PatientDataService._init();

  // ============================================
  // CORE DATA MODEL
  // ============================================

  /// Get the latest patient data from all sources
  Future<PatientDataSnapshot?> getLatestPatientData(String patientId) async {
    try {
      final data = await DatabaseHelper.instance.getLatestPatientData(patientId);
      if (data != null) {
        return PatientDataSnapshot.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error getting latest patient data: $e');
      return null;
    }
  }

  /// Get latest vitals only
  Future<Map<String, String>> getLatestVitals(String patientId) async {
    final snapshot = await getLatestPatientData(patientId);
    return snapshot?.vitals ?? {};
  }

  /// Get latest clinical history only
  Future<Map<String, String?>> getLatestClinicalHistory(String patientId) async {
    final snapshot = await getLatestPatientData(patientId);
    if (snapshot == null) return {};

    return {
      'chiefComplaint': snapshot.chiefComplaint,
      'historyOfPresentIllness': snapshot.historyOfPresentIllness,
      'pastMedicalHistory': snapshot.pastMedicalHistory,
      'familyHistory': snapshot.familyHistory,
      'allergies': snapshot.allergies,
    };
  }

  /// Get latest measurements only
  Future<Map<String, String?>> getLatestMeasurements(String patientId) async {
    final snapshot = await getLatestPatientData(patientId);
    if (snapshot == null) return {};

    return {
      'height': snapshot.height,
      'weight': snapshot.weight,
      'bmi': snapshot.bmi,
    };
  }

  // ============================================
  // UPDATE DATA (from any screen)
  // ============================================

  /// Update patient data from Consultation screen
  Future<void> updateFromConsultation(ConsultationData consultationData) async {
    final snapshot = PatientDataSnapshot(
      patientId: consultationData.patient.id,
      chiefComplaint: consultationData.chiefComplaint,
      historyOfPresentIllness: consultationData.historyOfPresentIllness,
      pastMedicalHistory: consultationData.pastMedicalHistory,
      familyHistory: consultationData.familyHistory,
      allergies: consultationData.allergies,
      vitals: consultationData.vitals,
      height: consultationData.height,
      weight: consultationData.weight,
      bmi: consultationData.bmi,
      lastUpdated: DateTime.now(),
      updatedFrom: 'consultation',
    );

    await DatabaseHelper.instance.savePatientData(snapshot.toJson());
  }

  /// Update patient data from Endocrine module
  Future<void> updateFromEndocrine(EndocrineCondition condition) async {
    final snapshot = PatientDataSnapshot(
      patientId: condition.patientId,
      chiefComplaint: condition.chiefComplaint,
      historyOfPresentIllness: condition.historyOfPresentIllness,
      pastMedicalHistory: condition.pastMedicalHistory,
      familyHistory: condition.familyHistory,
      allergies: condition.allergies,
      vitals: condition.vitals ?? {},
      height: condition.measurements?['height'],
      weight: condition.measurements?['weight'],
      bmi: condition.measurements?['bmi'],
      lastUpdated: DateTime.now(),
      updatedFrom: 'endocrine',
    );

    await DatabaseHelper.instance.savePatientData(snapshot.toJson());
  }

  /// Update specific vitals only
  Future<void> updateVitals(String patientId, Map<String, String> vitals) async {
    final existing = await getLatestPatientData(patientId);

    final snapshot = PatientDataSnapshot(
      patientId: patientId,
      chiefComplaint: existing?.chiefComplaint,
      historyOfPresentIllness: existing?.historyOfPresentIllness,
      pastMedicalHistory: existing?.pastMedicalHistory,
      familyHistory: existing?.familyHistory,
      allergies: existing?.allergies,
      vitals: vitals,
      height: existing?.height,
      weight: existing?.weight,
      bmi: existing?.bmi,
      lastUpdated: DateTime.now(),
      updatedFrom: 'manual',
    );

    await DatabaseHelper.instance.savePatientData(snapshot.toJson());
  }

  // ============================================
  // AUTO-FILL HELPERS
  // ============================================

  /// Auto-fill ConsultationData from latest patient data
  Future<void> autoFillConsultationData(ConsultationData consultationData) async {
    final snapshot = await getLatestPatientData(consultationData.patient.id);
    if (snapshot == null) return;

    // Only fill if fields are empty (don't overwrite existing data)
    if (consultationData.chiefComplaint.isEmpty && snapshot.chiefComplaint != null) {
      consultationData.updateChiefComplaint(snapshot.chiefComplaint!);
    }

    if (consultationData.historyOfPresentIllness.isEmpty && snapshot.historyOfPresentIllness != null) {
      consultationData.updateHistoryOfPresentIllness(snapshot.historyOfPresentIllness!);
    }

    if (consultationData.pastMedicalHistory.isEmpty && snapshot.pastMedicalHistory != null) {
      consultationData.updatePastMedicalHistory(snapshot.pastMedicalHistory!);
    }

    if (consultationData.familyHistory.isEmpty && snapshot.familyHistory != null) {
      consultationData.familyHistory = snapshot.familyHistory!;
    }

    if (consultationData.allergies.isEmpty && snapshot.allergies != null) {
      consultationData.allergies = snapshot.allergies!;
    }

    // Auto-fill vitals
    if (consultationData.vitals.isEmpty && snapshot.vitals.isNotEmpty) {
      consultationData.vitals = Map<String, String>.from(snapshot.vitals);
    }

    // Auto-fill measurements
    if (consultationData.height == null && snapshot.height != null) {
      consultationData.updateMeasurements(height: snapshot.height);
    }

    if (consultationData.weight == null && snapshot.weight != null) {
      consultationData.updateMeasurements(weight: snapshot.weight);
    }

    consultationData.notifyListeners();
  }

  /// Auto-fill EndocrineCondition from latest patient data
  Future<EndocrineCondition> autoFillEndocrineCondition(EndocrineCondition condition) async {
    final snapshot = await getLatestPatientData(condition.patientId);
    if (snapshot == null) return condition;

    // Only fill if fields are empty
    return condition.copyWith(
      chiefComplaint: condition.chiefComplaint ?? snapshot.chiefComplaint,
      historyOfPresentIllness: condition.historyOfPresentIllness ?? snapshot.historyOfPresentIllness,
      pastMedicalHistory: condition.pastMedicalHistory ?? snapshot.pastMedicalHistory,
      familyHistory: condition.familyHistory ?? snapshot.familyHistory,
      allergies: condition.allergies ?? snapshot.allergies,
      vitals: (condition.vitals == null || condition.vitals!.isEmpty)
          ? snapshot.vitals
          : condition.vitals,
      measurements: (condition.measurements == null || condition.measurements!.isEmpty)
          ? {
        'height': snapshot.height ?? '',
        'weight': snapshot.weight ?? '',
        'bmi': snapshot.bmi ?? '',
      }
          : condition.measurements,
    );
  }

  // ============================================
  // SHOW AUTO-FILL DIALOG
  // ============================================

  /// Show dialog asking user if they want to auto-fill data
  Future<bool> showAutoFillDialog(
      BuildContext context, {
        required String patientName,
        required DateTime lastUpdated,
        required String updatedFrom,
      }) async {
    final timeDiff = DateTime.now().difference(lastUpdated);
    String timeAgo;

    if (timeDiff.inMinutes < 60) {
      timeAgo = '${timeDiff.inMinutes} minutes ago';
    } else if (timeDiff.inHours < 24) {
      timeAgo = '${timeDiff.inHours} hours ago';
    } else {
      timeAgo = '${timeDiff.inDays} days ago';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            const Text('Auto-fill Patient Data?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Previous data found for $patientName:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Last updated: $timeAgo',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.source, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Source: ${_formatSource(updatedFrom)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This will pre-fill:\n'
                  '• Vitals (BP, HR, Temp, SpO2, RR)\n'
                  '• Measurements (Height, Weight, BMI)\n'
                  '• Clinical history\n'
                  '• Allergies',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Text(
              'You can edit any field after auto-filling.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Auto-fill'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  String _formatSource(String source) {
    switch (source) {
      case 'consultation':
        return 'Consultation Screen';
      case 'endocrine':
        return 'Thyroid Module';
      case 'manual':
        return 'Manual Entry';
      default:
        return source;
    }
  }
}

// ============================================
// PATIENT DATA SNAPSHOT MODEL
// ============================================

/// Complete patient data snapshot with timestamps
class PatientDataSnapshot {
  final String patientId;

  // Clinical History
  final String? chiefComplaint;
  final String? historyOfPresentIllness;
  final String? pastMedicalHistory;
  final String? familyHistory;
  final String? allergies;

  // Vitals
  final Map<String, String> vitals;

  // Measurements
  final String? height;
  final String? weight;
  final String? bmi;

  // Metadata
  final DateTime lastUpdated;
  final String updatedFrom; // 'consultation' or 'endocrine' or 'manual'

  PatientDataSnapshot({
    required this.patientId,
    this.chiefComplaint,
    this.historyOfPresentIllness,
    this.pastMedicalHistory,
    this.familyHistory,
    this.allergies,
    this.vitals = const {},
    this.height,
    this.weight,
    this.bmi,
    required this.lastUpdated,
    required this.updatedFrom,
  });

  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'chiefComplaint': chiefComplaint,
    'historyOfPresentIllness': historyOfPresentIllness,
    'pastMedicalHistory': pastMedicalHistory,
    'familyHistory': familyHistory,
    'allergies': allergies,
    'vitals': vitals,
    'height': height,
    'weight': weight,
    'bmi': bmi,
    'lastUpdated': lastUpdated.toIso8601String(),
    'updatedFrom': updatedFrom,
  };

  factory PatientDataSnapshot.fromJson(Map<String, dynamic> json) {
    return PatientDataSnapshot(
      patientId: json['patientId'] as String,
      chiefComplaint: json['chiefComplaint'] as String?,
      historyOfPresentIllness: json['historyOfPresentIllness'] as String?,
      pastMedicalHistory: json['pastMedicalHistory'] as String?,
      familyHistory: json['familyHistory'] as String?,
      allergies: json['allergies'] as String?,
      vitals: json['vitals'] != null
          ? Map<String, String>.from(json['vitals'] as Map)
          : {},
      height: json['height'] as String?,
      weight: json['weight'] as String?,
      bmi: json['bmi'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      updatedFrom: json['updatedFrom'] as String,
    );
  }
}