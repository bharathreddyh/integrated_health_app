// lib/models/disease_template_data.dart

import 'disease_template.dart';

class DiseaseTemplateData {
  static final List<DiseaseTemplate> templates = [
    // ============================================================
    // ENDOCRINE SYSTEM - THYROID
    // ============================================================
    DiseaseTemplate(
      id: 'endo_thyroid_hashimoto',
      name: "Hashimoto's Thyroiditis",
      system: 'endocrine',
      category: 'thyroid',
      diagrams: [
        TemplateDiagram(
          id: 'hash_diagram_1',
          title: 'Thyroid Gland Location',
          description: 'Shows where the thyroid is located in the neck',
          imageAsset: 'assets/diagrams/thyroid_location.png',
        ),
        TemplateDiagram(
          id: 'hash_diagram_2',
          title: 'Autoimmune Attack',
          description: 'How antibodies attack the thyroid',
          imageAsset: 'assets/diagrams/hashimoto_mechanism.png',
        ),
        TemplateDiagram(
          id: 'hash_diagram_3',
          title: 'Symptoms Overview',
          description: 'Common symptoms of Hashimoto\'s',
          imageAsset: 'assets/diagrams/thyroid_symptoms.png',
        ),
        TemplateDiagram(
          id: 'hash_diagram_4',
          title: 'Treatment Path',
          description: 'How Hashimoto\'s is treated',
          imageAsset: 'assets/diagrams/thyroid_treatment.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'tsh',
          label: 'TSH',
          fieldType: 'number',
          unit: 'mIU/L',
          autoFillFromLab: 'TSH',
        ),
        TemplateDataField(
          id: 't3',
          label: 'T3',
          fieldType: 'number',
          unit: 'ng/dL',
          autoFillFromLab: 'T3',
        ),
        TemplateDataField(
          id: 't4',
          label: 'T4',
          fieldType: 'number',
          unit: 'μg/dL',
          autoFillFromLab: 'T4',
        ),
        TemplateDataField(
          id: 'anti_tpo',
          label: 'Anti-TPO Antibody',
          fieldType: 'number',
          unit: 'IU/mL',
          autoFillFromLab: 'Anti-TPO',
        ),
        TemplateDataField(
          id: 'anti_tg',
          label: 'Anti-Thyroglobulin',
          fieldType: 'number',
          unit: 'IU/mL',
          autoFillFromLab: 'Anti-Tg',
        ),
      ],
    ),

    DiseaseTemplate(
      id: 'endo_thyroid_graves',
      name: "Graves' Disease",
      system: 'endocrine',
      category: 'thyroid',
      diagrams: [
        TemplateDiagram(
          id: 'graves_diagram_1',
          title: 'Thyroid Overview',
          description: 'Normal vs enlarged thyroid',
          imageAsset: 'assets/diagrams/thyroid_comparison.png',
        ),
        TemplateDiagram(
          id: 'graves_diagram_2',
          title: 'Hyperthyroidism Effects',
          description: 'How excess thyroid hormone affects body',
          imageAsset: 'assets/diagrams/hyperthyroid_effects.png',
        ),
        TemplateDiagram(
          id: 'graves_diagram_3',
          title: 'Eye Changes',
          description: 'Graves\' ophthalmopathy explained',
          imageAsset: 'assets/diagrams/graves_eye.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'tsh',
          label: 'TSH',
          fieldType: 'number',
          unit: 'mIU/L',
          autoFillFromLab: 'TSH',
        ),
        TemplateDataField(
          id: 't3',
          label: 'T3',
          fieldType: 'number',
          unit: 'ng/dL',
          autoFillFromLab: 'T3',
        ),
        TemplateDataField(
          id: 't4',
          label: 'T4',
          fieldType: 'number',
          unit: 'μg/dL',
          autoFillFromLab: 'T4',
        ),
        TemplateDataField(
          id: 'tsi',
          label: 'TSI (Thyroid Stimulating Immunoglobulin)',
          fieldType: 'number',
          unit: '%',
          autoFillFromLab: 'TSI',
        ),
      ],
    ),

    DiseaseTemplate(
      id: 'endo_thyroid_hypothyroid',
      name: 'Hypothyroidism',
      system: 'endocrine',
      category: 'thyroid',
      diagrams: [
        TemplateDiagram(
          id: 'hypo_diagram_1',
          title: 'Underactive Thyroid',
          description: 'What happens when thyroid is underactive',
          imageAsset: 'assets/diagrams/hypothyroid_explained.png',
        ),
        TemplateDiagram(
          id: 'hypo_diagram_2',
          title: 'Symptoms Chart',
          description: 'Common signs of low thyroid',
          imageAsset: 'assets/diagrams/hypothyroid_symptoms.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'tsh',
          label: 'TSH',
          fieldType: 'number',
          unit: 'mIU/L',
          autoFillFromLab: 'TSH',
        ),
        TemplateDataField(
          id: 't4',
          label: 'Free T4',
          fieldType: 'number',
          unit: 'μg/dL',
          autoFillFromLab: 'T4',
        ),
      ],
    ),

    // ============================================================
    // ENDOCRINE SYSTEM - DIABETES
    // ============================================================
    DiseaseTemplate(
      id: 'endo_diabetes_type1',
      name: 'Type 1 Diabetes',
      system: 'endocrine',
      category: 'diabetes',
      diagrams: [
        TemplateDiagram(
          id: 'dm1_diagram_1',
          title: 'Pancreas & Insulin',
          description: 'How Type 1 diabetes affects the pancreas',
          imageAsset: 'assets/diagrams/type1_pancreas.png',
        ),
        TemplateDiagram(
          id: 'dm1_diagram_2',
          title: 'Blood Sugar Regulation',
          description: 'Normal vs diabetic blood sugar control',
          imageAsset: 'assets/diagrams/blood_sugar_control.png',
        ),
        TemplateDiagram(
          id: 'dm1_diagram_3',
          title: 'Insulin Injection Sites',
          description: 'Where to inject insulin',
          imageAsset: 'assets/diagrams/insulin_sites.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'fbs',
          label: 'Fasting Blood Sugar',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'FBS',
        ),
        TemplateDataField(
          id: 'ppbs',
          label: 'Post-Prandial Blood Sugar',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'PPBS',
        ),
        TemplateDataField(
          id: 'hba1c',
          label: 'HbA1c',
          fieldType: 'number',
          unit: '%',
          autoFillFromLab: 'HbA1c',
        ),
        TemplateDataField(
          id: 'c_peptide',
          label: 'C-Peptide',
          fieldType: 'number',
          unit: 'ng/mL',
          autoFillFromLab: 'C-Peptide',
        ),
      ],
    ),

    DiseaseTemplate(
      id: 'endo_diabetes_type2',
      name: 'Type 2 Diabetes',
      system: 'endocrine',
      category: 'diabetes',
      diagrams: [
        TemplateDiagram(
          id: 'dm2_diagram_1',
          title: 'Insulin Resistance',
          description: 'How cells become resistant to insulin',
          imageAsset: 'assets/diagrams/insulin_resistance.png',
        ),
        TemplateDiagram(
          id: 'dm2_diagram_2',
          title: 'Complications Overview',
          description: 'Long-term effects of uncontrolled diabetes',
          imageAsset: 'assets/diagrams/diabetes_complications.png',
        ),
        TemplateDiagram(
          id: 'dm2_diagram_3',
          title: 'Lifestyle Management',
          description: 'Diet and exercise for diabetes control',
          imageAsset: 'assets/diagrams/diabetes_lifestyle.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'fbs',
          label: 'Fasting Blood Sugar',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'FBS',
        ),
        TemplateDataField(
          id: 'ppbs',
          label: 'Post-Prandial Blood Sugar',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'PPBS',
        ),
        TemplateDataField(
          id: 'hba1c',
          label: 'HbA1c',
          fieldType: 'number',
          unit: '%',
          autoFillFromLab: 'HbA1c',
        ),
        TemplateDataField(
          id: 'fasting_insulin',
          label: 'Fasting Insulin',
          fieldType: 'number',
          unit: 'μIU/mL',
          autoFillFromLab: 'Fasting Insulin',
        ),
      ],
    ),

    // ============================================================
    // RENAL SYSTEM - CALCULI
    // ============================================================
    DiseaseTemplate(
      id: 'renal_calculi_kidney_stones',
      name: 'Renal Calculi (Kidney Stones)',
      system: 'renal',
      category: 'calculi',
      diagrams: [
        TemplateDiagram(
          id: 'calculi_diagram_1',
          title: 'Kidney Stone Location',
          description: 'Where stones form in the kidney',
          imageAsset: 'assets/diagrams/kidney_stone_location.png',
        ),
        TemplateDiagram(
          id: 'calculi_diagram_2',
          title: 'Stone Types',
          description: 'Different types of kidney stones',
          imageAsset: 'assets/diagrams/stone_types.png',
        ),
        TemplateDiagram(
          id: 'calculi_diagram_3',
          title: 'Stone Passage',
          description: 'How stones move through urinary system',
          imageAsset: 'assets/diagrams/stone_passage.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'location',
          label: 'Location',
          fieldType: 'text',
          unit: null,
        ),
        TemplateDataField(
          id: 'size',
          label: 'Size',
          fieldType: 'number',
          unit: 'mm',
        ),
        TemplateDataField(
          id: 'number',
          label: 'Number',
          fieldType: 'text',
          unit: null,
        ),
        TemplateDataField(
          id: 'creatinine',
          label: 'Serum Creatinine',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'Creatinine',
        ),
        TemplateDataField(
          id: 'uric_acid',
          label: 'Uric Acid',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'Uric Acid',
        ),
      ],
    ),

    DiseaseTemplate(
      id: 'renal_calculi_ureteric',
      name: 'Ureteric Calculi',
      system: 'renal',
      category: 'calculi',
      diagrams: [
        TemplateDiagram(
          id: 'ureteric_diagram_1',
          title: 'Ureter Obstruction',
          description: 'Stone blocking the ureter',
          imageAsset: 'assets/diagrams/ureteric_obstruction.png',
        ),
        TemplateDiagram(
          id: 'ureteric_diagram_2',
          title: 'Hydronephrosis',
          description: 'Kidney swelling from blockage',
          imageAsset: 'assets/diagrams/hydronephrosis.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'location',
          label: 'Location in Ureter',
          fieldType: 'text',
          unit: null,
        ),
        TemplateDataField(
          id: 'size',
          label: 'Stone Size',
          fieldType: 'number',
          unit: 'mm',
        ),
        TemplateDataField(
          id: 'hydronephrosis',
          label: 'Hydronephrosis Grade',
          fieldType: 'text',
          unit: null,
        ),
      ],
    ),

    // ============================================================
    // RENAL SYSTEM - CYSTIC DISEASES
    // ============================================================
    DiseaseTemplate(
      id: 'renal_cystic_simple',
      name: 'Simple Renal Cyst',
      system: 'renal',
      category: 'cystic',
      diagrams: [
        TemplateDiagram(
          id: 'simple_cyst_1',
          title: 'Simple Kidney Cyst',
          description: 'What a simple cyst looks like',
          imageAsset: 'assets/diagrams/simple_cyst.png',
        ),
        TemplateDiagram(
          id: 'simple_cyst_2',
          title: 'Cyst Characteristics',
          description: 'Benign vs concerning features',
          imageAsset: 'assets/diagrams/cyst_features.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'location',
          label: 'Location',
          fieldType: 'text',
          unit: null,
        ),
        TemplateDataField(
          id: 'size',
          label: 'Size',
          fieldType: 'number',
          unit: 'cm',
        ),
        TemplateDataField(
          id: 'bosniak',
          label: 'Bosniak Classification',
          fieldType: 'text',
          unit: null,
        ),
      ],
    ),

    DiseaseTemplate(
      id: 'renal_cystic_pkd',
      name: 'Polycystic Kidney Disease',
      system: 'renal',
      category: 'cystic',
      diagrams: [
        TemplateDiagram(
          id: 'pkd_diagram_1',
          title: 'PKD Overview',
          description: 'Multiple cysts in both kidneys',
          imageAsset: 'assets/diagrams/pkd_overview.png',
        ),
        TemplateDiagram(
          id: 'pkd_diagram_2',
          title: 'Disease Progression',
          description: 'How PKD progresses over time',
          imageAsset: 'assets/diagrams/pkd_progression.png',
        ),
        TemplateDiagram(
          id: 'pkd_diagram_3',
          title: 'Complications',
          description: 'Common complications of PKD',
          imageAsset: 'assets/diagrams/pkd_complications.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'kidney_size_right',
          label: 'Right Kidney Size',
          fieldType: 'number',
          unit: 'cm',
        ),
        TemplateDataField(
          id: 'kidney_size_left',
          label: 'Left Kidney Size',
          fieldType: 'number',
          unit: 'cm',
        ),
        TemplateDataField(
          id: 'largest_cyst',
          label: 'Largest Cyst',
          fieldType: 'number',
          unit: 'cm',
        ),
        TemplateDataField(
          id: 'creatinine',
          label: 'Creatinine',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'Creatinine',
        ),
        TemplateDataField(
          id: 'egfr',
          label: 'eGFR',
          fieldType: 'number',
          unit: 'mL/min',
          autoFillFromLab: 'eGFR',
        ),
      ],
    ),

    // ============================================================
    // RENAL SYSTEM - TUMORS
    // ============================================================
    DiseaseTemplate(
      id: 'renal_tumor_rcc',
      name: 'Renal Cell Carcinoma',
      system: 'renal',
      category: 'tumors',
      diagrams: [
        TemplateDiagram(
          id: 'rcc_diagram_1',
          title: 'Kidney Tumor Location',
          description: 'Where tumors typically occur',
          imageAsset: 'assets/diagrams/kidney_tumor_location.png',
        ),
        TemplateDiagram(
          id: 'rcc_diagram_2',
          title: 'Tumor Stages',
          description: 'Staging of kidney cancer',
          imageAsset: 'assets/diagrams/rcc_staging.png',
        ),
        TemplateDiagram(
          id: 'rcc_diagram_3',
          title: 'Spread Patterns',
          description: 'How kidney cancer spreads',
          imageAsset: 'assets/diagrams/rcc_metastasis.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'location',
          label: 'Tumor Location',
          fieldType: 'text',
          unit: null,
        ),
        TemplateDataField(
          id: 'size',
          label: 'Tumor Size',
          fieldType: 'number',
          unit: 'cm',
        ),
        TemplateDataField(
          id: 'stage',
          label: 'Clinical Stage',
          fieldType: 'text',
          unit: null,
        ),
        TemplateDataField(
          id: 'hemoglobin',
          label: 'Hemoglobin',
          fieldType: 'number',
          unit: 'g/dL',
          autoFillFromLab: 'Hemoglobin',
        ),
      ],
    ),

    // ============================================================
    // RENAL SYSTEM - INFECTIONS/INFLAMMATION
    // ============================================================
    DiseaseTemplate(
      id: 'renal_infection_pyelonephritis',
      name: 'Pyelonephritis',
      system: 'renal',
      category: 'infections',
      diagrams: [
        TemplateDiagram(
          id: 'pyelo_diagram_1',
          title: 'Kidney Infection',
          description: 'How infection affects the kidney',
          imageAsset: 'assets/diagrams/pyelonephritis.png',
        ),
        TemplateDiagram(
          id: 'pyelo_diagram_2',
          title: 'Infection Path',
          description: 'How bacteria reach the kidney',
          imageAsset: 'assets/diagrams/uti_pathway.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'wbc',
          label: 'WBC Count',
          fieldType: 'number',
          unit: 'cells/μL',
          autoFillFromLab: 'WBC',
        ),
        TemplateDataField(
          id: 'creatinine',
          label: 'Creatinine',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'Creatinine',
        ),
        TemplateDataField(
          id: 'urine_culture',
          label: 'Urine Culture',
          fieldType: 'text',
          unit: null,
        ),
      ],
    ),

    DiseaseTemplate(
      id: 'renal_infection_glomerulo',
      name: 'Glomerulonephritis',
      system: 'renal',
      category: 'infections',
      diagrams: [
        TemplateDiagram(
          id: 'gn_diagram_1',
          title: 'Glomerulus Structure',
          description: 'Normal vs inflamed glomerulus',
          imageAsset: 'assets/diagrams/glomerulus.png',
        ),
        TemplateDiagram(
          id: 'gn_diagram_2',
          title: 'Filtration Process',
          description: 'How inflammation affects filtering',
          imageAsset: 'assets/diagrams/glomerular_filtration.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'creatinine',
          label: 'Creatinine',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'Creatinine',
        ),
        TemplateDataField(
          id: 'bun',
          label: 'BUN',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'BUN',
        ),
        TemplateDataField(
          id: 'albumin',
          label: 'Serum Albumin',
          fieldType: 'number',
          unit: 'g/dL',
          autoFillFromLab: 'Albumin',
        ),
        TemplateDataField(
          id: 'urine_protein',
          label: 'Urine Protein',
          fieldType: 'text',
          unit: null,
        ),
      ],
    ),

    DiseaseTemplate(
      id: 'renal_chronic_ckd',
      name: 'Chronic Kidney Disease',
      system: 'renal',
      category: 'infections',
      diagrams: [
        TemplateDiagram(
          id: 'ckd_diagram_1',
          title: 'CKD Stages',
          description: '5 stages of kidney disease',
          imageAsset: 'assets/diagrams/ckd_stages.png',
        ),
        TemplateDiagram(
          id: 'ckd_diagram_2',
          title: 'Kidney Function',
          description: 'Normal vs damaged kidney',
          imageAsset: 'assets/diagrams/kidney_damage.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'creatinine',
          label: 'Creatinine',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'Creatinine',
        ),
        TemplateDataField(
          id: 'egfr',
          label: 'eGFR',
          fieldType: 'number',
          unit: 'mL/min',
          autoFillFromLab: 'eGFR',
        ),
        TemplateDataField(
          id: 'ckd_stage',
          label: 'CKD Stage',
          fieldType: 'text',
          unit: null,
        ),
      ],
    ),

    // ============================================================
    // CARDIOVASCULAR SYSTEM
    // ============================================================
    DiseaseTemplate(
      id: 'cardiac_hypertension',
      name: 'Hypertension',
      system: 'cardiac',
      category: 'hypertension',
      diagrams: [
        TemplateDiagram(
          id: 'htn_diagram_1',
          title: 'Blood Pressure Explained',
          description: 'What blood pressure means',
          imageAsset: 'assets/diagrams/blood_pressure.png',
        ),
        TemplateDiagram(
          id: 'htn_diagram_2',
          title: 'Organ Damage',
          description: 'How high BP affects organs',
          imageAsset: 'assets/diagrams/htn_complications.png',
        ),
        TemplateDiagram(
          id: 'htn_diagram_3',
          title: 'Lifestyle Management',
          description: 'Controlling blood pressure naturally',
          imageAsset: 'assets/diagrams/htn_lifestyle.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'bp_systolic',
          label: 'Systolic BP',
          fieldType: 'number',
          unit: 'mmHg',
        ),
        TemplateDataField(
          id: 'bp_diastolic',
          label: 'Diastolic BP',
          fieldType: 'number',
          unit: 'mmHg',
        ),
        TemplateDataField(
          id: 'cholesterol',
          label: 'Total Cholesterol',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'Total Cholesterol',
        ),
        TemplateDataField(
          id: 'ldl',
          label: 'LDL',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'LDL',
        ),
        TemplateDataField(
          id: 'hdl',
          label: 'HDL',
          fieldType: 'number',
          unit: 'mg/dL',
          autoFillFromLab: 'HDL',
        ),
      ],
    ),

    DiseaseTemplate(
      id: 'cardiac_mi',
      name: 'Myocardial Infarction',
      system: 'cardiac',
      category: 'cardiac',
      diagrams: [
        TemplateDiagram(
          id: 'mi_diagram_1',
          title: 'Heart Attack Explained',
          description: 'What happens during a heart attack',
          imageAsset: 'assets/diagrams/heart_attack.png',
        ),
        TemplateDiagram(
          id: 'mi_diagram_2',
          title: 'Coronary Arteries',
          description: 'Blood vessels of the heart',
          imageAsset: 'assets/diagrams/coronary_arteries.png',
        ),
        TemplateDiagram(
          id: 'mi_diagram_3',
          title: 'Warning Signs',
          description: 'Symptoms of heart attack',
          imageAsset: 'assets/diagrams/mi_symptoms.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'troponin',
          label: 'Troponin I',
          fieldType: 'number',
          unit: 'ng/mL',
          autoFillFromLab: 'Troponin I',
        ),
        TemplateDataField(
          id: 'ck_mb',
          label: 'CK-MB',
          fieldType: 'number',
          unit: 'U/L',
          autoFillFromLab: 'CK-MB',
        ),
        TemplateDataField(
          id: 'location',
          label: 'Infarct Location',
          fieldType: 'text',
          unit: null,
        ),
      ],
    ),

    DiseaseTemplate(
      id: 'cardiac_heart_failure',
      name: 'Heart Failure',
      system: 'cardiac',
      category: 'cardiac',
      diagrams: [
        TemplateDiagram(
          id: 'hf_diagram_1',
          title: 'Heart Failure Basics',
          description: 'Weak heart muscle explained',
          imageAsset: 'assets/diagrams/heart_failure.png',
        ),
        TemplateDiagram(
          id: 'hf_diagram_2',
          title: 'Fluid Buildup',
          description: 'Why fluid accumulates',
          imageAsset: 'assets/diagrams/fluid_overload.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'bnp',
          label: 'BNP',
          fieldType: 'number',
          unit: 'pg/mL',
          autoFillFromLab: 'BNP',
        ),
        TemplateDataField(
          id: 'ejection_fraction',
          label: 'Ejection Fraction',
          fieldType: 'number',
          unit: '%',
        ),
        TemplateDataField(
          id: 'nyha_class',
          label: 'NYHA Class',
          fieldType: 'text',
          unit: null,
        ),
      ],
    ),

    // ============================================================
    // RESPIRATORY SYSTEM
    // ============================================================
    DiseaseTemplate(
      id: 'respiratory_asthma',
      name: 'Bronchial Asthma',
      system: 'respiratory',
      category: 'respiratory',
      diagrams: [
        TemplateDiagram(
          id: 'asthma_diagram_1',
          title: 'Airways in Asthma',
          description: 'Normal vs asthmatic airways',
          imageAsset: 'assets/diagrams/asthma_airways.png',
        ),
        TemplateDiagram(
          id: 'asthma_diagram_2',
          title: 'Asthma Attack',
          description: 'What happens during an attack',
          imageAsset: 'assets/diagrams/asthma_attack.png',
        ),
        TemplateDiagram(
          id: 'asthma_diagram_3',
          title: 'Inhaler Technique',
          description: 'How to use inhalers properly',
          imageAsset: 'assets/diagrams/inhaler_use.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'peak_flow',
          label: 'Peak Flow',
          fieldType: 'number',
          unit: 'L/min',
        ),
        TemplateDataField(
          id: 'spo2',
          label: 'SpO2',
          fieldType: 'number',
          unit: '%',
        ),
        TemplateDataField(
          id: 'severity',
          label: 'Severity',
          fieldType: 'text',
          unit: null,
        ),
      ],
    ),

    DiseaseTemplate(
      id: 'respiratory_copd',
      name: 'COPD',
      system: 'respiratory',
      category: 'respiratory',
      diagrams: [
        TemplateDiagram(
          id: 'copd_diagram_1',
          title: 'COPD Overview',
          description: 'Emphysema and chronic bronchitis',
          imageAsset: 'assets/diagrams/copd_overview.png',
        ),
        TemplateDiagram(
          id: 'copd_diagram_2',
          title: 'Lung Damage',
          description: 'How COPD affects lung tissue',
          imageAsset: 'assets/diagrams/copd_damage.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'fev1',
          label: 'FEV1',
          fieldType: 'number',
          unit: 'L',
        ),
        TemplateDataField(
          id: 'fvc',
          label: 'FVC',
          fieldType: 'number',
          unit: 'L',
        ),
        TemplateDataField(
          id: 'gold_stage',
          label: 'GOLD Stage',
          fieldType: 'text',
          unit: null,
        ),
      ],
    ),

    DiseaseTemplate(
      id: 'respiratory_pneumonia',
      name: 'Pneumonia',
      system: 'respiratory',
      category: 'respiratory',
      diagrams: [
        TemplateDiagram(
          id: 'pneumonia_diagram_1',
          title: 'Lung Infection',
          description: 'How pneumonia affects lungs',
          imageAsset: 'assets/diagrams/pneumonia_lungs.png',
        ),
        TemplateDiagram(
          id: 'pneumonia_diagram_2',
          title: 'Types of Pneumonia',
          description: 'Bacterial vs viral pneumonia',
          imageAsset: 'assets/diagrams/pneumonia_types.png',
        ),
      ],
      dataFields: [
        TemplateDataField(
          id: 'wbc',
          label: 'WBC Count',
          fieldType: 'number',
          unit: 'cells/μL',
          autoFillFromLab: 'WBC',
        ),
        TemplateDataField(
          id: 'crp',
          label: 'CRP',
          fieldType: 'number',
          unit: 'mg/L',
          autoFillFromLab: 'CRP',
        ),
        TemplateDataField(
          id: 'location',
          label: 'Affected Area',
          fieldType: 'text',
          unit: null,
        ),
      ],
    ),
  ];

