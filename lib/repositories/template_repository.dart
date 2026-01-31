// lib/repositories/template_repository.dart
// Repository of pre-configured disease templates with auto-suggestion rules

import '../models/enhanced_disease_template.dart';

class TemplateRepository {
  static final TemplateRepository instance = TemplateRepository._();

  TemplateRepository._();

  /// Get all available templates
  List<EnhancedDiseaseTemplate> getAllTemplates() {
    return [
      _createDiabetesTemplate(),
      _createHypertensionTemplate(),
      _createThyroidTemplate(),
      _createCKDTemplate(),
      _createAsthmaTemplate(),
    ];
  }

  /// Get template by ID
  EnhancedDiseaseTemplate? getTemplateById(String id) {
    return getAllTemplates().where((t) => t.id == id).firstOrNull;
  }

  /// Get templates by category
  List<EnhancedDiseaseTemplate> getTemplatesByCategory(String category) {
    return getAllTemplates().where((t) => t.category == category).toList();
  }

  // ============================================================================
  // DIABETES MELLITUS TEMPLATE
  // ============================================================================

  EnhancedDiseaseTemplate _createDiabetesTemplate() {
    return EnhancedDiseaseTemplate(
      id: 'dm_type2_v1',
      name: 'Type 2 Diabetes Mellitus',
      category: 'Endocrine',
      description: 'Comprehensive management protocol for Type 2 Diabetes with evidence-based follow-up intervals and investigation schedules',

      followUpProtocol: FollowUpProtocol(
        defaultIntervalDays: 90, // Standard 3-month follow-up
        minIntervalDays: 14,
        maxIntervalDays: 180,
        adjustmentRules: [
          // New diagnosis: more frequent monitoring
          IntervalAdjustmentRule(
            condition: 'new_diagnosis',
            adjustmentDays: -60, // 1 month instead of 3
            rationale: 'New diagnosis requires more frequent monitoring for medication titration and patient education',
            conditionType: RuleConditionType.isInitialVisit,
          ),

          // Uncontrolled diabetes: shorter interval
          IntervalAdjustmentRule(
            condition: 'uncontrolled',
            adjustmentDays: -45, // 6 weeks instead of 3 months
            rationale: 'Uncontrolled diabetes requires more aggressive management and frequent monitoring',
            conditionType: RuleConditionType.customCondition,
          ),

          // High blood sugar: urgent follow-up
          IntervalAdjustmentRule(
            condition: 'hyperglycemia',
            adjustmentDays: -75, // 2 weeks
            rationale: 'Significantly elevated blood sugar requires prompt medication adjustment',
            conditionType: RuleConditionType.vitalOutOfRange,
            vitalParameter: 'fasting_blood_sugar',
            thresholdValue: 200.0,
            comparisonOperator: '>',
          ),

          // Well-controlled and stable: can extend slightly
          IntervalAdjustmentRule(
            condition: 'well_controlled',
            adjustmentDays: 30, // 4 months
            rationale: 'Well-controlled diabetes with stable medication allows for extended monitoring interval',
            conditionType: RuleConditionType.customCondition,
          ),
        ],
        defaultRationale: 'Standard 3-month follow-up as per ADA guidelines for routine diabetes monitoring',
        conditionalRationales: {
          'uncontrolled': 'More frequent monitoring needed due to suboptimal glycemic control',
          'well_controlled': 'Extended interval appropriate for stable, well-controlled diabetes',
        },
      ),

      investigationProtocols: [
        InvestigationProtocol(
          investigationName: 'HbA1c (Glycated Hemoglobin)',
          code: 'HBA1C',
          recommendedFrequencyDays: 90, // Every 3 months
          isMandatory: true,
          isUrgentIfOverdue: true,
          defaultRationale: 'HbA1c provides 3-month average blood sugar control and is essential for treatment adjustment',
          conditionalRationales: {
            'uncontrolled': 'Urgent HbA1c needed to assess recent control and guide therapy',
          },
          conditions: [
            InvestigationCondition(
              condition: 'uncontrolled',
              required: true,
            ),
          ],
        ),

        InvestigationProtocol(
          investigationName: 'Fasting Blood Sugar',
          code: 'FBS',
          recommendedFrequencyDays: 30, // Monthly
          isMandatory: false,
          isUrgentIfOverdue: false,
          defaultRationale: 'Regular monitoring of fasting glucose helps track day-to-day control',
        ),

        InvestigationProtocol(
          investigationName: 'Lipid Profile',
          code: 'LIPID',
          recommendedFrequencyDays: 180, // Every 6 months
          isMandatory: false,
          isUrgentIfOverdue: false,
          defaultRationale: 'Diabetes increases cardiovascular risk; lipid monitoring is essential',
        ),

        InvestigationProtocol(
          investigationName: 'Kidney Function (Creatinine, eGFR)',
          code: 'RFT',
          recommendedFrequencyDays: 180, // Every 6 months
          isMandatory: false,
          isUrgentIfOverdue: true,
          defaultRationale: 'Diabetes is leading cause of kidney disease; regular monitoring essential',
        ),

        InvestigationProtocol(
          investigationName: 'Urine Albumin-Creatinine Ratio (UACR)',
          code: 'UACR',
          recommendedFrequencyDays: 365, // Annually
          isMandatory: false,
          isUrgentIfOverdue: false,
          defaultRationale: 'Annual screening for diabetic nephropathy as per guidelines',
        ),

        InvestigationProtocol(
          investigationName: 'Retinal Screening (Fundoscopy)',
          code: 'FUNDOSCOPY',
          recommendedFrequencyDays: 365, // Annually
          isMandatory: false,
          isUrgentIfOverdue: false,
          defaultRationale: 'Annual screening for diabetic retinopathy to prevent vision loss',
        ),
      ],

      criticalCheckpoints: [
        'Signs of hypoglycemia (dizziness, sweating, confusion)',
        'Symptoms of diabetic ketoacidosis (nausea, vomiting, fruity breath)',
        'Foot ulcers or infections',
        'Sudden vision changes',
        'Chest pain or severe shortness of breath',
      ],

      protocolGuidelines: {
        'Target HbA1c': '<7.0%',
        'Target FBS': '80-130 mg/dL',
        'Target BP': '<140/90 mmHg',
        'Target LDL': '<100 mg/dL',
      },

      commonMedications: [
        'Metformin',
        'Glimepiride',
        'Sitagliptin',
        'Insulin (if required)',
        'Statin for cholesterol',
        'ACE inhibitor for kidney protection',
      ],

      lifestyleAdvice: [
        'Follow diabetic diet plan (limit refined carbs, sugar)',
        'Exercise 150 minutes per week (brisk walking, cycling)',
        'Monitor blood sugar at home regularly',
        'Maintain healthy weight (target BMI < 25)',
        'Avoid tobacco and limit alcohol',
        'Practice good foot hygiene and inspect feet daily',
      ],

      followUpPlanTemplate: '''
DIAGNOSIS: Type 2 Diabetes Mellitus - {control_status}

CURRENT STATUS:
• HbA1c: {hba1c}% (Target: <7.0%)
• Fasting Blood Sugar: {fasting_blood_sugar} mg/dL
• Overall control: {control_status}

TREATMENT PLAN:
Continue current diabetes management regimen with regular blood sugar monitoring.

FOLLOW-UP:
Next visit scheduled for comprehensive diabetes review and medication adjustment if needed.
''',

      aiEnabled: true,
      customPromptTemplate: null,

      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'system',
    );
  }

