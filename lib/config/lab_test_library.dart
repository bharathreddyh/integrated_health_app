// ==================== LAB TEST LIBRARY ====================
// File: lib/config/lab_test_library.dart
//
// Comprehensive library of pre-defined lab tests with units and reference ranges
// Organized by category for easy selection in the UI
//
// Usage:
//   LabTestLibrary.categories -> List of all categories
//   LabTestLibrary.getTestsForCategory('Thyroid Function') -> List of test names
//   LabTestLibrary.getTestDetails('Thyroid Function', 'TSH') -> Test details

class LabTestLibrary {
  // ==================== MAIN TEST DATABASE ====================

  static const Map<String, List<Map<String, dynamic>>> testsByCategory = {

    // ==================== THYROID FUNCTION PANEL ====================
    'Thyroid Function': [
      {
        'name': 'TSH',
        'fullName': 'Thyroid Stimulating Hormone',
        'unit': 'mIU/L',
        'min': 0.4,
        'max': 4.0,
        'description': 'Primary test for thyroid function'
      },
      {
        'name': 'Free T3',
        'fullName': 'Free Triiodothyronine',
        'unit': 'pg/mL',
        'min': 2.0,
        'max': 4.4,
        'description': 'Active thyroid hormone'
      },
      {
        'name': 'Free T4',
        'fullName': 'Free Thyroxine',
        'unit': 'ng/dL',
        'min': 0.9,
        'max': 1.7,
        'description': 'Unbound thyroxine'
      },
      {
        'name': 'Total T3',
        'fullName': 'Total Triiodothyronine',
        'unit': 'ng/dL',
        'min': 80.0,
        'max': 200.0,
        'description': 'Total T3 including bound and free'
      },
      {
        'name': 'Total T4',
        'fullName': 'Total Thyroxine',
        'unit': 'μg/dL',
        'min': 5.0,
        'max': 12.0,
        'description': 'Total T4 including bound and free'
      },
      {
        'name': 'Reverse T3',
        'fullName': 'Reverse Triiodothyronine',
        'unit': 'ng/dL',
        'min': 9.2,
        'max': 24.1,
        'description': 'Inactive form of T3'
      },
      {
        'name': 'T3 Uptake',
        'fullName': 'T3 Resin Uptake',
        'unit': '%',
        'min': 24.0,
        'max': 39.0,
        'description': 'Measures thyroid binding proteins'
      },
    ],

    // ==================== THYROID ANTIBODIES ====================
    'Thyroid Antibodies': [
      {
        'name': 'Anti-TPO',
        'fullName': 'Anti-Thyroid Peroxidase Antibody',
        'unit': 'IU/mL',
        'min': 0.0,
        'max': 35.0,
        'description': 'Marker for autoimmune thyroid disease'
      },
      {
        'name': 'Anti-Thyroglobulin',
        'fullName': 'Anti-Thyroglobulin Antibody',
        'unit': 'IU/mL',
        'min': 0.0,
        'max': 115.0,
        'description': 'Present in Hashimoto\'s and Graves\' disease'
      },
      {
        'name': 'TSH Receptor Antibody (TRAb)',
        'fullName': 'TSH Receptor Antibody',
        'unit': 'IU/L',
        'min': 0.0,
        'max': 1.75,
        'description': 'Diagnostic for Graves\' disease'
      },
      {
        'name': 'TSI',
        'fullName': 'Thyroid Stimulating Immunoglobulin',
        'unit': '%',
        'min': 0.0,
        'max': 140.0,
        'description': 'Specific for Graves\' disease'
      },
    ],

    // ==================== TUMOR MARKERS ====================
    'Tumor Markers': [
      {
        'name': 'Thyroglobulin',
        'fullName': 'Thyroglobulin',
        'unit': 'ng/mL',
        'min': 1.4,
        'max': 78.0,
        'description': 'Tumor marker for thyroid cancer follow-up'
      },
      {
        'name': 'Calcitonin (Male)',
        'fullName': 'Calcitonin - Male',
        'unit': 'pg/mL',
        'min': 0.0,
        'max': 10.0,
        'description': 'Marker for medullary thyroid cancer'
      },
      {
        'name': 'Calcitonin (Female)',
        'fullName': 'Calcitonin - Female',
        'unit': 'pg/mL',
        'min': 0.0,
        'max': 5.0,
        'description': 'Marker for medullary thyroid cancer'
      },
      {
        'name': 'CEA',
        'fullName': 'Carcinoembryonic Antigen',
        'unit': 'ng/mL',
        'min': 0.0,
        'max': 3.0,
        'description': 'Non-specific tumor marker'
      },
    ],

    // ==================== METABOLIC PANEL ====================
    'Metabolic Panel': [
      {
        'name': 'Fasting Glucose',
        'fullName': 'Fasting Blood Glucose',
        'unit': 'mg/dL',
        'min': 70.0,
        'max': 100.0,
        'description': 'Blood sugar after 8-hour fast'
      },
      {
        'name': 'Random Glucose',
        'fullName': 'Random Blood Glucose',
        'unit': 'mg/dL',
        'min': 70.0,
        'max': 140.0,
        'description': 'Blood sugar at any time'
      },
      {
        'name': 'HbA1c',
        'fullName': 'Glycated Hemoglobin',
        'unit': '%',
        'min': 4.0,
        'max': 5.6,
        'description': '3-month average blood sugar'
      },
      {
        'name': 'Total Cholesterol',
        'fullName': 'Total Cholesterol',
        'unit': 'mg/dL',
        'min': 0.0,
        'max': 200.0,
        'description': 'Total blood cholesterol'
      },
      {
        'name': 'LDL',
        'fullName': 'Low Density Lipoprotein',
        'unit': 'mg/dL',
        'min': 0.0,
        'max': 100.0,
        'description': 'Bad cholesterol'
      },
      {
        'name': 'HDL (Male)',
        'fullName': 'High Density Lipoprotein - Male',
        'unit': 'mg/dL',
        'min': 40.0,
        'max': 200.0,
        'description': 'Good cholesterol'
      },
      {
        'name': 'HDL (Female)',
        'fullName': 'High Density Lipoprotein - Female',
        'unit': 'mg/dL',
        'min': 50.0,
        'max': 200.0,
        'description': 'Good cholesterol'
      },
      {
        'name': 'Triglycerides',
        'fullName': 'Triglycerides',
        'unit': 'mg/dL',
        'min': 0.0,
        'max': 150.0,
        'description': 'Blood fats'
      },
      {
        'name': 'VLDL',
        'fullName': 'Very Low Density Lipoprotein',
        'unit': 'mg/dL',
        'min': 2.0,
        'max': 30.0,
        'description': 'Precursor to LDL'
      },
    ],

    // ==================== COMPLETE BLOOD COUNT (CBC) ====================
    'Complete Blood Count': [
      {
        'name': 'Hemoglobin (Male)',
        'fullName': 'Hemoglobin - Male',
        'unit': 'g/dL',
        'min': 14.0,
        'max': 18.0,
        'description': 'Oxygen-carrying protein in blood'
      },
      {
        'name': 'Hemoglobin (Female)',
        'fullName': 'Hemoglobin - Female',
        'unit': 'g/dL',
        'min': 12.0,
        'max': 16.0,
        'description': 'Oxygen-carrying protein in blood'
      },
      {
        'name': 'WBC Count',
        'fullName': 'White Blood Cell Count',
        'unit': 'cells/μL',
        'min': 4000.0,
        'max': 11000.0,
        'description': 'Immune system cells'
      },
      {
        'name': 'Platelet Count',
        'fullName': 'Platelet Count',
        'unit': 'cells/μL',
        'min': 150000.0,
        'max': 400000.0,
        'description': 'Blood clotting cells'
      },
      {
        'name': 'Hematocrit (Male)',
        'fullName': 'Hematocrit - Male',
        'unit': '%',
        'min': 41.0,
        'max': 50.0,
        'description': 'Percentage of RBCs in blood'
      },
      {
        'name': 'Hematocrit (Female)',
        'fullName': 'Hematocrit - Female',
        'unit': '%',
        'min': 36.0,
        'max': 46.0,
        'description': 'Percentage of RBCs in blood'
      },
      {
        'name': 'RBC (Male)',
        'fullName': 'Red Blood Cell Count - Male',
        'unit': 'million/μL',
        'min': 5.0,
        'max': 6.0,
        'description': 'Red blood cells'
      },
      {
        'name': 'RBC (Female)',
        'fullName': 'Red Blood Cell Count - Female',
        'unit': 'million/μL',
        'min': 4.5,
        'max': 5.5,
        'description': 'Red blood cells'
      },
      {
        'name': 'MCV',
        'fullName': 'Mean Corpuscular Volume',
        'unit': 'fL',
        'min': 80.0,
        'max': 100.0,
        'description': 'Average RBC size'
      },
      {
        'name': 'MCH',
        'fullName': 'Mean Corpuscular Hemoglobin',
        'unit': 'pg',
        'min': 27.0,
        'max': 32.0,
        'description': 'Average hemoglobin per RBC'
      },
      {
        'name': 'MCHC',
        'fullName': 'Mean Corpuscular Hemoglobin Concentration',
        'unit': 'g/dL',
        'min': 32.0,
        'max': 36.0,
        'description': 'Hemoglobin concentration in RBCs'
      },
      {
        'name': 'ESR',
        'fullName': 'Erythrocyte Sedimentation Rate',
        'unit': 'mm/hr',
        'min': 0.0,
        'max': 20.0,
        'description': 'Marker of inflammation'
      },
    ],

    // ==================== LIVER FUNCTION TESTS ====================
    'Liver Function': [
      {
        'name': 'ALT (SGPT)',
        'fullName': 'Alanine Aminotransferase',
        'unit': 'U/L',
        'min': 7.0,
        'max': 56.0,
        'description': 'Liver enzyme'
      },
      {
        'name': 'AST (SGOT)',
        'fullName': 'Aspartate Aminotransferase',
        'unit': 'U/L',
        'min': 10.0,
        'max': 40.0,
        'description': 'Liver enzyme'
      },
      {
        'name': 'ALP',
        'fullName': 'Alkaline Phosphatase',
        'unit': 'U/L',
        'min': 44.0,
        'max': 147.0,
        'description': 'Enzyme in liver and bones'
      },
      {
        'name': 'GGT',
        'fullName': 'Gamma-Glutamyl Transferase',
        'unit': 'U/L',
        'min': 0.0,
        'max': 55.0,
        'description': 'Liver enzyme sensitive to alcohol'
      },
      {
        'name': 'Bilirubin (Total)',
        'fullName': 'Total Bilirubin',
        'unit': 'mg/dL',
        'min': 0.1,
        'max': 1.2,
        'description': 'Breakdown product of hemoglobin'
      },
      {
        'name': 'Bilirubin (Direct)',
        'fullName': 'Direct Bilirubin',
        'unit': 'mg/dL',
        'min': 0.0,
        'max': 0.3,
        'description': 'Conjugated bilirubin'
      },
      {
        'name': 'Bilirubin (Indirect)',
        'fullName': 'Indirect Bilirubin',
        'unit': 'mg/dL',
        'min': 0.1,
        'max': 1.0,
        'description': 'Unconjugated bilirubin'
      },
      {
        'name': 'Total Protein',
        'fullName': 'Total Serum Protein',
        'unit': 'g/dL',
        'min': 6.0,
        'max': 8.3,
        'description': 'All proteins in blood'
      },
      {
        'name': 'Albumin',
        'fullName': 'Serum Albumin',
        'unit': 'g/dL',
        'min': 3.5,
        'max': 5.5,
        'description': 'Main protein in blood'
      },
      {
        'name': 'Globulin',
        'fullName': 'Serum Globulin',
        'unit': 'g/dL',
        'min': 2.0,
        'max': 3.5,
        'description': 'Group of proteins including antibodies'
      },
      {
        'name': 'A/G Ratio',
        'fullName': 'Albumin/Globulin Ratio',
        'unit': 'ratio',
        'min': 1.0,
        'max': 2.5,
        'description': 'Ratio of albumin to globulin'
      },
    ],

    // ==================== KIDNEY FUNCTION TESTS ====================
    'Kidney Function': [
      {
        'name': 'Creatinine (Male)',
        'fullName': 'Serum Creatinine - Male',
        'unit': 'mg/dL',
        'min': 0.7,
        'max': 1.3,
        'description': 'Waste product from muscles'
      },
      {
        'name': 'Creatinine (Female)',
        'fullName': 'Serum Creatinine - Female',
        'unit': 'mg/dL',
        'min': 0.6,
        'max': 1.2,
        'description': 'Waste product from muscles'
      },
      {
        'name': 'BUN',
        'fullName': 'Blood Urea Nitrogen',
        'unit': 'mg/dL',
        'min': 7.0,
        'max': 20.0,
        'description': 'Waste product from protein breakdown'
      },
      {
        'name': 'eGFR',
        'fullName': 'Estimated Glomerular Filtration Rate',
        'unit': 'mL/min/1.73m²',
        'min': 60.0,
        'max': 120.0,
        'description': 'Kidney function indicator'
      },
      {
        'name': 'Uric Acid (Male)',
        'fullName': 'Serum Uric Acid - Male',
        'unit': 'mg/dL',
        'min': 3.5,
        'max': 7.2,
        'description': 'Marker for gout and kidney stones'
      },
      {
        'name': 'Uric Acid (Female)',
        'fullName': 'Serum Uric Acid - Female',
        'unit': 'mg/dL',
        'min': 2.6,
        'max': 6.0,
        'description': 'Marker for gout and kidney stones'
      },
      {
        'name': 'BUN/Creatinine Ratio',
        'fullName': 'BUN to Creatinine Ratio',
        'unit': 'ratio',
        'min': 10.0,
        'max': 20.0,
        'description': 'Kidney function assessment'
      },
    ],

    // ==================== ELECTROLYTES ====================
    'Electrolytes': [
      {
        'name': 'Sodium',
        'fullName': 'Serum Sodium',
        'unit': 'mEq/L',
        'min': 136.0,
        'max': 145.0,
        'description': 'Major electrolyte in blood'
      },
      {
        'name': 'Potassium',
        'fullName': 'Serum Potassium',
        'unit': 'mEq/L',
        'min': 3.5,
        'max': 5.0,
        'description': 'Critical for heart function'
      },
      {
        'name': 'Chloride',
        'fullName': 'Serum Chloride',
        'unit': 'mEq/L',
        'min': 96.0,
        'max': 106.0,
        'description': 'Maintains fluid balance'
      },
      {
        'name': 'Bicarbonate',
        'fullName': 'Serum Bicarbonate',
        'unit': 'mEq/L',
        'min': 22.0,
        'max': 29.0,
        'description': 'Buffer in blood'
      },
      {
        'name': 'Calcium',
        'fullName': 'Serum Calcium',
        'unit': 'mg/dL',
        'min': 8.5,
        'max': 10.5,
        'description': 'Bone health and nerve function'
      },
      {
        'name': 'Phosphorus',
        'fullName': 'Serum Phosphorus',
        'unit': 'mg/dL',
        'min': 2.5,
        'max': 4.5,
        'description': 'Works with calcium'
      },
      {
        'name': 'Magnesium',
        'fullName': 'Serum Magnesium',
        'unit': 'mg/dL',
        'min': 1.7,
        'max': 2.2,
        'description': 'Important for muscle and nerve function'
      },
    ],

    // ==================== VITAMINS & MINERALS ====================
    'Vitamins & Minerals': [
      {
        'name': 'Vitamin D (25-OH)',
        'fullName': '25-Hydroxyvitamin D',
        'unit': 'ng/mL',
        'min': 30.0,
        'max': 100.0,
        'description': 'Bone health and immunity'
      },
      {
        'name': 'Vitamin B12',
        'fullName': 'Vitamin B12',
        'unit': 'pg/mL',
        'min': 200.0,
        'max': 900.0,
        'description': 'Nerve function and RBC production'
      },
      {
        'name': 'Folate',
        'fullName': 'Serum Folate',
        'unit': 'ng/mL',
        'min': 2.7,
        'max': 17.0,
        'description': 'Cell growth and DNA synthesis'
      },
      {
        'name': 'Serum Iron (Male)',
        'fullName': 'Serum Iron - Male',
        'unit': 'μg/dL',
        'min': 80.0,
        'max': 180.0,
        'description': 'Essential for hemoglobin'
      },
      {
        'name': 'Serum Iron (Female)',
        'fullName': 'Serum Iron - Female',
        'unit': 'μg/dL',
        'min': 60.0,
        'max': 170.0,
        'description': 'Essential for hemoglobin'
      },
      {
        'name': 'Ferritin (Male)',
        'fullName': 'Serum Ferritin - Male',
        'unit': 'ng/mL',
        'min': 12.0,
        'max': 300.0,
        'description': 'Iron storage protein'
      },
      {
        'name': 'Ferritin (Female)',
        'fullName': 'Serum Ferritin - Female',
        'unit': 'ng/mL',
        'min': 12.0,
        'max': 150.0,
        'description': 'Iron storage protein'
      },
      {
        'name': 'TIBC',
        'fullName': 'Total Iron Binding Capacity',
        'unit': 'μg/dL',
        'min': 250.0,
        'max': 450.0,
        'description': 'Blood capacity to bind iron'
      },
      {
        'name': 'Transferrin Saturation',
        'fullName': 'Transferrin Saturation',
        'unit': '%',
        'min': 20.0,
        'max': 50.0,
        'description': 'Percentage of transferrin bound to iron'
      },
    ],

    // ==================== CARDIAC MARKERS ====================
    'Cardiac Markers': [
      {
        'name': 'Troponin I',
        'fullName': 'Cardiac Troponin I',
        'unit': 'ng/mL',
        'min': 0.0,
        'max': 0.04,
        'description': 'Heart damage marker'
      },
      {
        'name': 'Troponin T',
        'fullName': 'Cardiac Troponin T',
        'unit': 'ng/mL',
        'min': 0.0,
        'max': 0.01,
        'description': 'Heart damage marker'
      },
      {
        'name': 'CPK-MB',
        'fullName': 'Creatine Phosphokinase-MB',
        'unit': 'ng/mL',
        'min': 0.0,
        'max': 5.0,
        'description': 'Heart muscle enzyme'
      },
      {
        'name': 'BNP',
        'fullName': 'B-type Natriuretic Peptide',
        'unit': 'pg/mL',
        'min': 0.0,
        'max': 100.0,
        'description': 'Heart failure marker'
      },
      {
        'name': 'NT-proBNP',
        'fullName': 'N-terminal pro-BNP',
        'unit': 'pg/mL',
        'min': 0.0,
        'max': 125.0,
        'description': 'Heart failure marker'
      },
      {
        'name': 'D-Dimer',
        'fullName': 'D-Dimer',
        'unit': 'ng/mL',
        'min': 0.0,
        'max': 500.0,
        'description': 'Blood clot marker'
      },
    ],

    // ==================== COAGULATION PROFILE ====================
    'Coagulation': [
      {
        'name': 'PT',
        'fullName': 'Prothrombin Time',
        'unit': 'seconds',
        'min': 11.0,
        'max': 13.5,
        'description': 'Blood clotting time'
      },
      {
        'name': 'INR',
        'fullName': 'International Normalized Ratio',
        'unit': 'ratio',
        'min': 0.8,
        'max': 1.2,
        'description': 'Standardized PT measurement'
      },
      {
        'name': 'aPTT',
        'fullName': 'Activated Partial Thromboplastin Time',
        'unit': 'seconds',
        'min': 25.0,
        'max': 35.0,
        'description': 'Blood clotting time'
      },
      {
        'name': 'Bleeding Time',
        'fullName': 'Bleeding Time',
        'unit': 'minutes',
        'min': 2.0,
        'max': 7.0,
        'description': 'Time for bleeding to stop'
      },
      {
        'name': 'Clotting Time',
        'fullName': 'Clotting Time',
        'unit': 'minutes',
        'min': 5.0,
        'max': 10.0,
        'description': 'Time for blood to clot'
      },
    ],
  };

