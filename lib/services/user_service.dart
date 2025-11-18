import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_helper.dart';

class UserService {
  static User? _currentUser;
  static const String _userIdKey = 'logged_in_user_id';

  static User? get currentUser => _currentUser;

  // Login and save to persistent storage
  static Future<void> login(User user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
  }

  // Logout and clear persistent storage
  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  // Check if user is logged in from persistent storage
  static Future<bool> isLoggedIn() async {
    if (_currentUser != null) return true;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);

    if (userId == null) return false;

    // Restore user from database
    final user = await DatabaseHelper.instance.getUserById(userId);
    if (user == null) {
      // User was deleted, clear stored ID
      await prefs.remove(_userIdKey);
      return false;
    }

    _currentUser = user;
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