  // ============================================================================
  // HYPERTENSION TEMPLATE
  // ============================================================================

  EnhancedDiseaseTemplate _createHypertensionTemplate() {
    return EnhancedDiseaseTemplate(
      id: 'htn_essential_v1',
      name: 'Essential Hypertension',
      category: 'Cardiovascular',
      description: 'Evidence-based protocol for essential hypertension management',

      followUpProtocol: FollowUpProtocol(
        defaultIntervalDays: 60, // 2 months for stable HTN
        minIntervalDays: 7,
        maxIntervalDays: 90,
        adjustmentRules: [
          IntervalAdjustmentRule(
            condition: 'new_diagnosis',
            adjustmentDays: -45, // 2 weeks
            rationale: 'New hypertension diagnosis requires close monitoring for medication titration',
            conditionType: RuleConditionType.isInitialVisit,
          ),

          IntervalAdjustmentRule(
            condition: 'uncontrolled_bp',
            adjustmentDays: -45, // 2 weeks
            rationale: 'Uncontrolled BP requires prompt medication adjustment',
            conditionType: RuleConditionType.vitalOutOfRange,
            vitalParameter: 'systolic_bp',
            thresholdValue: 140.0,
            comparisonOperator: '>',
          ),

          IntervalAdjustmentRule(
            condition: 'well_controlled',
            adjustmentDays: 30, // 3 months
            rationale: 'Well-controlled BP allows for extended monitoring',
            conditionType: RuleConditionType.customCondition,
          ),
        ],
        defaultRationale: 'Standard 2-month follow-up for established hypertension',
      ),

      investigationProtocols: [
        InvestigationProtocol(
          investigationName: 'ECG (Electrocardiogram)',
          code: 'ECG',
          recommendedFrequencyDays: 365, // Annually
          isMandatory: false,
          defaultRationale: 'Annual ECG to screen for cardiac complications of hypertension',
        ),

        InvestigationProtocol(
          investigationName: 'Kidney Function Test',
          code: 'RFT',
          recommendedFrequencyDays: 180, // Every 6 months
          isMandatory: false,
          isUrgentIfOverdue: true,
          defaultRationale: 'Monitor kidney function as hypertension can cause kidney damage',
        ),

        InvestigationProtocol(
          investigationName: 'Lipid Profile',
          code: 'LIPID',
          recommendedFrequencyDays: 180,
          isMandatory: false,
          defaultRationale: 'Assess cardiovascular risk factors',
        ),

        InvestigationProtocol(
          investigationName: 'Urine Routine',
          code: 'URINE',
          recommendedFrequencyDays: 180,
          isMandatory: false,
          defaultRationale: 'Screen for proteinuria and kidney involvement',
        ),
      ],

      criticalCheckpoints: [
        'Severe headache or dizziness',
        'Chest pain or tightness',
        'Shortness of breath',
        'Visual disturbances',
        'Severe nosebleeds',
        'BP > 180/120 mmHg',
      ],

      protocolGuidelines: {
        'Target BP': '<140/90 mmHg',
        'Target (Diabetes)': '<130/80 mmHg',
        'Lifestyle': 'DASH diet, exercise',
      },

      commonMedications: [
        'Amlodipine',
        'Telmisartan',
        'Metoprolol',
        'Hydrochlorothiazide',
      ],

      lifestyleAdvice: [
        'Reduce salt intake (<5g/day)',
        'DASH diet: fruits, vegetables, whole grains',
        'Regular exercise (30 min/day)',
        'Maintain healthy weight',
        'Limit alcohol',
        'Manage stress',
        'Monitor BP at home',
      ],

      followUpPlanTemplate: '''
DIAGNOSIS: Essential Hypertension - {control_status}

BLOOD PRESSURE:
• Current: {systolic_bp}/{diastolic_bp} mmHg
• Target: <140/90 mmHg
• Control status: {control_status}

MANAGEMENT:
Continue antihypertensive medication with lifestyle modifications.

MONITORING:
Regular home BP monitoring recommended.
''',

      aiEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'system',
    );
  }