  // ==================== HELPER METHODS ====================

  /// Get list of all available categories
  static List<String> get categories => testsByCategory.keys.toList();

  /// Get list of test names for a specific category
  static List<String> getTestsForCategory(String category) {
    final tests = testsByCategory[category];
    if (tests == null) return [];
    return tests.map((t) => t['name'] as String).toList();
  }

  /// Get full details for a specific test
  static Map<String, dynamic>? getTestDetails(String category, String testName) {
    final tests = testsByCategory[category];
    if (tests == null) return null;
    try {
      return tests.firstWhere((t) => t['name'] == testName);
    } catch (e) {
      return null;
    }
  }

  /// Get all tests across all categories (for search functionality)
  static List<Map<String, dynamic>> getAllTests() {
    final allTests = <Map<String, dynamic>>[];
    for (final category in testsByCategory.entries) {
      for (final test in category.value) {
        allTests.add({
          ...test,
          'category': category.key,
        });
      }
    }
    return allTests;
  }

  /// Search tests by name (fuzzy search)
  static List<Map<String, dynamic>> searchTests(String query) {
    if (query.isEmpty) return [];

    final allTests = getAllTests();
    final lowercaseQuery = query.toLowerCase();

    return allTests.where((test) {
      final testName = (test['name'] as String).toLowerCase();
      final fullName = (test['fullName'] as String).toLowerCase();
      return testName.contains(lowercaseQuery) ||
          fullName.contains(lowercaseQuery);
    }).toList();
  }

  /// Get category for a specific test name
  static String? getCategoryForTest(String testName) {
    for (final category in testsByCategory.entries) {
      final testNames = category.value.map((t) => t['name'] as String);
      if (testNames.contains(testName)) {
        return category.key;
      }
    }
    return null;
  }

  /// Get total count of tests
  static int get totalTestCount {
    int count = 0;
    for (final category in testsByCategory.values) {
      count += category.length;
    }
    return count;
  }

  /// Get count of tests in a category
  static int getTestCountForCategory(String category) {
    final tests = testsByCategory[category];
    return tests?.length ?? 0;
  }
}