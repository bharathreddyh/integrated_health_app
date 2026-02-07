// lib/config/model_3d_config.dart
// Configuration for 3D anatomical models - organized by medical system
// Inspired by anatomy apps like Complete Anatomy, Visible Body, 3D4Medical

import 'package:flutter/material.dart';

/// Annotation/hotspot for 3D models
/// Position is in 3D space coordinates (x y z) relative to the model
/// Normal is the direction the annotation faces (for proper positioning)
class ModelAnnotation {
  final String id;
  final String label;
  final String? description;
  final String position; // "x y z" format, e.g., "0 0.5 0.2"
  final String normal; // "x y z" format, e.g., "0 1 0" (pointing up)

  const ModelAnnotation({
    required this.id,
    required this.label,
    this.description,
    required this.position,
    this.normal = '0 0 1', // Default facing camera
  });
}

class Model3DItem {
  final String id;
  final String name;
  final String description;
  final String modelFileName; // Firebase model filename (without extension)
  final List<String> tags;
  final bool isPremium;
  final List<ModelAnnotation> annotations; // Hotspots/labels on the model

  const Model3DItem({
    required this.id,
    required this.name,
    required this.description,
    required this.modelFileName,
    this.tags = const [],
    this.isPremium = false,
    this.annotations = const [],
  });

  /// Get the thumbnail asset path for this model
  /// Thumbnails should be placed in assets/images/model_thumbnails/{modelFileName}.png
  /// You can use PNG, WebP, or GIF (for animated thumbnails)
  String get thumbnailAssetPath => 'assets/images/model_thumbnails/$modelFileName.png';

  /// Animated thumbnail (GIF) path - optional, for rotating preview
  String get animatedThumbnailPath => 'assets/images/model_thumbnails/$modelFileName.gif';

  /// Check if model has annotations
  bool get hasAnnotations => annotations.isNotEmpty;
}

class Model3DCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final Color color;
  final List<Model3DItem> models;

  const Model3DCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.models,
  });

  int get modelCount => models.length;
}

