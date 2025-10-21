// lib/models/disease_template.dart

class DiseaseTemplate {
  final String id;
  final String name;
  final String system; // 'endocrine', 'renal', 'cardiac', etc.
  final String category; // 'thyroid', 'diabetes', 'calculi', etc.
  final List<String> patientDiagramUrls; // URLs/paths to patient-friendly diagrams
  final List<String> requiredLabTests; // Lab test names that auto-fill
  final List<String> commonSymptoms;
  final String? defaultDiagnosis;
  final List<String>? treatmentSuggestions;

  const DiseaseTemplate({
    required this.id,
    required this.name,
    required this.system,
    required this.category,
    required this.patientDiagramUrls,
    required this.requiredLabTests,
    required this.commonSymptoms,
    this.defaultDiagnosis,
    this.treatmentSuggestions,
  });
}

// Pre-defined Disease Templates
class DiseaseTemplates {

  // ==================== ENDOCRINE SYSTEM ====================

  // Thyroid Disorders
  static const hashimotoThyroiditis = DiseaseTemplate(
    id: 'hashimoto',
    name: "Hashimoto's Thyroiditis",
    system: 'endocrine',
    category: 'thyroid',
    patientDiagramUrls: [
      'assets/diagrams/thyroid_location.png',
      'assets/diagrams/hashimoto_mechanism.png',
      'assets/diagrams/thyroid_antibodies.png',
    ],
    requiredLabTests: ['TSH', 'T3', 'T4', 'Free T4', 'Anti-TPO', 'Anti-Tg'],
    commonSymptoms: [
      'Fatigue',
      'Weight gain',
      'Cold intolerance',
      'Dry skin',
      'Hair loss',
      'Constipation',
      'Depression',
    ],
    defaultDiagnosis: "Hashimoto's Thyroiditis (Autoimmune Hypothyroidism)",
    treatmentSuggestions: [
      'Levothyroxine replacement therapy',
      'Regular TSH monitoring',
      'Selenium supplementation may help',
    ],
  );

  static const gravesDisease = DiseaseTemplate(
    id: 'graves',
    name: "Graves' Disease",
    system: 'endocrine',
    category: 'thyroid',
    patientDiagramUrls: [
      'assets/diagrams/thyroid_location.png',
      'assets/diagrams/graves_hyperthyroid.png',
    ],
    requiredLabTests: ['TSH', 'T3', 'T4', 'Free T4', 'TSH Receptor Antibody'],
    commonSymptoms: [
      'Weight loss',
      'Rapid heartbeat',
      'Anxiety',
      'Tremors',
      'Heat intolerance',
      'Bulging eyes (exophthalmos)',
    ],
    defaultDiagnosis: "Graves' Disease (Autoimmune Hyperthyroidism)",
  );

  // Diabetes
  static const type2Diabetes = DiseaseTemplate(
    id: 'type2_diabetes',
    name: 'Type 2 Diabetes Mellitus',
    system: 'endocrine',
    category: 'diabetes',
    patientDiagramUrls: [
      'assets/diagrams/diabetes_insulin_resistance.png',
      'assets/diagrams/blood_sugar_levels.png',
      'assets/diagrams/diabetes_complications.png',
    ],
    requiredLabTests: ['Fasting Blood Sugar', 'PPBS', 'HbA1c', 'Fasting Insulin'],
    commonSymptoms: [
      'Increased thirst',
      'Frequent urination',
      'Increased hunger',
      'Fatigue',
      'Blurred vision',
      'Slow healing wounds',
    ],
    defaultDiagnosis: 'Type 2 Diabetes Mellitus',
    treatmentSuggestions: [
      'Lifestyle modifications (diet & exercise)',
      'Metformin as first-line therapy',
      'Regular blood sugar monitoring',
    ],
  );

  static const type1Diabetes = DiseaseTemplate(
    id: 'type1_diabetes',
    name: 'Type 1 Diabetes Mellitus',
    system: 'endocrine',
    category: 'diabetes',
    patientDiagramUrls: [
      'assets/diagrams/type1_pancreas.png',
      'assets/diagrams/autoimmune_beta_cells.png',
    ],
    requiredLabTests: ['Fasting Blood Sugar', 'HbA1c', 'C-Peptide', 'Anti-GAD'],
    commonSymptoms: [
      'Sudden weight loss',
      'Extreme thirst',
      'Frequent urination',
      'Fatigue',
      'Blurred vision',
    ],
    defaultDiagnosis: 'Type 1 Diabetes Mellitus (Insulin-Dependent)',
  );

  // ==================== RENAL SYSTEM ====================

  static const renalCalculi = DiseaseTemplate(
    id: 'renal_calculi',
    name: 'Renal Calculi (Kidney Stones)',
    system: 'renal',
    category: 'calculi',
    patientDiagramUrls: [
      'assets/diagrams/kidney_stones_location.png',
      'assets/diagrams/stone_types.png',
      'assets/diagrams/stone_formation.png',
    ],
    requiredLabTests: ['Creatinine', 'BUN', 'eGFR', 'Urine Albumin', 'Uric Acid'],
    commonSymptoms: [
      'Severe flank pain',
      'Pain radiating to groin',
      'Hematuria (blood in urine)',
      'Nausea and vomiting',
      'Frequent urination',
      'Painful urination',
    ],
    defaultDiagnosis: 'Renal Calculi with Acute Renal Colic',
    treatmentSuggestions: [
      'Hydration therapy',
      'Pain management (NSAIDs)',
      'Alpha blockers for stone passage',
      'Urology referral if >5mm',
    ],
  );

