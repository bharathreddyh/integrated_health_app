// lib/config/medical_systems_config.dart

import 'package:flutter/material.dart';

// Disease Category Model
class DiseaseCategory {
  final String id;
  final String name;
  final IconData icon;
  final List<String> diseases;

  const DiseaseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.diseases,
  });
}

// Medical System Configuration Model
class MedicalSystemConfig {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<DiseaseCategory> categories;

  const MedicalSystemConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.categories,
  });

  int get totalDiseaseCount {
    return categories.fold(0, (sum, category) => sum + category.diseases.length);
  }
}

// Main Configuration Class
class MedicalSystemsConfig {
  // 🦋 ENDOCRINE SYSTEM (Already Built)
  static const endocrineSystem = MedicalSystemConfig(
    id: 'endocrine',
    name: 'Endocrine System',
    description: 'Hormones, Glands, Metabolism',
    icon: Icons.science,
    color: Color(0xFFEC4899), // Pink
    categories: [
      DiseaseCategory(
        id: 'thyroid',
        name: 'Thyroid Gland',
        icon: Icons.favorite,
        diseases: [
          'Primary Hypothyroidism',
          'Secondary Hypothyroidism',
          'Subclinical Hypothyroidism',
          'Graves\' Disease',
          'Toxic Multinodular Goiter',
          'Toxic Adenoma',
          'Subclinical Hyperthyroidism',
          'Hashimoto\'s Thyroiditis',
          'Subacute Thyroiditis',
          'Postpartum Thyroiditis',
          'Benign Thyroid Nodule',
          'Suspicious Thyroid Nodule',
          'Papillary Thyroid Carcinoma',
          'Follicular Thyroid Carcinoma',
          'Medullary Thyroid Carcinoma',
          'Anaplastic Thyroid Carcinoma',
        ],
      ),
      DiseaseCategory(
        id: 'pituitary',
        name: 'Pituitary Gland',
        icon: Icons.psychology,
        diseases: [
          'Acromegaly',
          'Prolactinoma',
          'Cushing\'s Disease',
          'TSH-secreting Adenoma',
          'Hypopituitarism',
          'Diabetes Insipidus',
          'SIADH',
        ],
      ),
      DiseaseCategory(
        id: 'parathyroid',
        name: 'Parathyroid Glands',
        icon: Icons.healing,
        diseases: [
          'Primary Hyperparathyroidism',
          'Secondary Hyperparathyroidism',
          'Tertiary Hyperparathyroidism',
          'Hypoparathyroidism',
          'Pseudohypoparathyroidism',
        ],
      ),
      DiseaseCategory(
        id: 'adrenal',
        name: 'Adrenal Glands',
        icon: Icons.shield,
        diseases: [
          'Cushing\'s Syndrome',
          'Addison\'s Disease',
          'Primary Aldosteronism',
          'Pheochromocytoma',
          'Congenital Adrenal Hyperplasia',
        ],
      ),
      DiseaseCategory(
        id: 'pancreas',
        name: 'Pancreas (Endocrine)',
        icon: Icons.bloodtype,
        diseases: [
          'Type 1 Diabetes',
          'Type 2 Diabetes',
          'Gestational Diabetes',
          'MODY',
          'Insulinoma',
        ],
      ),
    ],
  );

  // 🫘 RENAL SYSTEM (Priority 1)
  static const renalSystem = MedicalSystemConfig(
    id: 'renal',
    name: 'Renal System',
    description: 'Kidneys, Filtration, Electrolytes',
    icon: Icons.water_drop,
    color: Color(0xFF3B82F6), // Blue
    categories: [
      DiseaseCategory(
        id: 'ckd',
        name: 'Chronic Kidney Disease',
        icon: Icons.trending_down,
        diseases: [
          'CKD Stage 1',
          'CKD Stage 2',
          'CKD Stage 3',
          'CKD Stage 4',
          'CKD Stage 5 (ESRD)',
          'Diabetic Nephropathy',
          'Hypertensive Nephropathy',
        ],
      ),
      DiseaseCategory(
        id: 'aki',
        name: 'Acute Kidney Injury',
        icon: Icons.warning,
        diseases: [
          'Pre-renal AKI',
          'Intrinsic AKI',
          'Post-renal AKI',
          'Acute Tubular Necrosis',
        ],
      ),
      DiseaseCategory(
        id: 'glomerular',
        name: 'Glomerular Diseases',
        icon: Icons.filter_alt,
        diseases: [
          'IgA Nephropathy',
          'Focal Segmental Glomerulosclerosis',
          'Minimal Change Disease',
          'Membranous Nephropathy',
          'Rapidly Progressive GN',
        ],
      ),
      DiseaseCategory(
        id: 'stones',
        name: 'Nephrolithiasis',
        icon: Icons.circle,
        diseases: [
          'Calcium Oxalate Stones',
          'Uric Acid Stones',
          'Struvite Stones',
          'Cystine Stones',
        ],
      ),
      DiseaseCategory(
        id: 'infections',
        name: 'Renal Infections',
        icon: Icons.coronavirus,
        diseases: [
          'Acute Pyelonephritis',
          'Chronic Pyelonephritis',
          'Renal Abscess',
        ],
      ),
    ],
  );