class Model3DConfig {
  static const List<Model3DCategory> categories = [
    // ==================== GYNAECOLOGY ====================
    Model3DCategory(
      id: 'gynaecology',
      name: 'Gynaecology',
      description: 'Female reproductive system anatomy and pathology',
      icon: '🌸',
      color: Color(0xFFEC4899),
      models: [
        // Normal Anatomy
        Model3DItem(
          id: 'uterus',
          name: 'Uterus - Normal',
          description: 'Normal uterine anatomy showing myometrium, endometrium, and cervix',
          modelFileName: 'uterus',
          tags: ['anatomy', 'normal', 'uterus'],
        ),

        // Fibroids
        Model3DItem(
          id: 'fibroid_intramural',
          name: 'Intramural Fibroid',
          description: 'Fibroid within the muscular wall of the uterus',
          modelFileName: 'uterus', // TODO: Replace with 'fibroid_intramural' when uploaded
          tags: ['pathology', 'fibroid', 'uterus'],
        ),
        Model3DItem(
          id: 'fibroid_submucosal',
          name: 'Submucosal Fibroid',
          description: 'Fibroid projecting into the uterine cavity',
          modelFileName: 'uterus', // TODO: Replace with 'fibroid_submucosal' when uploaded
          tags: ['pathology', 'fibroid', 'uterus'],
        ),
        Model3DItem(
          id: 'fibroid_subserosal',
          name: 'Subserosal Fibroid',
          description: 'Fibroid projecting outward from the uterine surface',
          modelFileName: 'uterus', // TODO: Replace with 'fibroid_subserosal' when uploaded
          tags: ['pathology', 'fibroid', 'uterus'],
        ),
        Model3DItem(
          id: 'fibroid_pedunculated',
          name: 'Pedunculated Fibroid',
          description: 'Fibroid attached by a stalk to the uterus',
          modelFileName: 'uterus', // TODO: Replace with 'fibroid_pedunculated' when uploaded
          tags: ['pathology', 'fibroid', 'uterus'],
        ),
        Model3DItem(
          id: 'fibroid_cervical',
          name: 'Cervical Fibroid',
          description: 'Fibroid located in the cervical region',
          modelFileName: 'uterus', // TODO: Replace with 'fibroid_cervical' when uploaded
          tags: ['pathology', 'fibroid', 'cervix'],
        ),
        Model3DItem(
          id: 'fibroid_multiple',
          name: 'Multiple Fibroids',
          description: 'Uterus with multiple fibroids of different types',
          modelFileName: 'uterus', // TODO: Replace with 'fibroid_multiple' when uploaded
          tags: ['pathology', 'fibroid', 'uterus'],
        ),
        Model3DItem(
          id: 'fibroid_degenerating',
          name: 'Degenerating Fibroid',
          description: 'Fibroid undergoing degeneration',
          modelFileName: 'uterus', // TODO: Replace with 'fibroid_degenerating' when uploaded
          tags: ['pathology', 'fibroid', 'uterus'],
        ),

        // Ovarian Cysts
        Model3DItem(
          id: 'simple_cyst',
          name: 'Simple Ovarian Cyst',
          description: 'Fluid-filled simple cyst on the ovary',
          modelFileName: 'uterus', // TODO: Replace with 'simple_cyst' when uploaded
          tags: ['pathology', 'cyst', 'ovary'],
        ),
        Model3DItem(
          id: 'hemorrhagic_cyst',
          name: 'Hemorrhagic Cyst',
          description: 'Ovarian cyst with internal bleeding',
          modelFileName: 'uterus', // TODO: Replace with 'hemorrhagic_cyst' when uploaded
          tags: ['pathology', 'cyst', 'ovary'],
        ),
        Model3DItem(
          id: 'endometrioid_cyst',
          name: 'Endometrioid Cyst',
          description: 'Chocolate cyst from endometriosis',
          modelFileName: 'uterus', // TODO: Replace with 'endometrioid_cyst' when uploaded
          tags: ['pathology', 'cyst', 'ovary', 'endometriosis'],
        ),
        Model3DItem(
          id: 'dermoid_cyst',
          name: 'Dermoid Cyst',
          description: 'Mature cystic teratoma containing various tissues',
          modelFileName: 'uterus', // TODO: Replace with 'dermoid_cyst' when uploaded
          tags: ['pathology', 'cyst', 'ovary', 'teratoma'],
        ),

        // Other Pathologies
        Model3DItem(
          id: 'adenomyosis',
          name: 'Adenomyosis',
          description: 'Endometrial tissue within the myometrium',
          modelFileName: 'uterus', // TODO: Replace with 'adenomyosis' when uploaded
          tags: ['pathology', 'uterus', 'endometriosis'],
        ),
        Model3DItem(
          id: 'endometrial_polyp',
          name: 'Endometrial Polyp',
          description: 'Polypoid growth from the endometrium',
          modelFileName: 'uterus', // TODO: Replace with 'endometrial_polyp' when uploaded
          tags: ['pathology', 'polyp', 'endometrium'],
        ),
        Model3DItem(
          id: 'endometrial_hyperplasia',
          name: 'Endometrial Hyperplasia',
          description: 'Thickened endometrial lining',
          modelFileName: 'uterus', // TODO: Replace with 'endometrial_hyperplasia' when uploaded
          tags: ['pathology', 'endometrium', 'hyperplasia'],
        ),
        Model3DItem(
          id: 'endometrial_carcinoma',
          name: 'Endometrial Carcinoma',
          description: 'Malignant tumor of the endometrium',
          modelFileName: 'uterus', // TODO: Replace with 'endometrial_carcinoma' when uploaded
          tags: ['pathology', 'cancer', 'endometrium'],
        ),
        Model3DItem(
          id: 'endometrioma',
          name: 'Endometrioma',
          description: 'Endometriotic cyst (chocolate cyst)',
          modelFileName: 'uterus', // TODO: Replace with 'endometrioma' when uploaded
          tags: ['pathology', 'endometriosis', 'ovary'],
        ),
        Model3DItem(
          id: 'pcos_ovary',
          name: 'PCOS Ovary',
          description: 'Polycystic ovary with multiple small follicles',
          modelFileName: 'uterus', // TODO: Replace with 'pcos_ovary' when uploaded
          tags: ['pathology', 'pcos', 'ovary'],
        ),
        Model3DItem(
          id: 'uterine_anomalies',
          name: 'Uterine Anomalies',
          description: 'Congenital uterine malformations',
          modelFileName: 'uterus', // TODO: Replace with 'uterine_anomalies' when uploaded
          tags: ['anatomy', 'anomaly', 'uterus'],
        ),
      ],
    ),

    // ==================== CARDIAC ====================
    Model3DCategory(
      id: 'cardiac',
      name: 'Cardiovascular',
      description: 'Heart and blood vessel anatomy',
      icon: '❤️',
      color: Color(0xFFEF4444),
      models: [
        Model3DItem(
          id: 'heart_normal',
          name: 'Heart - Normal',
          description: 'Complete cardiac anatomy with chambers and valves',
          modelFileName: 'heart_normal',
          tags: ['anatomy', 'normal', 'heart'],
        ),
        Model3DItem(
          id: 'heart_coronary',
          name: 'Coronary Arteries',
          description: 'Heart with coronary artery system highlighted',
          modelFileName: 'heart_coronary',
          tags: ['anatomy', 'coronary', 'arteries'],
        ),
      ],
    ),

    // ==================== RENAL ====================
    Model3DCategory(
      id: 'renal',
      name: 'Renal System',
      description: 'Kidney and urinary tract anatomy',
      icon: '💎',
      color: Color(0xFFF59E0B),
      models: [
        Model3DItem(
          id: 'kidney_normal',
          name: 'Kidney - Normal',
          description: 'Normal kidney anatomy showing cortex, medulla, and pelvis',
          modelFileName: 'kidney_normal',
          tags: ['anatomy', 'normal', 'kidney'],
        ),
        Model3DItem(
          id: 'kidney_stones',
          name: 'Kidney Stones',
          description: 'Kidney with calculi in various locations',
          modelFileName: 'kidney_stones',
          tags: ['pathology', 'stones', 'kidney'],
        ),
      ],
    ),

    // ==================== RESPIRATORY ====================
    Model3DCategory(
      id: 'respiratory',
      name: 'Respiratory',
      description: 'Lungs and airway anatomy',
      icon: '💨',
      color: Color(0xFF3B82F6),
      models: [
        Model3DItem(
          id: 'lungs_normal',
          name: 'Lungs - Normal',
          description: 'Normal pulmonary anatomy with bronchial tree',
          modelFileName: 'lungs_normal',
          tags: ['anatomy', 'normal', 'lungs'],
        ),
      ],
    ),

    // ==================== NEUROLOGICAL ====================
    Model3DCategory(
      id: 'neuro',
      name: 'Neurological',
      description: 'Brain and nervous system anatomy',
      icon: '🧠',
      color: Color(0xFF8B5CF6),
      models: [
        Model3DItem(
          id: 'brain_normal',
          name: 'Brain - Normal',
          description: 'Complete brain anatomy with major structures',
          modelFileName: 'brain_normal',
          tags: ['anatomy', 'normal', 'brain'],
        ),
      ],
    ),

    // ==================== HEPATIC ====================
    Model3DCategory(
      id: 'hepatic',
      name: 'Hepatobiliary',
      description: 'Liver and biliary system anatomy',
      icon: '🔶',
      color: Color(0xFF10B981),
      models: [
        Model3DItem(
          id: 'liver_normal',
          name: 'Liver - Normal',
          description: 'Normal liver anatomy with segments',
          modelFileName: 'liver_normal',
          tags: ['anatomy', 'normal', 'liver'],
        ),
      ],
    ),

    // ==================== MUSCULOSKELETAL ====================
    Model3DCategory(
      id: 'musculoskeletal',
      name: 'Musculoskeletal',
      description: 'Bones, joints, and muscles',
      icon: '🦴',
      color: Color(0xFF6366F1),
      models: [
        Model3DItem(
          id: 'spine_normal',
          name: 'Spine - Normal',
          description: 'Complete spinal column anatomy',
          modelFileName: 'spine_normal',
          tags: ['anatomy', 'normal', 'spine'],
        ),
      ],
    ),

    // ==================== ENDOCRINE ====================
    Model3DCategory(
      id: 'endocrine',
      name: 'Endocrine',
      description: 'Thyroid, adrenal, and other glands',
      icon: '🦋',
      color: Color(0xFFF97316),
      models: [
        Model3DItem(
          id: 'thyroid_normal',
          name: 'Thyroid - Normal',
          description: 'Normal thyroid gland anatomy',
          modelFileName: 'thyroid_normal',
          tags: ['anatomy', 'normal', 'thyroid'],
        ),
      ],
    ),
  ];

  // Get all categories
  static List<Model3DCategory> getAllCategories() => categories;

  // Get category by ID
  static Model3DCategory? getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get all models across all categories
  static List<Model3DItem> getAllModels() {
    return categories.expand((c) => c.models).toList();
  }

  // Search models by name or tag
  static List<Model3DItem> searchModels(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllModels().where((model) {
      return model.name.toLowerCase().contains(lowerQuery) ||
          model.description.toLowerCase().contains(lowerQuery) ||
          model.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // Get total model count
  static int get totalModelCount => getAllModels().length;
}
