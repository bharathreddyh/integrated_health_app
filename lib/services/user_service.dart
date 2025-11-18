import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_helper.dart';
import 'firebase_auth_service.dart';
import 'cloud_sync_service.dart';

class UserService {
  static User? _currentUser;
  static const String _userIdKey = 'logged_in_user_id';
  static const String _useCloudAuthKey = 'use_cloud_auth';

  static final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  static final CloudSyncService _cloudSync = CloudSyncService();

  static User? get currentUser => _currentUser;

  // Login and save to persistent storage
  // Now supports both local and cloud authentication
  static Future<void> login(User user, {bool useCloudAuth = true}) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    await prefs.setBool(_useCloudAuthKey, useCloudAuth);

    // Perform initial sync if using cloud auth
    if (useCloudAuth && _cloudSync.isAuthenticated) {
      print('🔄 Performing initial data sync...');
      try {
        await _cloudSync.performFullSync();
        print('✅ Initial sync completed');
      } catch (e) {
        print('⚠️ Initial sync failed: $e');
      }
    }
  }

  // Logout and clear persistent storage
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final useCloudAuth = prefs.getBool(_useCloudAuthKey) ?? false;

    // Sign out from Firebase if using cloud auth
    if (useCloudAuth) {
      try {
        await _firebaseAuth.signOut();
        print('✅ Signed out from Firebase');
      } catch (e) {
        print('⚠️ Firebase sign-out error: $e');
      }
    }

    _currentUser = null;
    await prefs.remove(_userIdKey);
    await prefs.remove(_useCloudAuthKey);
  }

  // Check if user is logged in from persistent storage
  static Future<bool> isLoggedIn() async {
    if (_currentUser != null) return true;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    final useCloudAuth = prefs.getBool(_useCloudAuthKey) ?? false;

    if (userId == null) return false;

    // Try to restore user from cloud first, then local database
    User? user;

    if (useCloudAuth && _firebaseAuth.isAuthenticated()) {
      // Restore from Firebase
      user = await _firebaseAuth.getUserData(userId);
      if (user != null) {
        print('✅ User restored from Firebase');
        _currentUser = user;

        // Sync data in background
        _cloudSync.performFullSync().catchError((e) {
          print('⚠️ Background sync failed: $e');
        });

        return true;
      }
    }

    // Fallback to local database
    user = await DatabaseHelper.instance.getUserById(userId);
    if (user == null) {
      // User was deleted, clear stored ID
      await prefs.remove(_userIdKey);
      await prefs.remove(_useCloudAuthKey);
      return false;
    }

    _currentUser = user;
    print('✅ User restored from local database');
    return true;
  }

  // Get initial route based on login status
  static Future<String> getInitialRoute() async {
    final loggedIn = await isLoggedIn();
    if (!loggedIn) return '/login';

    switch (_currentUser!.role) {
      case UserRole.doctor:
        return '/doctor-home';
      case UserRole.nurse:
        return '/nurse-home';
      case UserRole.patient:
        return '/patient-home';
    }
  }

  // Convenience getters
  static bool get isDoctor => _currentUser?.role == UserRole.doctor;
  static bool get isNurse => _currentUser?.role == UserRole.nurse;
  static bool get isPatient => _currentUser?.role == UserRole.patient;

  static String? get currentUserId => _currentUser?.id;
  static String? get currentUserName => _currentUser?.name;
}