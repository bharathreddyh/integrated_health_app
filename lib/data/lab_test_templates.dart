// lib/data/lab_test_templates.dart

import '../models/lab_test.dart';

class LabTestTemplate {
  final String name;
  final LabTestCategory category;
  final String unit;
  final String? normalRangeMin;
  final String? normalRangeMax;
  final String description;

  const LabTestTemplate({
    required this.name,
    required this.category,
    required this.unit,
    this.normalRangeMin,
    this.normalRangeMax,
    required this.description,
  });
}

class LabTestTemplates {
  // HEMATOLOGY
  static const List<LabTestTemplate> hematology = [
    LabTestTemplate(
      name: 'Hemoglobin',
      category: LabTestCategory.hematology,
      unit: 'g/dL',
      normalRangeMin: '12.0',
      normalRangeMax: '16.0',
      description: 'Red blood cell oxygen carrier',
    ),
    LabTestTemplate(
      name: 'WBC Count',
      category: LabTestCategory.hematology,
      unit: 'cells/μL',
      normalRangeMin: '4000',
      normalRangeMax: '11000',
      description: 'White blood cell count',
    ),
    LabTestTemplate(
      name: 'Platelet Count',
      category: LabTestCategory.hematology,
      unit: 'cells/μL',
      normalRangeMin: '150000',
      normalRangeMax: '400000',
      description: 'Blood clotting cells',
    ),
    LabTestTemplate(
      name: 'ESR',
      category: LabTestCategory.hematology,
      unit: 'mm/hr',
      normalRangeMin: '0',
      normalRangeMax: '20',
      description: 'Erythrocyte sedimentation rate',
    ),
  ];

  // BIOCHEMISTRY
  static const List<LabTestTemplate> biochemistry = [
    LabTestTemplate(
      name: 'Fasting Blood Sugar',
      category: LabTestCategory.biochemistry,
      unit: 'mg/dL',
      normalRangeMin: '70',
      normalRangeMax: '100',
      description: 'Blood glucose after 8hr fast',
    ),
    LabTestTemplate(
      name: 'HbA1c',
      category: LabTestCategory.biochemistry,
      unit: '%',
      normalRangeMin: '4.0',
      normalRangeMax: '5.6',
      description: 'Average blood sugar over 3 months',
    ),
    LabTestTemplate(
      name: 'Creatinine',
      category: LabTestCategory.biochemistry,
      unit: 'mg/dL',
      normalRangeMin: '0.6',
      normalRangeMax: '1.2',
      description: 'Kidney function marker',
    ),
    LabTestTemplate(
      name: 'Blood Urea Nitrogen',
      category: LabTestCategory.biochemistry,
      unit: 'mg/dL',
      normalRangeMin: '7',
      normalRangeMax: '20',
      description: 'Kidney function marker',
    ),
    LabTestTemplate(
      name: 'Total Cholesterol',
      category: LabTestCategory.biochemistry,
      unit: 'mg/dL',
      normalRangeMin: '0',
      normalRangeMax: '200',
      description: 'Total blood cholesterol',
    ),
    LabTestTemplate(
      name: 'LDL Cholesterol',
      category: LabTestCategory.biochemistry,
      unit: 'mg/dL',
      normalRangeMin: '0',
      normalRangeMax: '100',
      description: 'Bad cholesterol',
    ),
    LabTestTemplate(
      name: 'HDL Cholesterol',
      category: LabTestCategory.biochemistry,
      unit: 'mg/dL',
      normalRangeMin: '40',
      normalRangeMax: null,
      description: 'Good cholesterol',
    ),
    LabTestTemplate(
      name: 'Triglycerides',
      category: LabTestCategory.biochemistry,
      unit: 'mg/dL',
      normalRangeMin: '0',
      normalRangeMax: '150',
      description: 'Blood fats',
    ),
    LabTestTemplate(
      name: 'ALT (SGPT)',
      category: LabTestCategory.biochemistry,
      unit: 'U/L',
      normalRangeMin: '7',
      normalRangeMax: '56',
      description: 'Liver enzyme',
    ),
    LabTestTemplate(
      name: 'AST (SGOT)',
      category: LabTestCategory.biochemistry,
      unit: 'U/L',
      normalRangeMin: '10',
      normalRangeMax: '40',
      description: 'Liver enzyme',
    ),
    LabTestTemplate(
      name: 'Bilirubin Total',
      category: LabTestCategory.biochemistry,
      unit: 'mg/dL',
      normalRangeMin: '0.1',
      normalRangeMax: '1.2',
      description: 'Liver function marker',
    ),
    LabTestTemplate(
      name: 'Albumin',
      category: LabTestCategory.biochemistry,
      unit: 'g/dL',
      normalRangeMin: '3.5',
      normalRangeMax: '5.5',
      description: 'Protein produced by liver',
    ),
    LabTestTemplate(
      name: 'Uric Acid',
      category: LabTestCategory.biochemistry,
      unit: 'mg/dL',
      normalRangeMin: '3.5',
      normalRangeMax: '7.2',
      description: 'Gout marker',
    ),
  ];