  // ============================================================================
  // HYPOTHYROIDISM TEMPLATE
  // ============================================================================

  EnhancedDiseaseTemplate _createThyroidTemplate() {
    return EnhancedDiseaseTemplate(
      id: 'thyroid_hypo_v1',
      name: 'Hypothyroidism',
      category: 'Endocrine',
      description: 'Management protocol for primary hypothyroidism',

      followUpProtocol: FollowUpProtocol(
        defaultIntervalDays: 90, // 3 months for stable thyroid
        minIntervalDays: 30,
        maxIntervalDays: 180,
        adjustmentRules: [
          IntervalAdjustmentRule(
            condition: 'new_diagnosis',
            adjustmentDays: -45, // 6 weeks
            rationale: 'New diagnosis requires dose titration',
            conditionType: RuleConditionType.isInitialVisit,
          ),

          IntervalAdjustmentRule(
            condition: 'medication_change',
            adjustmentDays: -45,
            rationale: 'Recent medication change requires monitoring',
            conditionType: RuleConditionType.customCondition,
          ),
        ],
        defaultRationale: 'Standard 3-month follow-up for stable hypothyroidism',
      ),

      investigationProtocols: [
        InvestigationProtocol(
          investigationName: 'TSH (Thyroid Stimulating Hormone)',
          code: 'TSH',
          recommendedFrequencyDays: 90,
          isMandatory: true,
          isUrgentIfOverdue: true,
          defaultRationale: 'TSH is the primary marker for thyroid function and medication adjustment',
        ),

        InvestigationProtocol(
          investigationName: 'Free T4',
          code: 'FT4',
          recommendedFrequencyDays: 180,
          isMandatory: false,
          defaultRationale: 'Complementary test for comprehensive thyroid assessment',
        ),
      ],

      criticalCheckpoints: [
        'Severe fatigue or weakness',
        'Chest pain or palpitations',
        'Significant weight changes',
        'Severe mood changes or depression',
      ],

      protocolGuidelines: {
        'Target TSH': '0.5-5.0 mIU/L',
        'Optimal TSH': '1.0-2.5 mIU/L',
      },

      commonMedications: [
        'Levothyroxine (Thyroxine)',
      ],

      lifestyleAdvice: [
        'Take medication on empty stomach (30 min before breakfast)',
        'Consistent timing of medication',
        'Avoid calcium/iron supplements within 4 hours of thyroid medication',
        'Regular exercise to combat fatigue',
        'Balanced, nutrient-rich diet',
      ],

      followUpPlanTemplate: '''
DIAGNOSIS: Primary Hypothyroidism - {control_status}

THYROID STATUS:
• TSH: {tsh} mIU/L (Target: 0.5-5.0)
• Current dose: Taking as prescribed

TREATMENT:
Continue levothyroxine with regular monitoring.
''',

      aiEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'system',
    );
  }