  // 🫀 GENITOURINARY SYSTEM (Priority 2)
  static const genitourinarySystem = MedicalSystemConfig(
    id: 'genitourinary',
    name: 'Genitourinary System',
    description: 'Bladder, Prostate, Male Reproductive',
    icon: Icons.personal_injury,
    color: Color(0xFF8B5CF6), // Purple
    categories: [
      DiseaseCategory(
        id: 'lower_uti',
        name: 'Lower Urinary Tract',
        icon: Icons.bubble_chart,
        diseases: [
          'Acute Cystitis',
          'Recurrent UTI',
          'Interstitial Cystitis',
          'Overactive Bladder',
          'Urinary Incontinence',
        ],
      ),
      DiseaseCategory(
        id: 'prostate',
        name: 'Prostate Disorders',
        icon: Icons.man,
        diseases: [
          'Benign Prostatic Hyperplasia',
          'Acute Prostatitis',
          'Chronic Prostatitis',
          'Prostate Cancer',
        ],
      ),
      DiseaseCategory(
        id: 'male_reproductive',
        name: 'Male Reproductive',
        icon: Icons.male,
        diseases: [
          'Erectile Dysfunction',
          'Male Hypogonadism',
          'Varicocele',
          'Epididymitis',
          'Testicular Torsion',
        ],
      ),
    ],
  );

  // 🩷 GYNAECOLOGY SYSTEM
  static const gynaecologySystem = MedicalSystemConfig(
    id: 'gynaecology',
    name: 'Gynaecology',
    description: 'Female Reproductive, Menstrual, Oncology',
    icon: Icons.female,
    color: Color(0xFFEC4899), // Pink
    categories: [
      DiseaseCategory(
        id: 'gynaecology',
        name: 'Gynaecology',
        icon: Icons.female,
        diseases: [
          'PCOS',
          'Endometriosis',
          'Uterine Fibroids',
          'Pelvic Inflammatory Disease',
          'Ovarian Cysts',
          'Cervical Dysplasia',
          'Adenomyosis',
          'Menopause',
        ],
      ),
      DiseaseCategory(
        id: 'menstrual',
        name: 'Menstrual Disorders',
        icon: Icons.calendar_month,
        diseases: [
          'Dysmenorrhoea',
          'Amenorrhoea',
          'Menorrhagia',
          'Oligomenorrhoea',
          'Premenstrual Syndrome',
        ],
      ),
      DiseaseCategory(
        id: 'fertility',
        name: 'Fertility & Contraception',
        icon: Icons.favorite,
        diseases: [
          'Female Infertility',
          'Recurrent Pregnancy Loss',
          'Contraception Counselling',
          'IVF Management',
        ],
      ),
      DiseaseCategory(
        id: 'gyn_oncology',
        name: 'Gynaecological Oncology',
        icon: Icons.warning,
        diseases: [
          'Cervical Cancer',
          'Ovarian Cancer',
          'Endometrial Cancer',
          'Vulvar Cancer',
          'Gestational Trophoblastic Disease',
        ],
      ),
    ],
  );

