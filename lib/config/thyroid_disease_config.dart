// lib/config/thyroid_disease_config.dart

class ThyroidDiseaseConfig {
  final String id;
  final String name;
  final String category;
  final String description;
  final String? icd10;
  final List<Map<String, dynamic>> labTests;
  final List<String> symptoms;
  final List<String> signs;
  final List<Map<String, dynamic>> treatments;
  final List<String> complications;
  final String? monitoringPlan;
  final Map<String, String>? targets;

  const ThyroidDiseaseConfig({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.icd10,
    required this.labTests,
    required this.symptoms,
    required this.signs,
    required this.treatments,
    required this.complications,
    this.monitoringPlan,
    this.targets,
  });

  static ThyroidDiseaseConfig? getDiseaseConfig(String diseaseId) {
    return _configs[diseaseId];
  }

  static final Map<String, ThyroidDiseaseConfig> _configs = {
    // HYPOTHYROIDISM
    'primary_hypothyroidism': ThyroidDiseaseConfig(
      id: 'primary_hypothyroidism',
      name: 'Primary Hypothyroidism',
      category: 'hypothyroidism',
      description: 'Underactive thyroid gland failing to produce sufficient thyroid hormones, most commonly due to autoimmune destruction (Hashimoto\'s) or iodine deficiency.',
      icd10: 'E03.9',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Free T4', 'unit': 'ng/dL', 'normalMin': 0.9, 'normalMax': 1.7},
        {'name': 'Free T3', 'unit': 'pg/mL', 'normalMin': 2.0, 'normalMax': 4.4},
        {'name': 'Anti-TPO', 'unit': 'IU/mL', 'normalMin': 0, 'normalMax': 34},
      ],
      symptoms: ['Fatigue', 'Weight gain', 'Cold intolerance', 'Constipation', 'Dry skin', 'Hair loss', 'Depression', 'Memory problems'],
      signs: ['Bradycardia', 'Delayed reflexes', 'Dry coarse skin', 'Hair loss', 'Periorbital puffiness', 'Goiter'],
      treatments: [
        {'name': 'Levothyroxine', 'defaultDose': '25-200 mcg daily', 'frequency': 'Once daily', 'notes': 'Take on empty stomach'},
      ],
      complications: ['Myxedema coma', 'Heart disease', 'Infertility', 'Birth defects'],
      monitoringPlan: 'Check TSH 6-8 weeks after dose changes, then annually once stable',
      targets: {'TSH': '0.4-2.5 mIU/L', 'Free T4': 'Normal range'},
    ),

