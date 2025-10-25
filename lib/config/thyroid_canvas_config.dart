// lib/config/thyroid_canvas_config.dart

import 'package:flutter/material.dart';
import '../models/condition_tool.dart';

class ThyroidImageConfig {
  final String id;
  final String name;
  final String imagePath;
  final String category; // 'anatomy' or 'disease'
  final String? diseaseId;

  const ThyroidImageConfig({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.category,
    this.diseaseId,
  });
}

class ThyroidCanvasConfig {
  // Thyroid-specific annotation tools
  static const List<ConditionTool> tools = [
    ConditionTool(
      id: 'pan',
      name: 'Pan Tool',
      color: Colors.grey,
      defaultSize: 0,
    ),
    ConditionTool(
      id: 'nodule',
      name: 'Nodule',
      color: Color(0xFF78716C), // Brown
      defaultSize: 12,
    ),
    ConditionTool(
      id: 'inflammation',
      name: 'Inflammation',
      color: Color(0xFFDC2626), // Red
      defaultSize: 15,
    ),
    ConditionTool(
      id: 'calcification',
      name: 'Calcification',
      color: Color(0xFFE5E7EB), // Light gray/white
      defaultSize: 8,
    ),
    ConditionTool(
      id: 'tumor',
      name: 'Tumor',
      color: Color(0xFF7C3AED), // Purple
      defaultSize: 18,
    ),
    ConditionTool(
      id: 'cyst',
      name: 'Cyst',
      color: Color(0xFF2563EB), // Blue
      defaultSize: 12,
    ),
    ConditionTool(
      id: 'goiter',
      name: 'Goiter/Enlargement',
      color: Color(0xFFF97316), // Orange
      defaultSize: 20,
    ),
  ];

  // Normal anatomy images (always available)
  static const Map<String, ThyroidImageConfig> anatomyImages = {
    'anterior': ThyroidImageConfig(
      id: 'anterior',
      name: 'Anterior View',
      imagePath: 'assets/images/thyroid/anatomy/thyroid_anterior.png',
      category: 'anatomy',
    ),
    'lateral': ThyroidImageConfig(
      id: 'lateral',
      name: 'Lateral View',
      imagePath: 'assets/images/thyroid/anatomy/thyroid_lateral.png',
      category: 'anatomy',
    ),
    'cross_section': ThyroidImageConfig(
      id: 'cross_section',
      name: 'Cross-Section View',
      imagePath: 'assets/images/thyroid/anatomy/thyroid_cross_section.png',
      category: 'anatomy',
    ),
    'microscopic': ThyroidImageConfig(
      id: 'microscopic',
      name: 'Microscopic (Follicles)',
      imagePath: 'assets/images/thyroid/anatomy/thyroid_microscopic.png',
      category: 'anatomy',
    ),
  };