  // 🤰 OBSTETRICS SYSTEM
  static const obstetricsSystem = MedicalSystemConfig(
    id: 'obstetrics',
    name: 'Obstetrics',
    description: 'Pregnancy, Labour, Antenatal Care',
    icon: Icons.pregnant_woman,
    color: Color(0xFFA855F7), // Purple
    categories: [
      DiseaseCategory(
        id: 'antenatal',
        name: 'Antenatal Conditions',
        icon: Icons.child_friendly,
        diseases: [
          'Normal Pregnancy',
          'Gestational Diabetes',
          'Pre-eclampsia',
          'Eclampsia',
          'HELLP Syndrome',
          'Hyperemesis Gravidarum',
          'Gestational Hypertension',
          'Rh Incompatibility',
        ],
      ),
      DiseaseCategory(
        id: 'complications',
        name: 'Pregnancy Complications',
        icon: Icons.warning,
        diseases: [
          'Ectopic Pregnancy',
          'Placenta Previa',
          'Placental Abruption',
          'Miscarriage',
          'Preterm Labour',
          'Premature Rupture of Membranes',
          'Intrauterine Growth Restriction',
          'Molar Pregnancy',
        ],
      ),
      DiseaseCategory(
        id: 'labour',
        name: 'Labour & Delivery',
        icon: Icons.local_hospital,
        diseases: [
          'Normal Labour',
          'Prolonged Labour',
          'Obstructed Labour',
          'Cord Prolapse',
          'Shoulder Dystocia',
          'Postpartum Haemorrhage',
          'Caesarean Section',
        ],
      ),
      DiseaseCategory(
        id: 'postnatal',
        name: 'Postnatal',
        icon: Icons.healing,
        diseases: [
          'Postpartum Depression',
          'Puerperal Sepsis',
          'Lactation Disorders',
          'Deep Vein Thrombosis',
        ],
      ),
    ],
  );

  // 🫁 HEPATOBILIARY SYSTEM (Priority 3)
  static const hepatobiliarySystem = MedicalSystemConfig(
    id: 'hepatobiliary',
    name: 'Hepatobiliary System',
    description: 'Liver, Gallbladder, Bile Ducts',
    icon: Icons.local_hospital,
    color: Color(0xFFF59E0B), // Orange
    categories: [
      DiseaseCategory(
        id: 'hepatitis',
        name: 'Hepatitis',
        icon: Icons.coronavirus,
        diseases: [
          'Hepatitis A',
          'Hepatitis B',
          'Hepatitis C',
          'Alcoholic Hepatitis',
          'Autoimmune Hepatitis',
        ],
      ),
      DiseaseCategory(
        id: 'cirrhosis',
        name: 'Cirrhosis & Fibrosis',
        icon: Icons.dangerous,
        diseases: [
          'Alcoholic Cirrhosis',
          'NASH Cirrhosis',
          'Hepatitis C Cirrhosis',
          'Primary Biliary Cholangitis',
          'Decompensated Cirrhosis',
        ],
      ),
      DiseaseCategory(
        id: 'fatty_liver',
        name: 'Fatty Liver Disease',
        icon: Icons.warning,
        diseases: [
          'Non-alcoholic Fatty Liver',
          'NASH',
          'Alcoholic Fatty Liver',
        ],
      ),
      DiseaseCategory(
        id: 'gallbladder',
        name: 'Gallbladder & Biliary',
        icon: Icons.circle,
        diseases: [
          'Cholelithiasis',
          'Acute Cholecystitis',
          'Chronic Cholecystitis',
          'Choledocholithiasis',
          'Cholangitis',
        ],
      ),
      DiseaseCategory(
        id: 'liver_tumors',
        name: 'Liver Tumors',
        icon: Icons.warning_amber,
        diseases: [
          'Hepatocellular Carcinoma',
          'Liver Metastases',
          'Hepatic Adenoma',
          'Hemangioma',
        ],
      ),
    ],
  );