    'secondary_hypothyroidism': ThyroidDiseaseConfig(
      id: 'secondary_hypothyroidism',
      name: 'Secondary Hypothyroidism',
      category: 'hypothyroidism',
      description: 'Hypothyroidism due to pituitary or hypothalamic dysfunction, resulting in inadequate TSH production.',
      icd10: 'E03.1',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Free T4', 'unit': 'ng/dL', 'normalMin': 0.9, 'normalMax': 1.7},
        {'name': 'Free T3', 'unit': 'pg/mL', 'normalMin': 2.0, 'normalMax': 4.4},
        {'name': 'Cortisol', 'unit': 'mcg/dL', 'normalMin': 5, 'normalMax': 25},
      ],
      symptoms: ['Fatigue', 'Weight gain', 'Cold intolerance', 'Headaches', 'Visual changes'],
      signs: ['Pituitary mass signs', 'Visual field defects', 'Other pituitary hormone deficiencies'],
      treatments: [
        {'name': 'Levothyroxine', 'defaultDose': '25-200 mcg daily', 'frequency': 'Once daily', 'notes': 'Treat after cortisol replacement if needed'},
        {'name': 'Hydrocortisone', 'defaultDose': '10-20 mg daily', 'frequency': 'Divided doses', 'notes': 'If adrenal insufficiency present'},
      ],
      complications: ['Hypopituitarism', 'Adrenal crisis', 'Visual loss'],
      monitoringPlan: 'Monitor Free T4 levels (not TSH), assess other pituitary hormones',
      targets: {'Free T4': 'Upper half of normal range'},
    ),

    'subclinical_hypothyroidism': ThyroidDiseaseConfig(
      id: 'subclinical_hypothyroidism',
      name: 'Subclinical Hypothyroidism',
      category: 'hypothyroidism',
      description: 'Elevated TSH with normal thyroid hormone levels, representing mild thyroid failure.',
      icd10: 'E02',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Free T4', 'unit': 'ng/dL', 'normalMin': 0.9, 'normalMax': 1.7},
      ],
      symptoms: ['Mild fatigue', 'May be asymptomatic'],
      signs: ['Usually none'],
      treatments: [
        {'name': 'Observation', 'defaultDose': 'Monitor TSH every 6-12 months', 'frequency': 'N/A', 'notes': 'If TSH <10 and asymptomatic'},
        {'name': 'Levothyroxine', 'defaultDose': '25-50 mcg daily', 'frequency': 'Once daily', 'notes': 'Consider if TSH >10 or symptomatic'},
      ],
      complications: ['Progression to overt hypothyroidism', 'Cardiovascular risk'],
      monitoringPlan: 'Recheck TSH in 6 months, then annually',
      targets: {'TSH': '<10 mIU/L if not treating'},
    ),

    // HYPERTHYROIDISM
    'graves_disease': ThyroidDiseaseConfig(
      id: 'graves_disease',
      name: 'Graves\' Disease',
      category: 'hyperthyroidism',
      description: 'Autoimmune disorder causing hyperthyroidism due to TSH receptor antibodies stimulating the thyroid gland.',
      icd10: 'E05.0',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Free T4', 'unit': 'ng/dL', 'normalMin': 0.9, 'normalMax': 1.7},
        {'name': 'Free T3', 'unit': 'pg/mL', 'normalMin': 2.0, 'normalMax': 4.4},
        {'name': 'TSI', 'unit': '%', 'normalMin': 0, 'normalMax': 140},
        {'name': 'Anti-TPO', 'unit': 'IU/mL', 'normalMin': 0, 'normalMax': 34},
      ],
      symptoms: ['Weight loss', 'Palpitations', 'Heat intolerance', 'Tremor', 'Anxiety', 'Insomnia', 'Increased appetite'],
      signs: ['Tachycardia', 'Goiter', 'Exophthalmos', 'Lid lag', 'Pretibial myxedema', 'Warm moist skin'],
      treatments: [
        {'name': 'Methimazole', 'defaultDose': '10-30 mg daily', 'frequency': 'Once daily', 'notes': 'First-line antithyroid drug'},
        {'name': 'Propylthiouracil', 'defaultDose': '50-150 mg TID', 'frequency': 'Three times daily', 'notes': 'Use in first trimester pregnancy'},
        {'name': 'Propranolol', 'defaultDose': '20-40 mg QID', 'frequency': 'Four times daily', 'notes': 'For symptom control'},
      ],
      complications: ['Thyroid storm', 'Atrial fibrillation', 'Heart failure', 'Osteoporosis', 'Graves ophthalmopathy'],
      monitoringPlan: 'Check TFT every 4-6 weeks initially, then every 3 months once stable',
      targets: {'TSH': '0.4-4.0 mIU/L', 'Free T4': 'Normal range'},
    ),

    'toxic_multinodular_goiter': ThyroidDiseaseConfig(
      id: 'toxic_multinodular_goiter',
      name: 'Toxic Multinodular Goiter',
      category: 'hyperthyroidism',
      description: 'Multiple autonomously functioning thyroid nodules causing hyperthyroidism, typically in elderly patients.',
      icd10: 'E05.2',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Free T4', 'unit': 'ng/dL', 'normalMin': 0.9, 'normalMax': 1.7},
        {'name': 'Free T3', 'unit': 'pg/mL', 'normalMin': 2.0, 'normalMax': 4.4},
      ],
      symptoms: ['Weight loss', 'Palpitations', 'Heat intolerance', 'Neck swelling'],
      signs: ['Multinodular goiter', 'Tachycardia', 'Atrial fibrillation'],
      treatments: [
        {'name': 'Methimazole', 'defaultDose': '10-30 mg daily', 'frequency': 'Once daily', 'notes': 'Medical management'},
        {'name': 'Radioactive Iodine', 'defaultDose': '10-30 mCi', 'frequency': 'Single dose', 'notes': 'Definitive treatment'},
      ],
      complications: ['Atrial fibrillation', 'Heart failure', 'Compression symptoms'],
      monitoringPlan: 'Monitor TFT every 6-8 weeks until euthyroid',
      targets: {'TSH': 'Normal range', 'Free T4': 'Normal range'},
    ),

    'toxic_adenoma': ThyroidDiseaseConfig(
      id: 'toxic_adenoma',
      name: 'Toxic Adenoma',
      category: 'hyperthyroidism',
      description: 'Single autonomously functioning thyroid nodule causing hyperthyroidism.',
      icd10: 'E05.1',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Free T4', 'unit': 'ng/dL', 'normalMin': 0.9, 'normalMax': 1.7},
        {'name': 'Free T3', 'unit': 'pg/mL', 'normalMin': 2.0, 'normalMax': 4.4},
      ],
      symptoms: ['Weight loss', 'Palpitations', 'Heat intolerance'],
      signs: ['Single thyroid nodule', 'Tachycardia'],
      treatments: [
        {'name': 'Radioactive Iodine', 'defaultDose': '10-20 mCi', 'frequency': 'Single dose', 'notes': 'Preferred treatment'},
        {'name': 'Lobectomy', 'defaultDose': 'Surgery', 'frequency': 'Once', 'notes': 'Alternative to RAI'},
      ],
      complications: ['Atrial fibrillation', 'Compression symptoms if large'],
      monitoringPlan: 'Monitor TFT after treatment',
      targets: {'TSH': 'Normal range'},
    ),

    'subclinical_hyperthyroidism': ThyroidDiseaseConfig(
      id: 'subclinical_hyperthyroidism',
      name: 'Subclinical Hyperthyroidism',
      category: 'hyperthyroidism',
      description: 'Suppressed TSH with normal thyroid hormone levels, representing mild thyroid overactivity.',
      icd10: 'E05.9',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Free T4', 'unit': 'ng/dL', 'normalMin': 0.9, 'normalMax': 1.7},
        {'name': 'Free T3', 'unit': 'pg/mL', 'normalMin': 2.0, 'normalMax': 4.4},
      ],
      symptoms: ['May be asymptomatic', 'Mild palpitations'],
      signs: ['Usually none', 'Possible mild tachycardia'],
      treatments: [
        {'name': 'Observation', 'defaultDose': 'Monitor TSH', 'frequency': 'Every 6 months', 'notes': 'If asymptomatic'},
        {'name': 'Propranolol', 'defaultDose': '10-40 mg BID', 'frequency': 'Twice daily', 'notes': 'If symptomatic'},
      ],
      complications: ['Atrial fibrillation', 'Osteoporosis', 'Progression to overt hyperthyroidism'],
      monitoringPlan: 'Recheck TSH in 3-6 months',
      targets: {'TSH': '>0.1 mIU/L'},
    ),

    // THYROIDITIS
    'hashimotos_thyroiditis': ThyroidDiseaseConfig(
      id: 'hashimotos_thyroiditis',
      name: 'Hashimoto\'s Thyroiditis',
      category: 'thyroiditis',
      description: 'Chronic autoimmune thyroiditis leading to gradual thyroid destruction and hypothyroidism.',
      icd10: 'E06.3',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Free T4', 'unit': 'ng/dL', 'normalMin': 0.9, 'normalMax': 1.7},
        {'name': 'Anti-TPO', 'unit': 'IU/mL', 'normalMin': 0, 'normalMax': 34},
        {'name': 'Anti-Thyroglobulin', 'unit': 'IU/mL', 'normalMin': 0, 'normalMax': 115},
      ],
      symptoms: ['Fatigue', 'Weight gain', 'Cold intolerance', 'Neck fullness'],
      signs: ['Firm goiter', 'Hypothyroid signs'],
      treatments: [
        {'name': 'Levothyroxine', 'defaultDose': '25-200 mcg daily', 'frequency': 'Once daily', 'notes': 'If hypothyroid'},
      ],
      complications: ['Permanent hypothyroidism', 'Thyroid lymphoma (rare)'],
      monitoringPlan: 'Annual TSH monitoring',
      targets: {'TSH': '0.4-2.5 mIU/L if treating'},
    ),

    'subacute_thyroiditis': ThyroidDiseaseConfig(
      id: 'subacute_thyroiditis',
      name: 'Subacute Thyroiditis',
      category: 'thyroiditis',
      description: 'Painful inflammatory thyroid condition, often following viral infection, with triphasic course.',
      icd10: 'E06.1',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Free T4', 'unit': 'ng/dL', 'normalMin': 0.9, 'normalMax': 1.7},
        {'name': 'ESR', 'unit': 'mm/hr', 'normalMin': 0, 'normalMax': 20},
        {'name': 'CRP', 'unit': 'mg/L', 'normalMin': 0, 'normalMax': 5},
      ],
      symptoms: ['Painful thyroid', 'Fever', 'Neck pain', 'Fatigue'],
      signs: ['Tender goiter', 'May be hyperthyroid initially'],
      treatments: [
        {'name': 'NSAIDs', 'defaultDose': 'Ibuprofen 400-800 mg TID', 'frequency': 'Three times daily', 'notes': 'First-line for pain'},
        {'name': 'Prednisolone', 'defaultDose': '40 mg daily', 'frequency': 'Once daily', 'notes': 'If severe pain'},
        {'name': 'Propranolol', 'defaultDose': '20-40 mg TID', 'frequency': 'Three times daily', 'notes': 'For hyperthyroid symptoms'},
      ],
      complications: ['Transient hypothyroidism', 'Recurrence'],
      monitoringPlan: 'Monitor TFT every 4-6 weeks during acute phase',
      targets: {'Pain control': 'Resolution of symptoms'},
    ),

    'postpartum_thyroiditis': ThyroidDiseaseConfig(
      id: 'postpartum_thyroiditis',
      name: 'Postpartum Thyroiditis',
      category: 'thyroiditis',
      description: 'Autoimmune thyroiditis occurring within one year after delivery, with hyperthyroid then hypothyroid phases.',
      icd10: 'O90.5',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Free T4', 'unit': 'ng/dL', 'normalMin': 0.9, 'normalMax': 1.7},
        {'name': 'Anti-TPO', 'unit': 'IU/mL', 'normalMin': 0, 'normalMax': 34},
      ],
      symptoms: ['Hyperthyroid phase → Hypothyroid phase', 'Within 1 year postpartum', 'Fatigue', 'Mood changes'],
      signs: ['Small goiter', 'Variable thyroid function'],
      treatments: [
        {'name': 'Propranolol', 'defaultDose': '20-40 mg BID', 'frequency': 'Twice daily', 'notes': 'For hyperthyroid phase'},
        {'name': 'Levothyroxine', 'defaultDose': '25-100 mcg daily', 'frequency': 'Once daily', 'notes': 'If hypothyroid phase persists >6 months'},
      ],
      complications: ['Permanent hypothyroidism (20-30%)', 'Recurrence in future pregnancies'],
      monitoringPlan: 'Check TFT every 2 months initially, then at 12 months postpartum',
      targets: {'TSH': 'Normal range'},
    ),

    // THYROID NODULES
    'benign_thyroid_nodule': ThyroidDiseaseConfig(
      id: 'benign_thyroid_nodule',
      name: 'Benign Thyroid Nodule',
      category: 'nodules',
      description: 'Non-cancerous thyroid nodule, most commonly colloid nodule or benign follicular adenoma.',
      icd10: 'E04.1',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
      ],
      symptoms: ['Usually asymptomatic', 'Neck lump'],
      signs: ['Palpable nodule', 'Non-tender', 'Mobile'],
      treatments: [
        {'name': 'Observation', 'defaultDose': 'Follow-up ultrasound', 'frequency': '6-12 months', 'notes': 'Most benign nodules'},
        {'name': 'Levothyroxine suppression', 'defaultDose': 'TSH target 0.5-1.0', 'frequency': 'Daily', 'notes': 'Controversial, not routinely recommended'},
      ],
      complications: ['Growth causing compression', 'Rare malignant transformation'],
      monitoringPlan: 'Repeat ultrasound in 12 months, then every 2-3 years if stable',
      targets: {'Nodule size': 'Stable'},
    ),

    'suspicious_thyroid_nodule': ThyroidDiseaseConfig(
      id: 'suspicious_thyroid_nodule',
      name: 'Suspicious Thyroid Nodule',
      category: 'nodules',
      description: 'Thyroid nodule with features concerning for malignancy requiring further evaluation.',
      icd10: 'E04.1',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Calcitonin', 'unit': 'pg/mL', 'normalMin': 0, 'normalMax': 10},
      ],
      symptoms: ['Neck lump', 'Hoarseness', 'Dysphagia', 'Rapid growth'],
      signs: ['Hard nodule', 'Fixed', 'Lymphadenopathy'],
      treatments: [
        {'name': 'FNA biopsy', 'defaultDose': 'Diagnostic procedure', 'frequency': 'Once', 'notes': 'Required for diagnosis'},
        {'name': 'Surgical referral', 'defaultDose': 'Based on FNA results', 'frequency': 'N/A', 'notes': 'If Bethesda IV-VI'},
      ],
      complications: ['Malignancy risk', 'Local invasion if cancer'],
      monitoringPlan: 'Urgent FNA, then management based on results',
      targets: {'Diagnosis': 'Definitive pathology'},
    ),

    // THYROID CANCER
    'papillary_thyroid_carcinoma': ThyroidDiseaseConfig(
      id: 'papillary_thyroid_carcinoma',
      name: 'Papillary Thyroid Carcinoma',
      category: 'cancer',
      description: 'Most common thyroid cancer (80%), generally with excellent prognosis when treated appropriately.',
      icd10: 'C73',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Thyroglobulin', 'unit': 'ng/mL', 'normalMin': 0, 'normalMax': 55},
      ],
      symptoms: ['Neck lump', 'Lymph node enlargement', 'Usually asymptomatic'],
      signs: ['Hard nodule', 'Lymphadenopathy', 'Fixed mass'],
      treatments: [
        {'name': 'Total thyroidectomy', 'defaultDose': 'Surgery', 'frequency': 'Once', 'notes': 'Primary treatment'},
        {'name': 'RAI ablation', 'defaultDose': '30-150 mCi', 'frequency': 'Once', 'notes': 'Post-surgery if indicated'},
        {'name': 'Levothyroxine', 'defaultDose': 'TSH suppression', 'frequency': 'Daily', 'notes': 'Lifelong, TSH target based on risk'},
      ],
      complications: ['Recurrence', 'Lymph node metastases', 'Distant metastases (rare)'],
      monitoringPlan: 'Thyroglobulin and ultrasound surveillance based on risk stratification',
      targets: {'TSH': '<0.1-2.0 mIU/L based on risk', 'Thyroglobulin': 'Undetectable'},
    ),

    'follicular_thyroid_carcinoma': ThyroidDiseaseConfig(
      id: 'follicular_thyroid_carcinoma',
      name: 'Follicular Thyroid Carcinoma',
      category: 'cancer',
      description: 'Second most common thyroid cancer (10-15%), with tendency for hematogenous spread.',
      icd10: 'C73',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
        {'name': 'Thyroglobulin', 'unit': 'ng/mL', 'normalMin': 0, 'normalMax': 55},
      ],
      symptoms: ['Neck lump', 'May have distant metastases at presentation'],
      signs: ['Thyroid nodule', 'May have bone/lung metastases'],
      treatments: [
        {'name': 'Total thyroidectomy', 'defaultDose': 'Surgery', 'frequency': 'Once', 'notes': 'Primary treatment'},
        {'name': 'RAI ablation', 'defaultDose': '100-200 mCi', 'frequency': 'Once', 'notes': 'Usually required'},
        {'name': 'Levothyroxine', 'defaultDose': 'TSH suppression', 'frequency': 'Daily', 'notes': 'Lifelong'},
      ],
      complications: ['Distant metastases (lung, bone)', 'Recurrence'],
      monitoringPlan: 'Thyroglobulin, imaging surveillance',
      targets: {'TSH': '<0.1 mIU/L initially', 'Thyroglobulin': 'Undetectable'},
    ),

    'medullary_thyroid_carcinoma': ThyroidDiseaseConfig(
      id: 'medullary_thyroid_carcinoma',
      name: 'Medullary Thyroid Carcinoma',
      category: 'cancer',
      description: 'Neuroendocrine tumor from parafollicular C cells (3-4%), may be hereditary (MEN2).',
      icd10: 'C73',
      labTests: [
        {'name': 'Calcitonin', 'unit': 'pg/mL', 'normalMin': 0, 'normalMax': 10},
        {'name': 'CEA', 'unit': 'ng/mL', 'normalMin': 0, 'normalMax': 3},
      ],
      symptoms: ['Neck lump', 'Diarrhea', 'Flushing'],
      signs: ['Thyroid nodule', 'Lymphadenopathy', 'MEN syndrome features'],
      treatments: [
        {'name': 'Total thyroidectomy', 'defaultDose': 'With central neck dissection', 'frequency': 'Once', 'notes': 'Primary treatment'},
        {'name': 'Genetic testing', 'defaultDose': 'RET mutation', 'frequency': 'Once', 'notes': 'Screen family if positive'},
      ],
      complications: ['Early lymph node spread', 'Distant metastases', 'MEN2 syndrome associations'],
      monitoringPlan: 'Calcitonin and CEA monitoring',
      targets: {'Calcitonin': 'Undetectable post-op', 'CEA': 'Normal range'},
    ),

    'anaplastic_thyroid_carcinoma': ThyroidDiseaseConfig(
      id: 'anaplastic_thyroid_carcinoma',
      name: 'Anaplastic Thyroid Carcinoma',
      category: 'cancer',
      description: 'Highly aggressive undifferentiated thyroid cancer (<2%), with very poor prognosis.',
      icd10: 'C73',
      labTests: [
        {'name': 'TSH', 'unit': 'mIU/L', 'normalMin': 0.4, 'normalMax': 4.0},
      ],
      symptoms: ['Rapidly growing neck mass', 'Hoarseness', 'Dysphagia', 'Dyspnea', 'Stridor'],
      signs: ['Large fixed mass', 'Stridor', 'Lymphadenopathy', 'Vocal cord paralysis'],
      treatments: [
        {'name': 'Palliative care', 'defaultDose': 'Comfort measures', 'frequency': 'Ongoing', 'notes': 'Primary focus'},
        {'name': 'External beam radiation', 'defaultDose': '40-60 Gy', 'frequency': 'Daily fractions', 'notes': 'Palliative'},
        {'name': 'Chemotherapy', 'defaultDose': 'Doxorubicin/cisplatin', 'frequency': 'Cycles', 'notes': 'Limited benefit'},
      ],
      complications: ['Airway obstruction', 'Local invasion', 'Distant metastases'],
      monitoringPlan: 'Symptom management, airway monitoring',
      targets: {'Goals': 'Palliation, quality of life'},
    ),
  };
}