  // Helper method to get templates by system
  static List<DiseaseTemplate> getTemplatesBySystem(String system) {
    return templates.where((t) => t.system == system).toList();
  }

  // Helper method to get templates by category
  static List<DiseaseTemplate> getTemplatesByCategory(String category) {
    return templates.where((t) => t.category == category).toList();
  }

  // Helper method to get template by ID
  static DiseaseTemplate? getTemplateById(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Simple system info used by the templates tab in page2_system_selector
class _SystemInfo {
  final String name;
  final String icon;
  _SystemInfo(this.name, this.icon);
}

/// Convenience wrapper so page2_system_selector can call DiseaseTemplates.*
class DiseaseTemplates {
  DiseaseTemplates._();

  static Map<String, List<DiseaseTemplate>> get groupedBySystem {
    final map = <String, List<DiseaseTemplate>>{};
    for (final t in DiseaseTemplateData.templates) {
      final sys = t.system ?? 'other';
      map.putIfAbsent(sys, () => []).add(t);
    }
    return map;
  }

  static DiseaseTemplate? getById(String id) =>
      DiseaseTemplateData.getTemplateById(id);
}

/// Convenience wrapper so page2_system_selector can call MedicalSystems.getById()
class MedicalSystems {
  MedicalSystems._();

  static final _systems = <String, _SystemInfo>{
    'endocrine': _SystemInfo('Endocrine System', '\u{1F9EC}'),
    'renal': _SystemInfo('Renal System', '\u{1FAC0}'),
    'cardiac': _SystemInfo('Cardiovascular System', '\u{2764}'),
    'respiratory': _SystemInfo('Respiratory System', '\u{1FAC1}'),
    'gastrointestinal': _SystemInfo('GI System', '\u{1F4A9}'),
    'neurological': _SystemInfo('Neurological System', '\u{1F9E0}'),
    'musculoskeletal': _SystemInfo('Musculoskeletal System', '\u{1F9B4}'),
    'genitourinary': _SystemInfo('Genitourinary System', '\u{1F6BB}'),
  };

  static _SystemInfo? getById(String id) => _systems[id];
}