  static const polycysticKidney = DiseaseTemplate(
    id: 'polycystic_kidney',
    name: 'Polycystic Kidney Disease',
    system: 'renal',
    category: 'cystic',
    patientDiagramUrls: [
      'assets/diagrams/pkd_kidneys.png',
      'assets/diagrams/pkd_cysts.png',
    ],
    requiredLabTests: ['Creatinine', 'BUN', 'eGFR', 'Sodium', 'Potassium'],
    commonSymptoms: [
      'High blood pressure',
      'Back or side pain',
      'Headaches',
      'Blood in urine',
      'Kidney infections',
    ],
    defaultDiagnosis: 'Autosomal Dominant Polycystic Kidney Disease (ADPKD)',
  );

  static const pyelonephritis = DiseaseTemplate(
    id: 'pyelonephritis',
    name: 'Acute Pyelonephritis',
    system: 'renal',
    category: 'infection',
    patientDiagramUrls: [
      'assets/diagrams/pyelonephritis_infection.png',
      'assets/diagrams/kidney_inflammation.png',
    ],
    requiredLabTests: ['WBC Count', 'Creatinine', 'BUN', 'ESR'],
    commonSymptoms: [
      'Fever and chills',
      'Flank pain',
      'Nausea and vomiting',
      'Frequent painful urination',
      'Cloudy or foul-smelling urine',
    ],
    defaultDiagnosis: 'Acute Pyelonephritis (Kidney Infection)',
    treatmentSuggestions: [
      'Antibiotics (empiric then culture-directed)',
      'Hydration',
      'Pain management',
      'Follow-up urine culture',
    ],
  );

  // ==================== CARDIOVASCULAR SYSTEM ====================

  static const hypertension = DiseaseTemplate(
    id: 'hypertension',
    name: 'Essential Hypertension',
    system: 'cardiovascular',
    category: 'hypertension',
    patientDiagramUrls: [
      'assets/diagrams/blood_pressure_explained.png',
      'assets/diagrams/hypertension_effects.png',
    ],
    requiredLabTests: ['Creatinine', 'Sodium', 'Potassium', 'Total Cholesterol', 'LDL', 'HDL'],
    commonSymptoms: [
      'Often asymptomatic',
      'Headaches',
      'Dizziness',
      'Shortness of breath',
    ],
    defaultDiagnosis: 'Essential (Primary) Hypertension',
    treatmentSuggestions: [
      'Lifestyle modifications',
      'ACE inhibitors or ARBs first-line',
      'Regular BP monitoring',
    ],
  );

  // ==================== GET ALL TEMPLATES ====================

  static List<DiseaseTemplate> get allTemplates => [
    // Endocrine
    hashimotoThyroiditis,
    gravesDisease,
    type1Diabetes,
    type2Diabetes,

    // Renal
    renalCalculi,
    polycysticKidney,
    pyelonephritis,

    // Cardiovascular
    hypertension,
  ];

  // Get templates by system
  static List<DiseaseTemplate> getBySystem(String system) {
    return allTemplates.where((t) => t.system == system).toList();
  }

  // Get template by ID
  static DiseaseTemplate? getById(String id) {
    try {
      return allTemplates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // Group templates by system
  static Map<String, List<DiseaseTemplate>> get groupedBySystem {
    final Map<String, List<DiseaseTemplate>> grouped = {};
    for (var template in allTemplates) {
      if (!grouped.containsKey(template.system)) {
        grouped[template.system] = [];
      }
      grouped[template.system]!.add(template);
    }
    return grouped;
  }
}

// System configuration
class MedicalSystem {
  final String id;
  final String name;
  final String icon; // emoji or icon name
  final List<String> categories;

  const MedicalSystem({
    required this.id,
    required this.name,
    required this.icon,
    required this.categories,
  });
}

class MedicalSystems {
  static const List<MedicalSystem> all = [
    MedicalSystem(
      id: 'endocrine',
      name: 'Endocrine System',
      icon: '📊',
      categories: ['thyroid', 'diabetes', 'adrenal'],
    ),
    MedicalSystem(
      id: 'renal',
      name: 'Renal System',
      icon: '🫘',
      categories: ['calculi', 'cystic', 'infection', 'tumor'],
    ),
    MedicalSystem(
      id: 'cardiovascular',
      name: 'Cardiovascular System',
      icon: '❤️',
      categories: ['hypertension', 'mi', 'heart_failure'],
    ),
    MedicalSystem(
      id: 'respiratory',
      name: 'Respiratory System',
      icon: '🫁',
      categories: ['asthma', 'copd', 'pneumonia'],
    ),
    MedicalSystem(
      id: 'nervous',
      name: 'Nervous System',
      icon: '🧠',
      categories: ['stroke', 'epilepsy', 'neuropathy'],
    ),
    MedicalSystem(
      id: 'musculoskeletal',
      name: 'Musculoskeletal System',
      icon: '🦴',
      categories: ['arthritis', 'fracture', 'osteoporosis'],
    ),
  ];

  static MedicalSystem? getById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}