  // ❤️ CARDIOVASCULAR SYSTEM
  static const cardiovascularSystem = MedicalSystemConfig(
    id: 'cardiovascular',
    name: 'Cardiovascular System',
    description: 'Heart, Vessels, Blood Pressure',
    icon: Icons.favorite,
    color: Color(0xFFEF4444), // Red
    categories: [
      DiseaseCategory(
        id: 'hypertension',
        name: 'Hypertension',
        icon: Icons.trending_up,
        diseases: [
          'Essential Hypertension',
          'Secondary Hypertension',
          'Hypertensive Crisis',
          'Resistant Hypertension',
        ],
      ),
      DiseaseCategory(
        id: 'cad',
        name: 'Coronary Artery Disease',
        icon: Icons.favorite_border,
        diseases: [
          'Stable Angina',
          'Unstable Angina',
          'STEMI',
          'NSTEMI',
          'Chronic CAD',
        ],
      ),
      DiseaseCategory(
        id: 'heart_failure',
        name: 'Heart Failure',
        icon: Icons.heart_broken,
        diseases: [
          'HFrEF',
          'HFpEF',
          'Acute Decompensated HF',
          'Right Heart Failure',
        ],
      ),
      DiseaseCategory(
        id: 'arrhythmias',
        name: 'Arrhythmias',
        icon: Icons.show_chart,
        diseases: [
          'Atrial Fibrillation',
          'Atrial Flutter',
          'SVT',
          'Ventricular Tachycardia',
        ],
      ),
    ],
  );

  // 🫁 RESPIRATORY SYSTEM
  static const respiratorySystem = MedicalSystemConfig(
    id: 'respiratory',
    name: 'Respiratory System',
    description: 'Lungs, Airways, Breathing',
    icon: Icons.air,
    color: Color(0xFF10B981), // Green
    categories: [
      DiseaseCategory(
        id: 'copd',
        name: 'COPD & Chronic Conditions',
        icon: Icons.wind_power,
        diseases: [
          'Chronic Bronchitis',
          'Emphysema',
          'COPD',
          'Bronchiectasis',
        ],
      ),
      DiseaseCategory(
        id: 'asthma',
        name: 'Asthma',
        icon: Icons.waves,
        diseases: [
          'Allergic Asthma',
          'Exercise-Induced Asthma',
          'Severe Asthma',
        ],
      ),
      DiseaseCategory(
        id: 'infections',
        name: 'Respiratory Infections',
        icon: Icons.coronavirus,
        diseases: [
          'Community-Acquired Pneumonia',
          'Hospital-Acquired Pneumonia',
          'Tuberculosis',
          'Acute Bronchitis',
        ],
      ),
    ],
  );

  // 🧠 NEUROLOGICAL SYSTEM
  static const neurologicalSystem = MedicalSystemConfig(
    id: 'neurological',
    name: 'Neurological System',
    description: 'Brain, Nerves, CNS',
    icon: Icons.psychology,
    color: Color(0xFF6366F1), // Indigo
    categories: [
      DiseaseCategory(
        id: 'stroke',
        name: 'Cerebrovascular',
        icon: Icons.emergency,
        diseases: [
          'Ischemic Stroke',
          'Hemorrhagic Stroke',
          'TIA',
        ],
      ),
      DiseaseCategory(
        id: 'seizures',
        name: 'Epilepsy & Seizures',
        icon: Icons.flash_on,
        diseases: [
          'Generalized Epilepsy',
          'Focal Epilepsy',
          'Status Epilepticus',
        ],
      ),
      DiseaseCategory(
        id: 'headache',
        name: 'Headache Disorders',
        icon: Icons.mood_bad,
        diseases: [
          'Migraine',
          'Tension Headache',
          'Cluster Headache',
        ],
      ),
    ],
  );

  // 🦴 MUSCULOSKELETAL SYSTEM
  static const musculoskeletalSystem = MedicalSystemConfig(
    id: 'musculoskeletal',
    name: 'Musculoskeletal System',
    description: 'Bones, Joints, Muscles',
    icon: Icons.accessibility_new,
    color: Color(0xFFA855F7), // Purple
    categories: [
      DiseaseCategory(
        id: 'arthritis',
        name: 'Arthritis',
        icon: Icons.accessible,
        diseases: [
          'Osteoarthritis',
          'Rheumatoid Arthritis',
          'Gout',
          'Psoriatic Arthritis',
        ],
      ),
      DiseaseCategory(
        id: 'bone',
        name: 'Bone Disorders',
        icon: Icons.height,
        diseases: [
          'Osteoporosis',
          'Osteomalacia',
          'Paget\'s Disease',
        ],
      ),
    ],
  );

  // All Systems List
  static final List<MedicalSystemConfig> allSystems = [
    endocrineSystem,
    renalSystem,
    genitourinarySystem,
    gynaecologySystem,
    obstetricsSystem,
    hepatobiliarySystem,
    cardiovascularSystem,
    respiratorySystem,
    neurologicalSystem,
    musculoskeletalSystem,
  ];
}