  // IMMUNOLOGY
  static const List<LabTestTemplate> immunology = [
    LabTestTemplate(
      name: 'TSH',
      category: LabTestCategory.immunology,
      unit: 'mIU/L',
      normalRangeMin: '0.4',
      normalRangeMax: '4.0',
      description: 'Thyroid stimulating hormone',
    ),
    LabTestTemplate(
      name: 'T3',
      category: LabTestCategory.immunology,
      unit: 'ng/dL',
      normalRangeMin: '80',
      normalRangeMax: '200',
      description: 'Thyroid hormone',
    ),
    LabTestTemplate(
      name: 'T4',
      category: LabTestCategory.immunology,
      unit: 'μg/dL',
      normalRangeMin: '5.0',
      normalRangeMax: '12.0',
      description: 'Thyroid hormone',
    ),
    LabTestTemplate(
      name: 'Vitamin D',
      category: LabTestCategory.immunology,
      unit: 'ng/mL',
      normalRangeMin: '30',
      normalRangeMax: '100',
      description: 'Vitamin D levels',
    ),
    LabTestTemplate(
      name: 'Vitamin B12',
      category: LabTestCategory.immunology,
      unit: 'pg/mL',
      normalRangeMin: '200',
      normalRangeMax: '900',
      description: 'Vitamin B12 levels',
    ),
  ];

  // MICROBIOLOGY
  static const List<LabTestTemplate> microbiology = [
    LabTestTemplate(
      name: 'Urine Culture',
      category: LabTestCategory.microbiology,
      unit: 'CFU/mL',
      normalRangeMin: null,
      normalRangeMax: '10000',
      description: 'Bacterial infection test',
    ),
    LabTestTemplate(
      name: 'Blood Culture',
      category: LabTestCategory.microbiology,
      unit: '',
      normalRangeMin: null,
      normalRangeMax: null,
      description: 'Bloodstream infection test',
    ),
  ];

  // Get all templates grouped by category
  static Map<LabTestCategory, List<LabTestTemplate>> get allTemplates => {
    LabTestCategory.hematology: hematology,
    LabTestCategory.biochemistry: biochemistry,
    LabTestCategory.immunology: immunology,
    LabTestCategory.microbiology: microbiology,
  };

  // Get all templates as flat list
  static List<LabTestTemplate> get flatList => [
    ...hematology,
    ...biochemistry,
    ...immunology,
    ...microbiology,
  ];

  // Search templates
  static List<LabTestTemplate> search(String query) {
    final lowerQuery = query.toLowerCase();
    return flatList.where((template) =>
    template.name.toLowerCase().contains(lowerQuery) ||
        template.description.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}