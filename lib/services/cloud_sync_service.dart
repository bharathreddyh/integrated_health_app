// lib/services/cloud_sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/patient.dart';
import 'database_helper.dart';

/// Cloud Sync Service
/// Synchronizes local SQLite data with Firebase Firestore
/// Ensures patient data is accessible across all logged-in devices
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get user's Firestore collection reference
  CollectionReference? get _userPatientsCollection {
    if (_currentUserId == null) return null;
    return _firestore.collection('users').doc(_currentUserId).collection('patients');
  }

  // ==================== PATIENT SYNC ====================

  /// Sync a patient to Firestore
  Future<void> syncPatientToCloud(Patient patient) async {
    if (_currentUserId == null) {
      print('⚠️ Cannot sync: User not authenticated');
      return;
    }

    try {
      final patientData = {
        'id': patient.id,
        'name': patient.name,
        'age': patient.age,
        'phone': patient.phone,
        'date': patient.date,
        'conditions': patient.conditions,
        'notes': patient.notes,
        'visits': patient.visits,
        'vitals': patient.vitals?.toJson(),
        'userId': _currentUserId,
        'lastModified': FieldValue.serverTimestamp(),
        'syncedAt': FieldValue.serverTimestamp(),
      };

      await _userPatientsCollection!.doc(patient.id).set(
        patientData,
        SetOptions(merge: true),
      );

      print('✅ Patient synced to cloud: ${patient.name}');
    } catch (e) {
      print('❌ Error syncing patient to cloud: $e');
      rethrow;
    }
  }

  /// Sync all patients to Firestore
  Future<void> syncAllPatientsToCloud() async {
    if (_currentUserId == null) {
      print('⚠️ Cannot sync: User not authenticated');
      return;
    }

    try {
      final patients = await DatabaseHelper.instance.getPatients();
      print('📤 Syncing ${patients.length} patients to cloud...');

      for (final patient in patients) {
        await syncPatientToCloud(patient);
      }

      _lastSyncTime = DateTime.now();
      print('✅ All patients synced to cloud');
    } catch (e) {
      print('❌ Error syncing patients to cloud: $e');
      rethrow;
    }
  }

  /// Sync patients from Firestore to local database
  Future<void> syncPatientsFromCloud() async {
    if (_currentUserId == null) {
      print('⚠️ Cannot sync: User not authenticated');
      return;
    }

    if (_isSyncing) {
      print('⏳ Sync already in progress...');
      return;
    }

    _isSyncing = true;

    try {
      print('📥 Syncing patients from cloud...');

      final snapshot = await _userPatientsCollection!.get();
      final cloudPatients = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Patient.fromMap(data);
      }).toList();

      print('📥 Found ${cloudPatients.length} patients in cloud');

      // Get local patients
      final localPatients = await DatabaseHelper.instance.getPatients();
      final localPatientIds = localPatients.map((p) => p.id).toSet();

      // Sync each cloud patient to local database
      for (final patient in cloudPatients) {
        if (localPatientIds.contains(patient.id)) {
          // Update existing patient
          await DatabaseHelper.instance.updatePatient(patient);
          print('🔄 Updated patient: ${patient.name}');
        } else {
          // Insert new patient
          await DatabaseHelper.instance.insertPatient(patient);
          print('➕ Added patient: ${patient.name}');
        }
      }

      _lastSyncTime = DateTime.now();
      print('✅ Patients synced from cloud successfully');
    } catch (e) {
      print('❌ Error syncing patients from cloud: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Delete patient from Firestore
  Future<void> deletePatientFromCloud(String patientId) async {
    if (_currentUserId == null) {
      print('⚠️ Cannot delete: User not authenticated');
      return;
    }

    try {
      await _userPatientsCollection!.doc(patientId).delete();
      print('✅ Patient deleted from cloud: $patientId');
    } catch (e) {
      print('❌ Error deleting patient from cloud: $e');
      rethrow;
    }
  }

  // ==================== VISIT SYNC ====================

  /// Sync a visit to Firestore
  Future<void> syncVisitToCloud(String patientId, Map<String, dynamic> visitData) async {
    if (_currentUserId == null) {
      print('⚠️ Cannot sync: User not authenticated');
      return;
    }

    try {
      final visitWithTimestamp = {
        ...visitData,
        'userId': _currentUserId,
        'patientId': patientId,
        'syncedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('visits')
          .doc(visitData['id'] as String)
          .set(visitWithTimestamp, SetOptions(merge: true));

      print('✅ Visit synced to cloud');
    } catch (e) {
      print('❌ Error syncing visit to cloud: $e');
      rethrow;
    }
  }

  /// Sync all visits for a patient from cloud
  Future<List<Map<String, dynamic>>> syncVisitsFromCloud(String patientId) async {
    if (_currentUserId == null) {
      print('⚠️ Cannot sync: User not authenticated');
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('visits')
          .where('patientId', isEqualTo: patientId)
          .orderBy('visitDate', descending: true)
          .get();

      final visits = snapshot.docs.map((doc) => doc.data()).toList();
      print('📥 Synced ${visits.length} visits from cloud');
      return visits;
    } catch (e) {
      print('❌ Error syncing visits from cloud: $e');
      return [];
    }
  }

  // ==================== PRESCRIPTION SYNC ====================

  /// Sync prescription to Firestore
  Future<void> syncPrescriptionToCloud(Map<String, dynamic> prescriptionData) async {
    if (_currentUserId == null) {
      print('⚠️ Cannot sync: User not authenticated');
      return;
    }

    try {
      final prescriptionWithTimestamp = {
        ...prescriptionData,
        'userId': _currentUserId,
        'syncedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('prescriptions')
          .doc(prescriptionData['id'] as String)
          .set(prescriptionWithTimestamp, SetOptions(merge: true));

      print('✅ Prescription synced to cloud');
    } catch (e) {
      print('❌ Error syncing prescription to cloud: $e');
      rethrow;
    }
  }

  // ==================== LAB TEST SYNC ====================

  /// Sync lab test to Firestore
  Future<void> syncLabTestToCloud(Map<String, dynamic> labTestData) async {
    if (_currentUserId == null) {
      print('⚠️ Cannot sync: User not authenticated');
      return;
    }

    try {
      final labTestWithTimestamp = {
        ...labTestData,
        'userId': _currentUserId,
        'syncedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('lab_tests')
          .doc(labTestData['id'] as String)
          .set(labTestWithTimestamp, SetOptions(merge: true));

      print('✅ Lab test synced to cloud');
    } catch (e) {
      print('❌ Error syncing lab test to cloud: $e');
      rethrow;
    }
  }

  // ==================== FULL SYNC ====================

  /// Perform full bidirectional sync
  /// 1. Pull latest data from cloud
  /// 2. Push local changes to cloud
  Future<void> performFullSync() async {
    if (_currentUserId == null) {
      print('⚠️ Cannot sync: User not authenticated');
      return;
    }

    if (_isSyncing) {
      print('⏳ Sync already in progress...');
      return;
    }

    _isSyncing = true;

    try {
      print('🔄 Starting full sync...');

      // Step 1: Pull from cloud
      await syncPatientsFromCloud();

      // Step 2: Push to cloud (in case local has newer data)
      await syncAllPatientsToCloud();

      _lastSyncTime = DateTime.now();
      print('✅ Full sync completed successfully');
    } catch (e) {
      print('❌ Full sync error: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Enable real-time sync listener for patients
  Stream<List<Patient>> watchPatientsFromCloud() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _userPatientsCollection!.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Patient.fromMap(data);
      }).toList();
    });
  }

  // ==================== SYNC STATUS ====================

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Get time since last sync
  Duration? get timeSinceLastSync {
    if (_lastSyncTime == null) return null;
    return DateTime.now().difference(_lastSyncTime!);
  }
}
