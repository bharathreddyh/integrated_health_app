// lib/services/cloud_sync_service.dart
// Stub for cloud sync functionality (no-op until implemented).

class CloudSyncService {
  CloudSyncService();

  bool get isAuthenticated => false;

  Future<void> syncPatientToCloud(dynamic patient) async {}

  Future<void> deletePatientFromCloud(dynamic id) async {}

  Future<void> syncEndocrineConditionToCloud(dynamic data) async {}

  Future<void> syncEndocrineVisitToCloud(dynamic data) async {}

  Future<void> syncPatientData(String patientId) async {}

  Future<void> syncAll() async {}
}
