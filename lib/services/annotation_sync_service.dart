import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/model_3d_config.dart';
import 'user_service.dart';

/// Service to sync 3D model annotations with Firebase Firestore
class AnnotationSyncService {
  static final AnnotationSyncService _instance = AnnotationSyncService._internal();
  static AnnotationSyncService get instance => _instance;

  AnnotationSyncService._internal();

  FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Get the collection reference for a user's annotations
  CollectionReference<Map<String, dynamic>> _getUserAnnotationsCollection() {
    final userId = UserService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return firestore
        .collection('users')
        .doc(userId)
        .collection('model_annotations');
  }

  /// Load annotations for a specific model from Firestore
  Future<List<ModelAnnotation>> loadAnnotations(String modelName) async {
    try {
      final userId = UserService.currentUserId;
      if (userId == null) {
        debugPrint('AnnotationSyncService: User not logged in, returning empty list');
        return [];
      }

      final doc = await _getUserAnnotationsCollection().doc(modelName).get();

      if (!doc.exists) {
        return [];
      }

      final data = doc.data();
      if (data == null || !data.containsKey('annotations')) {
        return [];
      }

      final List<dynamic> annotationsList = data['annotations'] as List<dynamic>;
      return annotationsList.map((json) => ModelAnnotation(
        id: json['id'] as String,
        label: json['label'] as String,
        description: json['description'] as String?,
        position: json['position'] as String,
        normal: json['normal'] as String? ?? '0 0 1',
      )).toList();
    } catch (e) {
      debugPrint('Error loading annotations from Firestore: $e');
      return [];
    }
  }

  /// Save annotations for a specific model to Firestore
  Future<bool> saveAnnotations(String modelName, List<ModelAnnotation> annotations) async {
    try {
      final userId = UserService.currentUserId;
      if (userId == null) {
        debugPrint('AnnotationSyncService: User not logged in, cannot save');
        return false;
      }

      final annotationsList = annotations.map((a) => {
        'id': a.id,
        'label': a.label,
        'description': a.description,
        'position': a.position,
        'normal': a.normal,
      }).toList();

      await _getUserAnnotationsCollection().doc(modelName).set({
        'modelName': modelName,
        'annotations': annotationsList,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('AnnotationSyncService: Saved ${annotations.length} annotations for $modelName');
      return true;
    } catch (e) {
      debugPrint('Error saving annotations to Firestore: $e');
      return false;
    }
  }

  /// Delete all annotations for a specific model
  Future<bool> deleteAnnotations(String modelName) async {
    try {
      final userId = UserService.currentUserId;
      if (userId == null) {
        return false;
      }

      await _getUserAnnotationsCollection().doc(modelName).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting annotations from Firestore: $e');
      return false;
    }
  }

  /// Get all model names that have annotations
  Future<List<String>> getAnnotatedModels() async {
    try {
      final userId = UserService.currentUserId;
      if (userId == null) {
        return [];
      }

      final snapshot = await _getUserAnnotationsCollection().get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting annotated models: $e');
      return [];
    }
  }

  /// Check if user is logged in and can sync
  bool get canSync => UserService.currentUserId != null;
}
