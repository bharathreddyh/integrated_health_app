// lib/config/canvas_system_config.dart
// Enhanced system configurations for multi-system canvas tool WITH THYROID SUPPORT

import 'package:flutter/material.dart';
import '../models/condition_tool.dart';

class DiagramConfig {
  final String id;
  final String name;
  final String imagePath;
  final String category; // 'anatomy' or 'template'

  const DiagramConfig({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.category,
  });
}

class SystemConfig {
  final String id;
  final String name;
  final String icon;
  final List<ConditionTool> tools;
  final Map<String, DiagramConfig> anatomyDiagrams;
  final Map<String, DiagramConfig> systemTemplates;

  const SystemConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.tools,
    required this.anatomyDiagrams,
    required this.systemTemplates,
  });

  Map<String, DiagramConfig> get allDiagrams {
    return {...anatomyDiagrams, ...systemTemplates};
  }
}

class CanvasSystemConfig {
  static const Map<String, SystemConfig> systems = {

    // ==================== THYROID SYSTEM ====================
    'thyroid': SystemConfig(
      id: 'thyroid',
      name: 'Thyroid System',
      icon: '⚕️',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'nodule', name: 'Nodule', color: Color(0xFF78716C), defaultSize: 12),
        ConditionTool(id: 'inflammation', name: 'Inflammation', color: Color(0xFFDC2626), defaultSize: 15),
        ConditionTool(id: 'calcification', name: 'Calcification', color: Color(0xFFE5E7EB), defaultSize: 8),
        ConditionTool(id: 'tumor', name: 'Tumor', color: Color(0xFF7C3AED), defaultSize: 18),
        ConditionTool(id: 'cyst', name: 'Cyst', color: Color(0xFF2563EB), defaultSize: 12),
        ConditionTool(id: 'goiter', name: 'Goiter/Enlargement', color: Color(0xFFF97316), defaultSize: 20),
      ],
      anatomyDiagrams: {
        'anterior': DiagramConfig(
          id: 'anterior',
          name: 'Anterior View',
          imagePath: 'assets/images/thyroid/anatomy/thyroid_anterior.png',
          category: 'anatomy',
        ),
        'lateral': DiagramConfig(
          id: 'lateral',
          name: 'Lateral View',
          imagePath: 'assets/images/thyroid/anatomy/thyroid_lateral.png',
          category: 'anatomy',
        ),
        'cross_section': DiagramConfig(
          id: 'cross_section',
          name: 'Cross-Section View',
          imagePath: 'assets/images/thyroid/anatomy/thyroid_cross_section.png',
          category: 'anatomy',
        ),
        'microscopic': DiagramConfig(
          id: 'microscopic',
          name: 'Microscopic (Follicles)',
          imagePath: 'assets/images/thyroid/anatomy/thyroid_microscopic.png',
          category: 'anatomy',
        ),
      },
      systemTemplates: {
        'graves_diffuse': DiagramConfig(
          id: 'graves_diffuse',
          name: 'Diffuse Goiter (Graves)',
          imagePath: 'assets/images/thyroid/diseases/graves/graves_diffuse_goiter.png',
          category: 'template',
        ),
        'graves_vascularity': DiagramConfig(
          id: 'graves_vascularity',
          name: 'Increased Vascularity',
          imagePath: 'assets/images/thyroid/diseases/graves/graves_vascularity.png',
          category: 'template',
        ),
        'hashimotos_lymphocytes': DiagramConfig(
          id: 'hashimotos_lymphocytes',
          name: 'Lymphocytic Infiltration',
          imagePath: 'assets/images/thyroid/diseases/hashimotos/hashimotos_lymphocytes.png',
          category: 'template',
        ),
        'hypothyroid_atrophy': DiagramConfig(
          id: 'hypothyroid_atrophy',
          name: 'Thyroid Atrophy',
          imagePath: 'assets/images/thyroid/diseases/hypothyroid/hypothyroid_atrophy.png',
          category: 'template',
        ),
      },
    ),

    // ==================== KIDNEY SYSTEM ====================
    'kidney': SystemConfig(
      id: 'kidney',
      name: 'Renal System',
      icon: '🔴',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'calculi', name: 'Calculi', color: Colors.grey, defaultSize: 8),
        ConditionTool(id: 'cyst', name: 'Cyst', color: Color(0xFF2563EB), defaultSize: 12),
        ConditionTool(id: 'tumor', name: 'Tumor', color: Color(0xFF7C2D12), defaultSize: 16),
        ConditionTool(id: 'inflammation', name: 'Inflammation', color: Color(0xFFEA580C), defaultSize: 14),
        ConditionTool(id: 'blockage', name: 'Blockage', color: Color(0xFF9333EA), defaultSize: 10),
      ],
      anatomyDiagrams: {
        'anatomical': DiagramConfig(
          id: 'anatomical',
          name: 'Detailed Anatomy',
          imagePath: 'assets/images/kidney_anatomical.png',
          category: 'anatomy',
        ),
        'simple': DiagramConfig(
          id: 'simple',
          name: 'Simple Diagram',
          imagePath: 'assets/images/kidney_simple.png',
          category: 'anatomy',
        ),
        'crossSection': DiagramConfig(
          id: 'crossSection',
          name: 'Cross-Section View',
          imagePath: 'assets/images/kidney_cross_section.png',
          category: 'anatomy',
        ),
        'nephron': DiagramConfig(
          id: 'nephron',
          name: 'Nephron (Microscopic)',
          imagePath: 'assets/images/kidney_nephron.png',
          category: 'anatomy',
        ),
      },
      systemTemplates: {
        'polycystic': DiagramConfig(
          id: 'polycystic',
          name: 'Polycystic Kidney Disease',
          imagePath: 'assets/images/kidney_polycystic.png',
          category: 'template',
        ),
        'pyelonephritis': DiagramConfig(
          id: 'pyelonephritis',
          name: 'Pyelonephritis',
          imagePath: 'assets/images/kidney_pyelonephritis.png',
          category: 'template',
        ),
        'glomerulonephritis': DiagramConfig(
          id: 'glomerulonephritis',
          name: 'Glomerulonephritis',
          imagePath: 'assets/images/kidney_glomerulonephritis.png',
          category: 'template',
        ),
      },
    ),

    // ==================== CARDIAC SYSTEM ====================
    'cardiac': SystemConfig(
      id: 'cardiac',
      name: 'Cardiac System',
      icon: '❤️',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'stenosis', name: 'Stenosis', color: Color(0xFFDC2626), defaultSize: 10),
        ConditionTool(id: 'blockage', name: 'Blockage', color: Color(0xFF7C2D12), defaultSize: 12),
        ConditionTool(id: 'infarction', name: 'Infarction', color: Color(0xFF991B1B), defaultSize: 16),
        ConditionTool(id: 'valve', name: 'Valve Issue', color: Color(0xFFEA580C), defaultSize: 14),
        ConditionTool(id: 'arrhythmia', name: 'Arrhythmia Area', color: Color(0xFFF59E0B), defaultSize: 12),
      ],
      anatomyDiagrams: {
        'anterior': DiagramConfig(
          id: 'anterior',
          name: 'Anterior View',
          imagePath: 'assets/images/cardiac_anterior.png',
          category: 'anatomy',
        ),
        'posterior': DiagramConfig(
          id: 'posterior',
          name: 'Posterior View',
          imagePath: 'assets/images/cardiac_posterior.png',
          category: 'anatomy',
        ),
        'crossSection': DiagramConfig(
          id: 'crossSection',
          name: 'Cross-Section',
          imagePath: 'assets/images/cardiac_cross_section.png',
          category: 'anatomy',
        ),
        'coronary': DiagramConfig(
          id: 'coronary',
          name: 'Coronary Arteries',
          imagePath: 'assets/images/cardiac_coronary.png',
          category: 'anatomy',
        ),
      },
      systemTemplates: {
        'mi': DiagramConfig(
          id: 'mi',
          name: 'Myocardial Infarction',
          imagePath: 'assets/images/cardiac_mi.png',
          category: 'template',
        ),
        'chf': DiagramConfig(
          id: 'chf',
          name: 'Congestive Heart Failure',
          imagePath: 'assets/images/cardiac_chf.png',
          category: 'template',
        ),
      },
    ),

    // ==================== PULMONARY SYSTEM ====================
    'pulmonary': SystemConfig(
      id: 'pulmonary',
      name: 'Pulmonary System',
      icon: '💨',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'consolidation', name: 'Consolidation', color: Color(0xFFDC2626), defaultSize: 16),
        ConditionTool(id: 'nodule', name: 'Nodule', color: Color(0xFF7C2D12), defaultSize: 10),
        ConditionTool(id: 'effusion', name: 'Effusion', color: Color(0xFF2563EB), defaultSize: 14),
        ConditionTool(id: 'inflammation', name: 'Inflammation', color: Color(0xFFEA580C), defaultSize: 12),
        ConditionTool(id: 'obstruction', name: 'Obstruction', color: Color(0xFF9333EA), defaultSize: 12),
      ],
      anatomyDiagrams: {
        'anterior': DiagramConfig(
          id: 'anterior',
          name: 'Anterior View',
          imagePath: 'assets/images/pulmonary_anterior.png',
          category: 'anatomy',
        ),
        'posterior': DiagramConfig(
          id: 'posterior',
          name: 'Posterior View',
          imagePath: 'assets/images/pulmonary_posterior.png',
          category: 'anatomy',
        ),
        'lobes': DiagramConfig(
          id: 'lobes',
          name: 'Lobes & Segments',
          imagePath: 'assets/images/pulmonary_lobes.png',
          category: 'anatomy',
        ),
      },
      systemTemplates: {
        'pneumonia': DiagramConfig(
          id: 'pneumonia',
          name: 'Pneumonia',
          imagePath: 'assets/images/pulmonary_pneumonia.png',
          category: 'template',
        ),
        'copd': DiagramConfig(
          id: 'copd',
          name: 'COPD',
          imagePath: 'assets/images/pulmonary_copd.png',
          category: 'template',
        ),
        'asthma': DiagramConfig(
          id: 'asthma',
          name: 'Asthma',
          imagePath: 'assets/images/pulmonary_asthma.png',
          category: 'template',
        ),
      },
    ),

    // ==================== NEUROLOGICAL SYSTEM ====================
    'neuro': SystemConfig(
      id: 'neuro',
      name: 'Neurological System',
      icon: '🧠',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'lesion', name: 'Lesion', color: Color(0xFFDC2626), defaultSize: 12),
        ConditionTool(id: 'hemorrhage', name: 'Hemorrhage', color: Color(0xFF991B1B), defaultSize: 14),
        ConditionTool(id: 'infarct', name: 'Infarct', color: Color(0xFF7C2D12), defaultSize: 16),
        ConditionTool(id: 'tumor', name: 'Tumor', color: Color(0xFF7C3AED), defaultSize: 16),
        ConditionTool(id: 'atrophy', name: 'Atrophy', color: Color(0xFF64748B), defaultSize: 14),
      ],
      anatomyDiagrams: {
        'sagittal': DiagramConfig(
          id: 'sagittal',
          name: 'Sagittal View',
          imagePath: 'assets/images/neuro_sagittal.png',
          category: 'anatomy',
        ),
        'coronal': DiagramConfig(
          id: 'coronal',
          name: 'Coronal View',
          imagePath: 'assets/images/neuro_coronal.png',
          category: 'anatomy',
        ),
        'axial': DiagramConfig(
          id: 'axial',
          name: 'Axial View',
          imagePath: 'assets/images/neuro_axial.png',
          category: 'anatomy',
        ),
      },
      systemTemplates: {
        'stroke': DiagramConfig(
          id: 'stroke',
          name: 'Stroke',
          imagePath: 'assets/images/neuro_stroke.png',
          category: 'template',
        ),
        'alzheimers': DiagramConfig(
          id: 'alzheimers',
          name: 'Alzheimer\'s Disease',
          imagePath: 'assets/images/neuro_alzheimers.png',
          category: 'template',
        ),
      },
    ),

    // ==================== HEPATIC SYSTEM ====================
    'hepatic': SystemConfig(
      id: 'hepatic',
      name: 'Hepatic System',
      icon: '🔶',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'lesion', name: 'Lesion', color: Color(0xFFDC2626), defaultSize: 12),
        ConditionTool(id: 'cyst', name: 'Cyst', color: Color(0xFF2563EB), defaultSize: 12),
        ConditionTool(id: 'tumor', name: 'Tumor', color: Color(0xFF7C2D12), defaultSize: 16),
        ConditionTool(id: 'fibrosis', name: 'Fibrosis', color: Color(0xFFEA580C), defaultSize: 14),
        ConditionTool(id: 'inflammation', name: 'Inflammation', color: Color(0xFFF59E0B), defaultSize: 14),
      ],
      anatomyDiagrams: {
        'anterior': DiagramConfig(
          id: 'anterior',
          name: 'Anterior View',
          imagePath: 'assets/images/hepatic_anterior.png',
          category: 'anatomy',
        ),
        'posterior': DiagramConfig(
          id: 'posterior',
          name: 'Posterior View',
          imagePath: 'assets/images/hepatic_posterior.png',
          category: 'anatomy',
        ),
        'segments': DiagramConfig(
          id: 'segments',
          name: 'Liver Segments',
          imagePath: 'assets/images/hepatic_segments.png',
          category: 'anatomy',
        ),
      },
      systemTemplates: {
        'cirrhosis': DiagramConfig(
          id: 'cirrhosis',
          name: 'Cirrhosis',
          imagePath: 'assets/images/hepatic_cirrhosis.png',
          category: 'template',
        ),
        'hepatitis': DiagramConfig(
          id: 'hepatitis',
          name: 'Hepatitis',
          imagePath: 'assets/images/hepatic_hepatitis.png',
          category: 'template',
        ),
      },
    ),

    // ==================== GYNAECOLOGY SYSTEM ====================
    'gynaecology': SystemConfig(
      id: 'gynaecology',
      name: 'Gynaecology',
      icon: '♀️',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'lesion', name: 'Lesion', color: Color(0xFFDC2626), defaultSize: 12),
        ConditionTool(id: 'cyst', name: 'Cyst', color: Color(0xFF2563EB), defaultSize: 12),
        ConditionTool(id: 'fibroid', name: 'Fibroid', color: Color(0xFF7C2D12), defaultSize: 16),
        ConditionTool(id: 'polyp', name: 'Polyp', color: Color(0xFFEA580C), defaultSize: 10),
        ConditionTool(id: 'mass', name: 'Mass', color: Color(0xFF9333EA), defaultSize: 14),
      ],
      anatomyDiagrams: {
        'uterus': DiagramConfig(
          id: 'uterus',
          name: 'Uterus',
          imagePath: 'assets/images/gynae_uterus.png',
          category: 'anatomy',
        ),
        'ovaries': DiagramConfig(
          id: 'ovaries',
          name: 'Ovaries',
          imagePath: 'assets/images/gynae_ovaries.png',
          category: 'anatomy',
        ),
        'cervix': DiagramConfig(
          id: 'cervix',
          name: 'Cervix',
          imagePath: 'assets/images/gynae_cervix.png',
          category: 'anatomy',
        ),
        'uterus_3d': DiagramConfig(
          id: 'uterus_3d',
          name: 'Uterus Normal 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'fibroid_intramural_3d': DiagramConfig(
          id: 'fibroid_intramural_3d',
          name: 'Fibroid - Intramural 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'fibroid_submucosal_3d': DiagramConfig(
          id: 'fibroid_submucosal_3d',
          name: 'Fibroid - Submucosal 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'fibroid_subserosal_3d': DiagramConfig(
          id: 'fibroid_subserosal_3d',
          name: 'Fibroid - Subserosal 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'fibroid_pedunculated_3d': DiagramConfig(
          id: 'fibroid_pedunculated_3d',
          name: 'Fibroid - Pedunculated 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'fibroid_cervical_3d': DiagramConfig(
          id: 'fibroid_cervical_3d',
          name: 'Fibroid - Cervical 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'fibroid_multiple_3d': DiagramConfig(
          id: 'fibroid_multiple_3d',
          name: 'Fibroid - Multiple 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'fibroid_degenerating_3d': DiagramConfig(
          id: 'fibroid_degenerating_3d',
          name: 'Fibroid - Degenerating 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'simple_cyst_3d': DiagramConfig(
          id: 'simple_cyst_3d',
          name: 'Ovarian Cyst - Simple 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'hemorrhagic_cyst_3d': DiagramConfig(
          id: 'hemorrhagic_cyst_3d',
          name: 'Ovarian Cyst - Hemorrhagic 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'endometrioid_cyst_3d': DiagramConfig(
          id: 'endometrioid_cyst_3d',
          name: 'Ovarian Cyst - Endometrioid 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'dermoid_cyst_3d': DiagramConfig(
          id: 'dermoid_cyst_3d',
          name: 'Ovarian Cyst - Dermoid 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'adenomyosis_3d': DiagramConfig(
          id: 'adenomyosis_3d',
          name: 'Uterine Adenomyosis 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'endometrial_polyp_3d': DiagramConfig(
          id: 'endometrial_polyp_3d',
          name: 'Endometrial Polyp 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'endometrial_hyperplasia_3d': DiagramConfig(
          id: 'endometrial_hyperplasia_3d',
          name: 'Endometrial Hyperplasia 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'endometrial_carcinoma_3d': DiagramConfig(
          id: 'endometrial_carcinoma_3d',
          name: 'Endometrial Carcinoma 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'endometrioma_3d': DiagramConfig(
          id: 'endometrioma_3d',
          name: 'Endometrioma 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'pcos_ovary_3d': DiagramConfig(
          id: 'pcos_ovary_3d',
          name: 'PCOS Ovary 3D',
          imagePath: '',
          category: 'anatomy',
        ),
        'uterine_anomalies_3d': DiagramConfig(
          id: 'uterine_anomalies_3d',
          name: 'Uterine Anomalies 3D',
          imagePath: '',
          category: 'anatomy',
        ),
      },
      systemTemplates: {
        'fibroids': DiagramConfig(
          id: 'fibroids',
          name: 'Uterine Fibroids',
          imagePath: 'assets/images/gynae_fibroids.png',
          category: 'template',
        ),
        'pcos': DiagramConfig(
          id: 'pcos',
          name: 'PCOS',
          imagePath: 'assets/images/gynae_pcos.png',
          category: 'template',
        ),
        'endometriosis': DiagramConfig(
          id: 'endometriosis',
          name: 'Endometriosis',
          imagePath: 'assets/images/gynae_endometriosis.png',
          category: 'template',
        ),
      },
    ),

    // ==================== OBSTETRICS SYSTEM ====================
    'obstetrics': SystemConfig(
      id: 'obstetrics',
      name: 'Obstetrics',
      icon: '🤰',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'marker', name: 'Marker', color: Color(0xFFDC2626), defaultSize: 12),
        ConditionTool(id: 'placenta', name: 'Placenta', color: Color(0xFF7C2D12), defaultSize: 16),
        ConditionTool(id: 'fetus', name: 'Fetus', color: Color(0xFF2563EB), defaultSize: 14),
        ConditionTool(id: 'cord', name: 'Cord', color: Color(0xFF9333EA), defaultSize: 10),
      ],
      anatomyDiagrams: {
        'uterus_pregnant': DiagramConfig(
          id: 'uterus_pregnant',
          name: 'Pregnant Uterus',
          imagePath: 'assets/images/obs_uterus_pregnant.png',
          category: 'anatomy',
        ),
        'pelvis': DiagramConfig(
          id: 'pelvis',
          name: 'Pelvis',
          imagePath: 'assets/images/obs_pelvis.png',
          category: 'anatomy',
        ),
        'fetal_positions': DiagramConfig(
          id: 'fetal_positions',
          name: 'Fetal Positions',
          imagePath: 'assets/images/obs_fetal_positions.png',
          category: 'anatomy',
        ),
      },
      systemTemplates: {
        'preeclampsia': DiagramConfig(
          id: 'preeclampsia',
          name: 'Pre-eclampsia',
          imagePath: 'assets/images/obs_preeclampsia.png',
          category: 'template',
        ),
        'placenta_previa': DiagramConfig(
          id: 'placenta_previa',
          name: 'Placenta Previa',
          imagePath: 'assets/images/obs_placenta_previa.png',
          category: 'template',
        ),
        'ectopic': DiagramConfig(
          id: 'ectopic',
          name: 'Ectopic Pregnancy',
          imagePath: 'assets/images/obs_ectopic.png',
          category: 'template',
        ),
      },
    ),
  };

  // Helper method to get system config by ID
  static SystemConfig? getSystem(String systemId) {
    return systems[systemId];
  }

  // Helper method to get all system IDs
  static List<String> getAllSystemIds() {
    return systems.keys.toList();
  }

  // Helper method to check if system exists
  static bool hasSystem(String systemId) {
    return systems.containsKey(systemId);
  }
}