  // ============================================================================
  // CHRONIC KIDNEY DISEASE TEMPLATE
  // ============================================================================

  EnhancedDiseaseTemplate _createCKDTemplate() {
    return EnhancedDiseaseTemplate(
      id: 'ckd_stage3_v1',
      name: 'Chronic Kidney Disease (Stage 3)',
      category: 'Nephrology',
      description: 'Management protocol for CKD Stage 3',

      followUpProtocol: FollowUpProtocol(
        defaultIntervalDays: 90,
        minIntervalDays: 30,
        maxIntervalDays: 180,
        adjustmentRules: [
          IntervalAdjustmentRule(
            condition: 'declining_function',
            adjustmentDays: -60,
            rationale: 'Declining kidney function requires closer monitoring',
            conditionType: RuleConditionType.customCondition,
          ),
        ],
        defaultRationale: 'Regular monitoring of kidney function per CKD guidelines',
      ),

      investigationProtocols: [
        InvestigationProtocol(
          investigationName: 'Serum Creatinine & eGFR',
          code: 'CREAT',
          recommendedFrequencyDays: 90,
          isMandatory: true,
          isUrgentIfOverdue: true,
          defaultRationale: 'Essential for monitoring kidney function progression',
        ),

        InvestigationProtocol(
          investigationName: 'Urine Albumin-Creatinine Ratio',
          code: 'UACR',
          recommendedFrequencyDays: 180,
          isMandatory: true,
          defaultRationale: 'Monitor proteinuria as marker of kidney damage',
        ),

        InvestigationProtocol(
          investigationName: 'Electrolytes (Na, K)',
          code: 'ELECTROLYTES',
          recommendedFrequencyDays: 90,
          isMandatory: true,
          defaultRationale: 'Monitor for electrolyte imbalances',
        ),

        InvestigationProtocol(
          investigationName: 'Hemoglobin',
          code: 'HB',
          recommendedFrequencyDays: 90,
          isMandatory: false,
          defaultRationale: 'Screen for anemia of chronic kidney disease',
        ),
      ],

      criticalCheckpoints: [
        'Severe swelling (face, legs, abdomen)',
        'Significant decrease in urine output',
        'Severe nausea or vomiting',
        'Confusion or altered mental status',
        'Chest pain or severe shortness of breath',
      ],

      protocolGuidelines: {
        'Target eGFR': 'Slow decline',
        'Target BP': '<130/80 mmHg',
        'Protein intake': '0.8 g/kg/day',
      },

      commonMedications: [
        'ACE inhibitor/ARB',
        'Diuretics if needed',
        'Phosphate binders',
        'Erythropoietin if anemic',
      ],

      lifestyleAdvice: [
        'Limit protein intake as advised',
        'Control blood pressure strictly',
        'Manage diabetes if present',
        'Avoid NSAIDs (ibuprofen, etc.)',
        'Stay well hydrated',
        'Limit salt and potassium if advised',
      ],

      followUpPlanTemplate: '''
DIAGNOSIS: Chronic Kidney Disease Stage 3

KIDNEY FUNCTION:
• eGFR: {egfr} mL/min/1.73m²
• Status: Stable function, ongoing monitoring

MANAGEMENT:
Nephroprotective therapy with lifestyle modifications.
''',

      aiEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'system',
    );
  }