  // Disease-specific images
  static const Map<String, List<ThyroidImageConfig>> diseaseImages = {
    'graves_disease': [
      ThyroidImageConfig(
        id: 'graves_diffuse',
        name: 'Diffuse Goiter',
        imagePath: 'assets/images/thyroid/diseases/graves/graves_diffuse_goiter.png',
        category: 'disease',
        diseaseId: 'graves_disease',
      ),
      ThyroidImageConfig(
        id: 'graves_vascularity',
        name: 'Increased Vascularity',
        imagePath: 'assets/images/thyroid/diseases/graves/graves_vascularity.png',
        category: 'disease',
        diseaseId: 'graves_disease',
      ),
      ThyroidImageConfig(
        id: 'graves_ophthalmopathy',
        name: 'Eye Changes (Ophthalmopathy)',
        imagePath: 'assets/images/thyroid/diseases/graves/graves_ophthalmopathy.png',
        category: 'disease',
        diseaseId: 'graves_disease',
      ),
    ],
    'hashimotos_thyroiditis': [
      ThyroidImageConfig(
        id: 'hashimotos_lymphocytes',
        name: 'Lymphocytic Infiltration',
        imagePath: 'assets/images/thyroid/diseases/hashimotos/hashimotos_lymphocytes.png',
        category: 'disease',
        diseaseId: 'hashimotos_thyroiditis',
      ),
      ThyroidImageConfig(
        id: 'hashimotos_destruction',
        name: 'Follicle Destruction',
        imagePath: 'assets/images/thyroid/diseases/hashimotos/hashimotos_destruction.png',
        category: 'disease',
        diseaseId: 'hashimotos_thyroiditis',
      ),
      ThyroidImageConfig(
        id: 'hashimotos_fibrosis',
        name: 'Fibrosis Pattern',
        imagePath: 'assets/images/thyroid/diseases/hashimotos/hashimotos_fibrosis.png',
        category: 'disease',
        diseaseId: 'hashimotos_thyroiditis',
      ),
    ],
    'primary_hypothyroidism': [
      ThyroidImageConfig(
        id: 'hypothyroid_atrophy',
        name: 'Thyroid Atrophy',
        imagePath: 'assets/images/thyroid/diseases/hypothyroid/hypothyroid_atrophy.png',
        category: 'disease',
        diseaseId: 'primary_hypothyroidism',
      ),
      ThyroidImageConfig(
        id: 'hypothyroid_reduced',
        name: 'Reduced Hormone Production',
        imagePath: 'assets/images/thyroid/diseases/hypothyroid/hypothyroid_reduced.png',
        category: 'disease',
        diseaseId: 'primary_hypothyroidism',
      ),
    ],
    'toxic_multinodular_goiter': [
      ThyroidImageConfig(
        id: 'tmg_nodules',
        name: 'Multiple Nodules',
        imagePath: 'assets/images/thyroid/diseases/toxic_multinodular/tmg_nodules.png',
        category: 'disease',
        diseaseId: 'toxic_multinodular_goiter',
      ),
      ThyroidImageConfig(
        id: 'tmg_heterogeneous',
        name: 'Heterogeneous Texture',
        imagePath: 'assets/images/thyroid/diseases/toxic_multinodular/tmg_heterogeneous.png',
        category: 'disease',
        diseaseId: 'toxic_multinodular_goiter',
      ),
    ],
    'subacute_thyroiditis': [
      ThyroidImageConfig(
        id: 'subacute_inflammation',
        name: 'Thyroid Inflammation',
        imagePath: 'assets/images/thyroid/diseases/subacute/subacute_inflammation.png',
        category: 'disease',
        diseaseId: 'subacute_thyroiditis',
      ),
      ThyroidImageConfig(
        id: 'subacute_pain',
        name: 'Painful Thyroid',
        imagePath: 'assets/images/thyroid/diseases/subacute/subacute_pain.png',
        category: 'disease',
        diseaseId: 'subacute_thyroiditis',
      ),
    ],
    'thyroid_cancer': [
      ThyroidImageConfig(
        id: 'cancer_papillary',
        name: 'Papillary Carcinoma',
        imagePath: 'assets/images/thyroid/diseases/cancer/cancer_papillary.png',
        category: 'disease',
        diseaseId: 'thyroid_cancer',
      ),
      ThyroidImageConfig(
        id: 'cancer_follicular',
        name: 'Follicular Carcinoma',
        imagePath: 'assets/images/thyroid/diseases/cancer/cancer_follicular.png',
        category: 'disease',
        diseaseId: 'thyroid_cancer',
      ),
      ThyroidImageConfig(
        id: 'cancer_medullary',
        name: 'Medullary Carcinoma',
        imagePath: 'assets/images/thyroid/diseases/cancer/cancer_medullary.png',
        category: 'disease',
        diseaseId: 'thyroid_cancer',
      ),
    ],
  };

  // Get all available images for a specific disease
  static List<ThyroidImageConfig> getImagesForDisease(String diseaseId) {
    final List<ThyroidImageConfig> images = [];

    // Always include anatomy images
    images.addAll(anatomyImages.values);

    // Add disease-specific images if available
    if (diseaseImages.containsKey(diseaseId)) {
      images.addAll(diseaseImages[diseaseId]!);
    }

    return images;
  }

  // Get anatomy images only
  static List<ThyroidImageConfig> getAnatomyImages() {
    return anatomyImages.values.toList();
  }

  // Get disease images only for a specific disease
  static List<ThyroidImageConfig> getDiseaseImagesOnly(String diseaseId) {
    return diseaseImages[diseaseId] ?? [];
  }

  // Check if disease has specific images
  static bool hasDiseaseImages(String diseaseId) {
    return diseaseImages.containsKey(diseaseId) &&
        diseaseImages[diseaseId]!.isNotEmpty;
  }
}