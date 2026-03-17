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
  final String? subcategory; // Subcategory for grouping (e.g., "Fibroids", "Ovary")

  // Comparison model support (for before/after views)
  final bool isComparisonModel;
  final String? beforeModelFileName; // "Before" state model
  final String? afterModelFileName;  // "After" state model
  final String? beforeLabel;         // Label for before model (e.g., "Early Stage")
  final String? afterLabel;          // Label for after model (e.g., "Advanced")

  const Model3DItem({
    required this.id,
    required this.name,
    required this.description,
    required this.modelFileName,
    this.tags = const [],
    this.isPremium = false,
    this.annotations = const [],
    this.subcategory,
    this.isComparisonModel = false,
    this.beforeModelFileName,
    this.afterModelFileName,
    this.beforeLabel,
    this.afterLabel,
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
          modelFileName: 'fibroid_intramural',
          tags: ['pathology', 'fibroid', 'uterus'],
          subcategory: 'Fibroids',
        ),
        Model3DItem(
          id: 'fibroid_submucosal',
          name: 'Submucosal Fibroid',
          description: 'Fibroid projecting into the uterine cavity',
          modelFileName: 'fibroid_submucosal',
          tags: ['pathology', 'fibroid', 'uterus'],
          subcategory: 'Fibroids',
        ),
        Model3DItem(
          id: 'fibroid_subserosal',
          name: 'Subserosal Fibroid',
          description: 'Fibroid projecting outward from the uterine surface',
          modelFileName: 'fibroid_subserosal',
          tags: ['pathology', 'fibroid', 'uterus'],
          subcategory: 'Fibroids',
        ),
        Model3DItem(
          id: 'fibroid_pedunculated',
          name: 'Pedunculated Fibroid',
          description: 'Fibroid attached by a stalk to the uterus',
          modelFileName: 'uterus', // TODO: Replace with 'fibroid_pedunculated' when uploaded
          tags: ['pathology', 'fibroid', 'uterus'],
          subcategory: 'Fibroids',
        ),
        Model3DItem(
          id: 'fibroid_cervical',
          name: 'Cervical Fibroid',
          description: 'Fibroid located in the cervical region',
          modelFileName: 'fibroid_cervical',
          tags: ['pathology', 'fibroid', 'cervix'],
          subcategory: 'Fibroids',
        ),
        Model3DItem(
          id: 'fibroid_multiple',
          name: 'Multiple Fibroids',
          description: 'Uterus with multiple fibroids of different types',
          modelFileName: 'uterus', // TODO: Replace with 'fibroid_multiple' when uploaded
          tags: ['pathology', 'fibroid', 'uterus'],
          subcategory: 'Fibroids',
        ),
        Model3DItem(
          id: 'fibroid_compression',
          name: 'Fibroid Compression',
          description: 'Fibroid growth causing pressure effects on bladder and rectum - before and after comparison',
          modelFileName: 'uterus_fibroid_compression_before', // Default model for single view
          tags: ['pathology', 'fibroid', 'uterus', 'compression'],
          subcategory: 'Fibroids',
          isComparisonModel: true,
          beforeModelFileName: 'uterus_fibroid_compression_before',
          afterModelFileName: 'uterus_fibroid_compression_after',
          beforeLabel: 'Before',
          afterLabel: 'After',
        ),

        // Mullerian Anomaly
        Model3DItem(
          id: 'normal_uterus_mullerian',
          name: 'Normal Uterus',
          description: 'Normal uterine anatomy for comparison with mullerian anomalies',
          modelFileName: 'normal_uterus_mullerian',
          tags: ['anatomy', 'normal', 'uterus', 'mullerian'],
          subcategory: 'Mullerian Anomaly',
        ),
        Model3DItem(
          id: 'arcuate_uterus',
          name: 'Arcuate Uterus',
          description: 'Minor indentation of the uterine fundus',
          modelFileName: 'arcuate_uterus',
          tags: ['anatomy', 'anomaly', 'uterus', 'mullerian'],
          subcategory: 'Mullerian Anomaly',
        ),
        Model3DItem(
          id: 'septate_uterus',
          name: 'Septate Uterus',
          description: 'Uterus divided by a fibrous or muscular septum',
          modelFileName: 'uterus_septate',
          tags: ['anatomy', 'anomaly', 'uterus', 'mullerian', 'septum'],
          subcategory: 'Mullerian Anomaly',
        ),
        Model3DItem(
          id: 'subseptate_uterus',
          name: 'Subseptate Uterus',
          description: 'Uterus with a small septum that extends less than halfway into the cavity',
          modelFileName: 'uterus_subseptate',
          tags: ['anatomy', 'anomaly', 'uterus', 'mullerian', 'septum'],
          subcategory: 'Mullerian Anomaly',
        ),
        Model3DItem(
          id: 'bicornuate_bicollis',
          name: 'Bicornuate Bicollis',
          description: 'Heart-shaped uterus with two horns and two cervices',
          modelFileName: 'bicornuate_bicollis',
          tags: ['anatomy', 'anomaly', 'uterus', 'mullerian'],
          subcategory: 'Mullerian Anomaly',
        ),
        Model3DItem(
          id: 'bicornuate_unicollis',
          name: 'Bicornuate Unicollis',
          description: 'Heart-shaped uterus with two horns and a single cervix',
          modelFileName: 'bicornuate_unicollis',
          tags: ['anatomy', 'anomaly', 'uterus', 'mullerian'],
          subcategory: 'Mullerian Anomaly',
        ),
        Model3DItem(
          id: 'unicornate_uterus',
          name: 'Unicornate Uterus',
          description: 'One-sided uterine development with a single horn',
          modelFileName: 'uterus_unicornuate',
          tags: ['anatomy', 'anomaly', 'uterus', 'mullerian'],
          subcategory: 'Mullerian Anomaly',
        ),
        Model3DItem(
          id: 'unicornuate_uterus_rudimentary_horn',
          name: 'Unicornuate Uterus with Rudimentary Horn',
          description: 'Unicornuate uterus with a non-communicating or communicating rudimentary horn',
          modelFileName: 'unicornuate_uterus_rudimentary_horn',
          tags: ['anatomy', 'anomaly', 'uterus', 'mullerian', 'rudimentary horn'],
          subcategory: 'Mullerian Anomaly',
        ),
        Model3DItem(
          id: 'uterus_didelphys',
          name: 'Uterus Didelphys',
          description: 'Complete duplication resulting in double uterus',
          modelFileName: 'uterus_didelphys',
          tags: ['anatomy', 'anomaly', 'uterus', 'mullerian'],
          subcategory: 'Mullerian Anomaly',
        ),

        // Ovary
        Model3DItem(
          id: 'simple_cyst',
          name: 'Simple Ovarian Cyst',
          description: 'Fluid-filled simple cyst on the ovary',
          modelFileName: 'uterus', // TODO: Replace with 'simple_cyst' when uploaded
          tags: ['pathology', 'cyst', 'ovary'],
          subcategory: 'Ovary',
        ),
        Model3DItem(
          id: 'hemorrhagic_cyst',
          name: 'Hemorrhagic Cyst',
          description: 'Ovarian cyst with internal bleeding',
          modelFileName: 'uterus', // TODO: Replace with 'hemorrhagic_cyst' when uploaded
          tags: ['pathology', 'cyst', 'ovary'],
          subcategory: 'Ovary',
        ),
        Model3DItem(
          id: 'endometrioid_cyst',
          name: 'Endometrioid Cyst',
          description: 'Chocolate cyst from endometriosis',
          modelFileName: 'uterus', // TODO: Replace with 'endometrioid_cyst' when uploaded
          tags: ['pathology', 'cyst', 'ovary', 'endometriosis'],
          subcategory: 'Ovary',
        ),
        Model3DItem(
          id: 'dermoid_cyst',
          name: 'Dermoid Cyst',
          description: 'Mature cystic teratoma containing various tissues',
          modelFileName: 'uterus', // TODO: Replace with 'dermoid_cyst' when uploaded
          tags: ['pathology', 'cyst', 'ovary', 'teratoma'],
          subcategory: 'Ovary',
        ),
        Model3DItem(
          id: 'endometrioma',
          name: 'Endometrioma',
          description: 'Endometriotic cyst (chocolate cyst)',
          modelFileName: 'uterus', // TODO: Replace with 'endometrioma' when uploaded
          tags: ['pathology', 'endometriosis', 'ovary'],
          subcategory: 'Ovary',
        ),
        Model3DItem(
          id: 'pcos_ovary',
          name: 'PCOS Ovary',
          description: 'Polycystic ovary with multiple small follicles',
          modelFileName: 'uterus', // TODO: Replace with 'pcos_ovary' when uploaded
          tags: ['pathology', 'pcos', 'ovary'],
          subcategory: 'Ovary',
        ),

        // Endometrium
        Model3DItem(
          id: 'normal_endometrium',
          name: 'Normal Endometrium',
          description: 'Normal endometrial lining of the uterus',
          modelFileName: 'uterus_endo_normal',
          tags: ['anatomy', 'normal', 'endometrium'],
          subcategory: 'Endometrium',
        ),
        Model3DItem(
          id: 'adenomyosis_endometriosis',
          name: 'Adenomyosis & Endometriosis',
          description: 'Adenomyosis with endometriosis showing ectopic endometrial tissue',
          modelFileName: 'uterus_endo_adenoendo',
          tags: ['pathology', 'uterus', 'endometriosis', 'adenomyosis'],
          subcategory: 'Endometrium',
        ),
        Model3DItem(
          id: 'endometrial_polyp',
          name: 'Endometrial Polyp',
          description: 'Polypoid growth from the endometrium',
          modelFileName: 'uterus_endo_polyp',
          tags: ['pathology', 'polyp', 'endometrium'],
          subcategory: 'Endometrium',
        ),
        Model3DItem(
          id: 'endometrial_hyperplasia',
          name: 'Endometrial Hyperplasia',
          description: 'Thickened endometrial lining',
          modelFileName: 'uterus_endo_hyperplasia',
          tags: ['pathology', 'endometrium', 'hyperplasia'],
          subcategory: 'Endometrium',
        ),
        Model3DItem(
          id: 'cystic_endometrial_hyperplasia',
          name: 'Cystic Endometrial Hyperplasia',
          description: 'Cystic glandular changes in endometrial hyperplasia',
          modelFileName: 'uterus_endo_cystic',
          tags: ['pathology', 'endometrium', 'hyperplasia', 'cystic'],
          subcategory: 'Endometrium',
        ),
        Model3DItem(
          id: 'endometrial_carcinoma',
          name: 'Endometrial Carcinoma',
          description: 'Malignant tumor of the endometrium',
          modelFileName: 'uterus_endo_ca',
          tags: ['pathology', 'cancer', 'endometrium'],
          subcategory: 'Endometrium',
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

    // ==================== OBSTETRIC ====================
    Model3DCategory(
      id: 'obstetric',
      name: 'Obstetric',
      description: 'Pregnancy and placental anatomy and pathology',
      icon: '🤰',
      color: Color(0xFFE879F9),
      models: [
        // Placenta Previa
        Model3DItem(
          id: 'placenta_normal',
          name: 'Normal Placenta',
          description: 'Normal placental position in the upper uterine segment (fundal)',
          modelFileName: 'placenta_normal',
          tags: ['anatomy', 'normal', 'placenta'],
          subcategory: 'Placenta Previa',
        ),
        Model3DItem(
          id: 'placenta_previa_type1',
          name: 'Placenta Previa Type I',
          description: 'Low-lying placenta reaching the lower uterine segment but not the internal os',
          modelFileName: 'placenta_previa_type1',
          tags: ['pathology', 'placenta', 'previa'],
          subcategory: 'Placenta Previa',
        ),
        Model3DItem(
          id: 'placenta_previa_type2',
          name: 'Placenta Previa Type II',
          description: 'Marginal previa — placenta reaching but not covering the internal os',
          modelFileName: 'placenta_previa_type2',
          tags: ['pathology', 'placenta', 'previa'],
          subcategory: 'Placenta Previa',
        ),
        Model3DItem(
          id: 'placenta_previa_type3',
          name: 'Placenta Previa Type III',
          description: 'Partial previa — placenta partially covering the internal os',
          modelFileName: 'placenta_previa_type3',
          tags: ['pathology', 'placenta', 'previa'],
          subcategory: 'Placenta Previa',
        ),
        Model3DItem(
          id: 'placenta_previa_type4',
          name: 'Placenta Previa Type IV',
          description: 'Complete previa — placenta completely covering the internal os',
          modelFileName: 'placenta_previa_type4',
          tags: ['pathology', 'placenta', 'previa'],
          subcategory: 'Placenta Previa',
        ),

        // Placental Abruption
        Model3DItem(
          id: 'placental_abruption_revealed',
          name: 'Revealed Abruption',
          description: 'Placental abruption with visible vaginal bleeding — blood tracks between membranes and cervix',
          modelFileName: 'placental_abruption_revealed',
          tags: ['pathology', 'placenta', 'abruption'],
          subcategory: 'Placental Abruption',
        ),
        Model3DItem(
          id: 'placental_abruption_concealed',
          name: 'Concealed Abruption',
          description: 'Placental abruption with blood trapped behind the placenta — no visible vaginal bleeding',
          modelFileName: 'placental_abruption_concealed',
          tags: ['pathology', 'placenta', 'abruption'],
          subcategory: 'Placental Abruption',
        ),

        // Fetal Presentation
        Model3DItem(
          id: 'fetal_cephalic',
          name: 'Cephalic Presentation',
          description: 'Normal head-down presentation — vertex is the presenting part',
          modelFileName: 'fetal_cephalic',
          tags: ['anatomy', 'normal', 'fetus', 'presentation'],
          subcategory: 'Fetal Presentation',
        ),
        Model3DItem(
          id: 'fetal_breech',
          name: 'Breech Presentation',
          description: 'Buttocks or feet presenting first — frank, complete, or footling',
          modelFileName: 'fetal_breech',
          tags: ['pathology', 'fetus', 'presentation', 'malpresentation'],
          subcategory: 'Fetal Presentation',
        ),
        Model3DItem(
          id: 'fetal_transverse',
          name: 'Transverse Lie',
          description: 'Fetus lying horizontally across the uterus — shoulder presentation',
          modelFileName: 'fetal_transverse',
          tags: ['pathology', 'fetus', 'presentation', 'malpresentation'],
          subcategory: 'Fetal Presentation',
        ),
        Model3DItem(
          id: 'fetal_oblique',
          name: 'Oblique Lie',
          description: 'Fetus lying at an angle between longitudinal and transverse axes',
          modelFileName: 'fetal_oblique',
          tags: ['pathology', 'fetus', 'presentation', 'malpresentation'],
          subcategory: 'Fetal Presentation',
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
