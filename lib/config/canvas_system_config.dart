// lib/config/canvas_system_config.dart

import 'package:flutter/material.dart';
import '../models/condition_tool.dart';

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

  Map<String, DiagramConfig> get allDiagrams => {
    ...anatomyDiagrams,
    ...systemTemplates,
  };
}

class DiagramConfig {
  final String id;
  final String name;
  final String imagePath;
  final String category;

  const DiagramConfig({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.category,
  });
}

class CanvasSystemConfig {
  static const Map<String, SystemConfig> systems = {
    // ==================== KIDNEY SYSTEM ====================
    'kidney': SystemConfig(
      id: 'kidney',
      name: 'Renal System',
      icon: '🫘',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'calculi', name: 'Calculi', color: Color(0xFF78716C), defaultSize: 10),
        ConditionTool(id: 'cyst', name: 'Cyst', color: Color(0xFF2563EB), defaultSize: 12),
        ConditionTool(id: 'tumor', name: 'Tumor', color: Color(0xFF7C2D12), defaultSize: 16),
        // Removed: inflammation and blockage
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
        'heartFailure': DiagramConfig(
          id: 'heartFailure',
          name: 'Heart Failure',
          imagePath: 'assets/images/cardiac_heart_failure.png',
          category: 'template',
        ),
        'atrialFib': DiagramConfig(
          id: 'atrialFib',
          name: 'Atrial Fibrillation',
          imagePath: 'assets/images/cardiac_atrial_fib.png',
          category: 'template',
        ),
      },
    ),

    // ==================== RESPIRATORY SYSTEM ====================
    'respiratory': SystemConfig(
      id: 'respiratory',
      name: 'Respiratory System',
      icon: '🫁',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'nodule', name: 'Nodule', color: Color(0xFF7C2D12), defaultSize: 8),
        ConditionTool(id: 'infiltrate', name: 'Infiltrate', color: Color(0xFFEA580C), defaultSize: 14),
        ConditionTool(id: 'effusion', name: 'Effusion', color: Color(0xFF2563EB), defaultSize: 16),
        ConditionTool(id: 'consolidation', name: 'Consolidation', color: Color(0xFF991B1B), defaultSize: 14),
        ConditionTool(id: 'mass', name: 'Mass', color: Color(0xFF7C2D12), defaultSize: 16),
      ],
      anatomyDiagrams: {
        'anterior': DiagramConfig(
          id: 'anterior',
          name: 'Anterior View',
          imagePath: 'assets/images/respiratory_anterior.png',
          category: 'anatomy',
        ),
        'posterior': DiagramConfig(
          id: 'posterior',
          name: 'Posterior View',
          imagePath: 'assets/images/respiratory_posterior.png',
          category: 'anatomy',
        ),
        'leftLateral': DiagramConfig(
          id: 'leftLateral',
          name: 'Left Lateral',
          imagePath: 'assets/images/respiratory_left_lateral.png',
          category: 'anatomy',
        ),
        'rightLateral': DiagramConfig(
          id: 'rightLateral',
          name: 'Right Lateral',
          imagePath: 'assets/images/respiratory_right_lateral.png',
          category: 'anatomy',
        ),
      },
      systemTemplates: {
        'pneumonia': DiagramConfig(
          id: 'pneumonia',
          name: 'Pneumonia',
          imagePath: 'assets/images/respiratory_pneumonia.png',
          category: 'template',
        ),
        'copd': DiagramConfig(
          id: 'copd',
          name: 'COPD',
          imagePath: 'assets/images/respiratory_copd.png',
          category: 'template',
        ),
        'asthma': DiagramConfig(
          id: 'asthma',
          name: 'Asthma',
          imagePath: 'assets/images/respiratory_asthma.png',
          category: 'template',
        ),
      },
    ),

    // ==================== NEUROLOGICAL SYSTEM ====================
    'neurological': SystemConfig(
      id: 'neurological',
      name: 'Neurological System',
      icon: '🧠',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'lesion', name: 'Lesion', color: Color(0xFFDC2626), defaultSize: 12),
        ConditionTool(id: 'tumor', name: 'Tumor', color: Color(0xFF7C2D12), defaultSize: 16),
        ConditionTool(id: 'hemorrhage', name: 'Hemorrhage', color: Color(0xFF991B1B), defaultSize: 14),
        ConditionTool(id: 'infarct', name: 'Infarct', color: Color(0xFF9333EA), defaultSize: 14),
        ConditionTool(id: 'atrophy', name: 'Atrophy', color: Color(0xFF78716C), defaultSize: 12),
      ],
      anatomyDiagrams: {
        'sagittal': DiagramConfig(
          id: 'sagittal',
          name: 'Sagittal View',
          imagePath: 'assets/images/neuro_sagittal.png',
          category: 'anatomy',
        ),
        'axial': DiagramConfig(
          id: 'axial',
          name: 'Axial View',
          imagePath: 'assets/images/neuro_axial.png',
          category: 'anatomy',
        ),
        'coronal': DiagramConfig(
          id: 'coronal',
          name: 'Coronal View',
          imagePath: 'assets/images/neuro_coronal.png',
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
        'parkinsons': DiagramConfig(
          id: 'parkinsons',
          name: 'Parkinson\'s Disease',
          imagePath: 'assets/images/neuro_parkinsons.png',
          category: 'template',
        ),
      },
    ),

    // ==================== HEPATIC SYSTEM ====================
    'hepatic': SystemConfig(
      id: 'hepatic',
      name: 'Hepatic System',
      icon: '🟤',
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
        'fattyLiver': DiagramConfig(
          id: 'fattyLiver',
          name: 'Fatty Liver Disease',
          imagePath: 'assets/images/hepatic_fatty_liver.png',
          category: 'template',
        ),
      },
    ),

    // ==================== MUSCULOSKELETAL SYSTEM ====================
    'musculoskeletal': SystemConfig(
      id: 'musculoskeletal',
      name: 'Musculoskeletal System',
      icon: '🦴',
      tools: [
        ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        ConditionTool(id: 'fracture', name: 'Fracture', color: Color(0xFFDC2626), defaultSize: 12),
        ConditionTool(id: 'dislocation', name: 'Dislocation', color: Color(0xFFEA580C), defaultSize: 14),
        ConditionTool(id: 'arthritis', name: 'Arthritis', color: Color(0xFF9333EA), defaultSize: 12),
        ConditionTool(id: 'tear', name: 'Tear', color: Color(0xFF991B1B), defaultSize: 10),
        ConditionTool(id: 'inflammation', name: 'Inflammation', color: Color(0xFFF59E0B), defaultSize: 14),
      ],
      anatomyDiagrams: {
        'spine': DiagramConfig(
          id: 'spine',
          name: 'Spine',
          imagePath: 'assets/images/msk_spine.png',
          category: 'anatomy',
        ),
        'knee': DiagramConfig(
          id: 'knee',
          name: 'Knee',
          imagePath: 'assets/images/msk_knee.png',
          category: 'anatomy',
        ),
        'shoulder': DiagramConfig(
          id: 'shoulder',
          name: 'Shoulder',
          imagePath: 'assets/images/msk_shoulder.png',
          category: 'anatomy',
        ),
        'hip': DiagramConfig(
          id: 'hip',
          name: 'Hip',
          imagePath: 'assets/images/msk_hip.png',
          category: 'anatomy',
        ),
      },
      systemTemplates: {
        'osteoarthritis': DiagramConfig(
          id: 'osteoarthritis',
          name: 'Osteoarthritis',
          imagePath: 'assets/images/msk_osteoarthritis.png',
          category: 'template',
        ),
        'rheumatoid': DiagramConfig(
          id: 'rheumatoid',
          name: 'Rheumatoid Arthritis',
          imagePath: 'assets/images/msk_rheumatoid.png',
          category: 'template',
        ),
        'osteoporosis': DiagramConfig(
          id: 'osteoporosis',
          name: 'Osteoporosis',
          imagePath: 'assets/images/msk_osteoporosis.png',
          category: 'template',
        ),
      },
    ),
  };
}