  // ============================================================================
  // ASTHMA TEMPLATE
  // ============================================================================

  EnhancedDiseaseTemplate _createAsthmaTemplate() {
    return EnhancedDiseaseTemplate(
      id: 'asthma_persistent_v1',
      name: 'Persistent Asthma',
      category: 'Respiratory',
      description: 'Management protocol for persistent asthma',

      followUpProtocol: FollowUpProtocol(
        defaultIntervalDays: 90,
        minIntervalDays: 14,
        maxIntervalDays: 180,
        adjustmentRules: [
          IntervalAdjustmentRule(
            condition: 'uncontrolled',
            adjustmentDays: -60,
            rationale: 'Uncontrolled asthma requires medication adjustment',
            conditionType: RuleConditionType.customCondition,
          ),

          IntervalAdjustmentRule(
            condition: 'exacerbation',
            adjustmentDays: -75,
            rationale: 'Recent exacerbation requires close follow-up',
            conditionType: RuleConditionType.customCondition,
          ),
        ],
        defaultRationale: 'Regular asthma control assessment',
      ),

      investigationProtocols: [
        InvestigationProtocol(
          investigationName: 'Spirometry (PFT)',
          code: 'PFT',
          recommendedFrequencyDays: 180,
          isMandatory: false,
          defaultRationale: 'Objective measurement of lung function',
        ),

        InvestigationProtocol(
          investigationName: 'Peak Flow Measurement',
          code: 'PEAK_FLOW',
          recommendedFrequencyDays: 90,
          isMandatory: false,
          defaultRationale: 'Monitor airway function',
        ),
      ],

      criticalCheckpoints: [
        'Severe breathlessness at rest',
        'Unable to speak full sentences',
        'Blue lips or fingernails',
        'Peak flow <50% of personal best',
        'No improvement with rescue inhaler',
      ],

      protocolGuidelines: {
        'ACT Score': 'Target >20',
        'Peak Flow': '>80% personal best',
        'Exacerbations': '<2 per year',
      },

      commonMedications: [
        'ICS (Inhaled Corticosteroid)',
        'LABA (if needed)',
        'SABA (rescue inhaler)',
        'Leukotriene modifier',
      ],

      lifestyleAdvice: [
        'Avoid triggers (smoke, dust, allergens)',
        'Use inhaler technique correctly',
        'Monitor peak flow at home',
        'Keep rescue inhaler accessible',
        'Regular exercise as tolerated',
        'Annual flu vaccination',
      ],

      followUpPlanTemplate: '''
DIAGNOSIS: Persistent Asthma - {control_status}

ASTHMA CONTROL:
• Symptoms: {control_status}
• Rescue inhaler use: As needed
• Exacerbations: Monitoring

MANAGEMENT:
Continue controller medication with trigger avoidance.
''',

      aiEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'system',
    );
  }
}