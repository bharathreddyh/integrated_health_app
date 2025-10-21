// lib/models/canvas_system_config.dart
// System configurations for multi-system canvas tool

import 'package:flutter/material.dart';

class CanvasSystemConfig {
  final String id;
  final String name;
  final String icon;
  final Color primaryColor;
  final List<DiagramOption> anatomyDiagrams;
  final List<DiagramOption> systemTemplates;
  final List<CanvasTool> tools;

  const CanvasSystemConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.primaryColor,
    required this.anatomyDiagrams,
    required this.systemTemplates,
    required this.tools,
  });
}

class DiagramOption {
  final String id;
  final String name;
  final String? description;

  const DiagramOption({
    required this.id,
    required this.name,
    this.description,
  });
}

class CanvasTool {
  final String id;
  final String name;
  final Color color;
  final double defaultSize;

  const CanvasTool({
    required this.id,
    required this.name,
    required this.color,
    required this.defaultSize,
  });
}

// System Configurations
class SystemConfigurations {
  static const List<CanvasSystemConfig> allSystems = [
    // KIDNEY SYSTEM
    CanvasSystemConfig(
      id: 'kidney',
      name: 'Renal System',
      icon: '🫘',
      primaryColor: Color(0xFF8B4513),
      anatomyDiagrams: [
        DiagramOption(id: 'anatomical', name: 'Detailed Anatomy'),
        DiagramOption(id: 'simple', name: 'Simple Diagram'),
        DiagramOption(id: 'crossSection', name: 'Cross-Section View'),
        DiagramOption(id: 'nephron', name: 'Nephron (Microscopic)'),
      ],
      systemTemplates: [
        DiagramOption(id: 'polycystic', name: 'Polycystic Kidney Disease'),
        DiagramOption(id: 'pyelonephritis', name: 'Pyelonephritis'),
        DiagramOption(id: 'glomerulonephritis', name: 'Glomerulonephritis'),
        DiagramOption(id: 'aki', name: 'Acute Kidney Injury'),
        DiagramOption(id: 'ckd', name: 'Chronic Kidney Disease'),
      ],
      tools: [
        CanvasTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        CanvasTool(id: 'calculi', name: 'Calculi', color: Colors.grey, defaultSize: 8),
        CanvasTool(id: 'cyst', name: 'Cyst', color: Color(0xFF2563EB), defaultSize: 12),
        CanvasTool(id: 'tumor', name: 'Tumor', color: Color(0xFF7C2D12), defaultSize: 16),
        CanvasTool(id: 'inflammation', name: 'Inflammation', color: Color(0xFFEA580C), defaultSize: 14),
        CanvasTool(id: 'blockage', name: 'Blockage', color: Color(0xFF9333EA), defaultSize: 10),
      ],
    ),

    // CARDIAC SYSTEM
    CanvasSystemConfig(
      id: 'cardiac',
      name: 'Cardiac System',
      icon: '❤️',
      primaryColor: Color(0xFFDC2626),
      anatomyDiagrams: [
        DiagramOption(id: 'anterior', name: 'Anterior View'),
        DiagramOption(id: 'posterior', name: 'Posterior View'),
        DiagramOption(id: 'crossSection', name: 'Cross-Section'),
        DiagramOption(id: 'coronaryArteries', name: 'Coronary Arteries'),
      ],
      systemTemplates: [
        DiagramOption(id: 'mi', name: 'Myocardial Infarction'),
        DiagramOption(id: 'heartFailure', name: 'Heart Failure'),
        DiagramOption(id: 'atrialFib', name: 'Atrial Fibrillation'),
        DiagramOption(id: 'valvular', name: 'Valvular Heart Disease'),
        DiagramOption(id: 'cad', name: 'Coronary Artery Disease'),
      ],
      tools: [
        CanvasTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        CanvasTool(id: 'stenosis', name: 'Stenosis', color: Color(0xFFDC2626), defaultSize: 10),
        CanvasTool(id: 'blockage', name: 'Blockage', color: Color(0xFF991B1B), defaultSize: 12),
        CanvasTool(id: 'infarction', name: 'Infarction', color: Color(0xFFEF4444), defaultSize: 16),
        CanvasTool(id: 'valve', name: 'Valve Issue', color: Color(0xFFF59E0B), defaultSize: 10),
        CanvasTool(id: 'arrhythmia', name: 'Arrhythmia Area', color: Color(0xFFFBBF24), defaultSize: 14),
      ],
    ),

    // RESPIRATORY SYSTEM
    CanvasSystemConfig(
      id: 'respiratory',
      name: 'Respiratory System',
      icon: '🫁',
      primaryColor: Color(0xFF0EA5E9),
      anatomyDiagrams: [
        DiagramOption(id: 'anterior', name: 'Anterior View'),
        DiagramOption(id: 'posterior', name: 'Posterior View'),
        DiagramOption(id: 'leftLateral', name: 'Left Lateral'),
        DiagramOption(id: 'rightLateral', name: 'Right Lateral'),
        DiagramOption(id: 'lobes', name: 'Lobar Anatomy'),
      ],
      systemTemplates: [
        DiagramOption(id: 'pneumonia', name: 'Pneumonia'),
        DiagramOption(id: 'copd', name: 'COPD'),
        DiagramOption(id: 'asthma', name: 'Asthma'),
        DiagramOption(id: 'pleuralEffusion', name: 'Pleural Effusion'),
        DiagramOption(id: 'pneumothorax', name: 'Pneumothorax'),
      ],
      tools: [
        CanvasTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        CanvasTool(id: 'nodule', name: 'Nodule', color: Color(0xFF64748B), defaultSize: 8),
        CanvasTool(id: 'infiltrate', name: 'Infiltrate', color: Color(0xFF0EA5E9), defaultSize: 14),
        CanvasTool(id: 'effusion', name: 'Effusion', color: Color(0xFF06B6D4), defaultSize: 16),
        CanvasTool(id: 'consolidation', name: 'Consolidation', color: Color(0xFF0284C7), defaultSize: 12),
        CanvasTool(id: 'mass', name: 'Mass', color: Color(0xFF475569), defaultSize: 16),
      ],
    ),

    // NEUROLOGICAL SYSTEM
    CanvasSystemConfig(
      id: 'neurological',
      name: 'Neurological System',
      icon: '🧠',
      primaryColor: Color(0xFF8B5CF6),
      anatomyDiagrams: [
        DiagramOption(id: 'sagittal', name: 'Sagittal View'),
        DiagramOption(id: 'coronal', name: 'Coronal View'),
        DiagramOption(id: 'axial', name: 'Axial View'),
        DiagramOption(id: 'lobes', name: 'Brain Lobes'),
      ],
      systemTemplates: [
        DiagramOption(id: 'stroke', name: 'Stroke'),
        DiagramOption(id: 'hemorrhage', name: 'Intracranial Hemorrhage'),
        DiagramOption(id: 'tumor', name: 'Brain Tumor'),
        DiagramOption(id: 'meningitis', name: 'Meningitis'),
        DiagramOption(id: 'seizure', name: 'Seizure Disorder'),
      ],
      tools: [
        CanvasTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        CanvasTool(id: 'lesion', name: 'Lesion', color: Color(0xFF8B5CF6), defaultSize: 12),
        CanvasTool(id: 'hemorrhage', name: 'Hemorrhage', color: Color(0xFFDC2626), defaultSize: 14),
        CanvasTool(id: 'infarct', name: 'Infarct', color: Color(0xFF7C3AED), defaultSize: 16),
        CanvasTool(id: 'edema', name: 'Edema', color: Color(0xFFA78BFA), defaultSize: 14),
        CanvasTool(id: 'tumor', name: 'Tumor', color: Color(0xFF6D28D9), defaultSize: 18),
      ],
    ),

    // HEPATIC SYSTEM
    CanvasSystemConfig(
      id: 'hepatic',
      name: 'Hepatic System',
      icon: '🟤',
      primaryColor: Color(0xFF92400E),
      anatomyDiagrams: [
        DiagramOption(id: 'anatomical', name: 'Detailed Anatomy'),
        DiagramOption(id: 'segments', name: 'Liver Segments'),
        DiagramOption(id: 'bloodSupply', name: 'Blood Supply'),
        DiagramOption(id: 'biliary', name: 'Biliary System'),
      ],
      systemTemplates: [
        DiagramOption(id: 'cirrhosis', name: 'Cirrhosis'),
        DiagramOption(id: 'hepatitis', name: 'Hepatitis'),
        DiagramOption(id: 'fattyLiver', name: 'Fatty Liver Disease'),
        DiagramOption(id: 'hepatoma', name: 'Hepatocellular Carcinoma'),
        DiagramOption(id: 'cholecystitis', name: 'Cholecystitis'),
      ],
      tools: [
        CanvasTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        CanvasTool(id: 'nodule', name: 'Nodule', color: Color(0xFF92400E), defaultSize: 10),
        CanvasTool(id: 'lesion', name: 'Lesion', color: Color(0xFFA16207), defaultSize: 12),
        CanvasTool(id: 'fibrosis', name: 'Fibrosis', color: Color(0xFFB45309), defaultSize: 14),
        CanvasTool(id: 'cyst', name: 'Cyst', color: Color(0xFF0EA5E9), defaultSize: 12),
        CanvasTool(id: 'tumor', name: 'Tumor', color: Color(0xFF78350F), defaultSize: 16),
      ],
    ),

    // MUSCULOSKELETAL SYSTEM
    CanvasSystemConfig(
      id: 'musculoskeletal',
      name: 'Musculoskeletal System',
      icon: '🦴',
      primaryColor: Color(0xFFF5F5F4),
      anatomyDiagrams: [
        DiagramOption(id: 'anterior', name: 'Anterior Skeleton'),
        DiagramOption(id: 'posterior', name: 'Posterior Skeleton'),
        DiagramOption(id: 'spine', name: 'Spinal Column'),
        DiagramOption(id: 'joints', name: 'Major Joints'),
      ],
      systemTemplates: [
        DiagramOption(id: 'fracture', name: 'Fracture'),
        DiagramOption(id: 'arthritis', name: 'Arthritis'),
        DiagramOption(id: 'dislocation', name: 'Dislocation'),
        DiagramOption(id: 'sprain', name: 'Sprain/Strain'),
        DiagramOption(id: 'osteoporosis', name: 'Osteoporosis'),
      ],
      tools: [
        CanvasTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
        CanvasTool(id: 'fracture', name: 'Fracture', color: Color(0xFFDC2626), defaultSize: 12),
        CanvasTool(id: 'inflammation', name: 'Inflammation', color: Color(0xFFF97316), defaultSize: 14),
        CanvasTool(id: 'degeneration', name: 'Degeneration', color: Color(0xFF78350F), defaultSize: 12),
        CanvasTool(id: 'edema', name: 'Edema', color: Color(0xFF0EA5E9), defaultSize: 14),
        CanvasTool(id: 'tear', name: 'Tear', color: Color(0xFFEF4444), defaultSize: 10),
      ],
    ),
  ];

  static CanvasSystemConfig getSystemById(String id) {
    return allSystems.firstWhere(
          (system) => system.id == id,
      orElse: () => allSystems.first, // Default to kidney
    );
  }

  static List<DiagramOption> getAllDiagramOptions(String systemId) {
    final system = getSystemById(systemId);
    return [...system.anatomyDiagrams, ...system.systemTemplates];
  }

  static Map<String, String> getDiagramTypeMap(String systemId) {
    final options = getAllDiagramOptions(systemId);
    return Map.fromEntries(
      options.map((opt) => MapEntry(opt.id, opt.name)),
    );
  }
}