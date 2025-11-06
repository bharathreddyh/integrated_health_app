// lib/services/firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

/// Firebase Authentication Service
/// Handles cloud-based user authentication and syncs with Firestore
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current Firebase user
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  // Stream of authentication state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Register new user with email and password
  /// Creates Firebase Auth account and stores user data in Firestore
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    String? specialty,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      // Create user document in Firestore
      final user = User(
        id: credential.user!.uid,
        name: name,
        email: email,
        passwordHash: '', // Not stored in cloud for security
        role: _parseUserRole(role),
        specialty: specialty,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'role': user.role.name,
        'specialty': user.specialty,
        'createdAt': user.createdAt.toIso8601String(),
      });

      // Update display name
      await credential.user!.updateDisplayName(name);

      print('✅ User registered in Firebase: ${user.email}');
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ Firebase registration error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Registration error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        print('⚠️ User document not found in Firestore');
        return null;
      }

      final userData = userDoc.data()!;
      final user = User(
        id: credential.user!.uid,
        name: userData['name'] as String,
        email: userData['email'] as String,
        passwordHash: '', // Not used for Firebase auth
        role: _parseUserRole(userData['role'] as String),
        specialty: userData['specialty'] as String?,
        createdAt: DateTime.parse(userData['createdAt'] as String),
      );

      print('✅ User signed in: ${user.email}');
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ Firebase sign-in error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Sign-in error: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ User signed out');
    } catch (e) {
      print('❌ Sign-out error: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Get user data from Firestore
  Future<User?> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return null;

      final data = userDoc.data()!;
      return User(
        id: userId,
        name: data['name'] as String,
        email: data['email'] as String,
        passwordHash: '',
        role: _parseUserRole(data['role'] as String),
        specialty: data['specialty'] as String?,
        createdAt: DateTime.parse(data['createdAt'] as String),
      );
    } catch (e) {
      print('❌ Error fetching user data: $e');
      return null;
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? specialty,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (specialty != null) updates['specialty'] = specialty;

      await _firestore.collection('users').doc(userId).update(updates);

      if (name != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(name);
      }

      print('✅ User profile updated');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Password reset email sent to $email');
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ Password reset error: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String userId) async {
    try {
      // Delete user document from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Delete Firebase Auth user
      await _auth.currentUser?.delete();

      print('✅ User account deleted');
    } catch (e) {
      print('❌ Error deleting account: $e');
      rethrow;
    }
  }

  // Helper: Parse user role from string
  UserRole _parseUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'nurse':
        return UserRole.nurse;
      case 'patient':
        return UserRole.patient;
      default:
        return UserRole.patient;
    }
  }

  // Helper: Handle Firebase Auth exceptions
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
