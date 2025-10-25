// ==================== INVESTIGATION LIBRARY ====================
// File: lib/config/investigation_library.dart

class InvestigationLibrary {
  static const Map<String, List<Map<String, dynamic>>> investigationsByCategory = {

    // ==================== ULTRASOUND ====================
    'Ultrasound': [
      {
        'name': 'USG Thyroid',
        'type': 'ultrasound',
        'hasStructuredForm': true,
        'description': 'Ultrasound examination of thyroid gland',
      },
      {
        'name': 'USG Neck',
        'type': 'ultrasound',
        'hasStructuredForm': false,
        'description': 'Ultrasound of neck region',
      },
      {
        'name': 'USG Abdomen',
        'type': 'ultrasound',
        'hasStructuredForm': false,
        'description': 'Abdominal ultrasound',
      },
      {
        'name': 'USG Pelvis',
        'type': 'ultrasound',
        'hasStructuredForm': false,
        'description': 'Pelvic ultrasound',
      },
      {
        'name': 'Doppler Study',
        'type': 'ultrasound',
        'hasStructuredForm': false,
        'description': 'Doppler blood flow study',
      },
    ],

    // ==================== NUCLEAR MEDICINE ====================
    'Nuclear Medicine': [
      {
        'name': 'Thyroid Scan (Tc-99m)',
        'type': 'nuclear_medicine',
        'hasStructuredForm': true,
        'description': 'Technetium-99m thyroid scan',
      },
      {
        'name': 'Radioiodine Uptake Scan',
        'type': 'nuclear_medicine',
        'hasStructuredForm': true,
        'description': 'RAI uptake measurement',
      },
      {
        'name': 'PET-CT',
        'type': 'nuclear_medicine',
        'hasStructuredForm': false,
        'description': 'Positron Emission Tomography with CT',
      },
      {
        'name': 'Bone Scan',
        'type': 'nuclear_medicine',
        'hasStructuredForm': false,
        'description': 'Nuclear bone imaging',
      },
    ],

    // ==================== CT SCANS ====================
    'CT Scan': [
      {
        'name': 'CT Neck with Contrast',
        'type': 'ct',
        'hasStructuredForm': false,
        'description': 'Contrast-enhanced CT of neck',
      },
      {
        'name': 'CT Neck Plain',
        'type': 'ct',
        'hasStructuredForm': false,
        'description': 'Non-contrast CT of neck',
      },
      {
        'name': 'CT Brain',
        'type': 'ct',
        'hasStructuredForm': false,
        'description': 'CT scan of brain',
      },
      {
        'name': 'CT Chest',
        'type': 'ct',
        'hasStructuredForm': false,
        'description': 'CT scan of chest',
      },
      {
        'name': 'CT Abdomen',
        'type': 'ct',
        'hasStructuredForm': false,
        'description': 'CT scan of abdomen',
      },
      {
        'name': 'HRCT Chest',
        'type': 'ct',
        'hasStructuredForm': false,
        'description': 'High Resolution CT of chest',
      },
    ],

    // ==================== MRI SCANS ====================
    'MRI': [
      {
        'name': 'MRI Neck',
        'type': 'mri',
        'hasStructuredForm': false,
        'description': 'MRI of neck region',
      },
      {
        'name': 'MRI Brain',
        'type': 'mri',
        'hasStructuredForm': false,
        'description': 'MRI of brain',
      },
      {
        'name': 'MRI Spine',
        'type': 'mri',
        'hasStructuredForm': false,
        'description': 'MRI of spine',
      },
      {
        'name': 'MRI Pituitary',
        'type': 'mri',
        'hasStructuredForm': false,
        'description': 'Dedicated pituitary MRI',
      },
    ],

    // ==================== BIOPSY ====================
    'Biopsy': [
      {
        'name': 'FNAC Thyroid',
        'type': 'biopsy',
        'hasStructuredForm': true,
        'description': 'Fine Needle Aspiration Cytology of thyroid',
      },
      {
        'name': 'Core Needle Biopsy',
        'type': 'biopsy',
        'hasStructuredForm': false,
        'description': 'Core biopsy of thyroid',
      },
      {
        'name': 'Thyroid Biopsy',
        'type': 'biopsy',
        'hasStructuredForm': false,
        'description': 'General thyroid biopsy',
      },
    ],

    // ==================== CARDIAC ASSESSMENT ====================
    'Cardiac Assessment': [
      {
        'name': 'ECG',
        'type': 'cardiac',
        'hasStructuredForm': true,
        'description': 'Electrocardiogram',
      },
      {
        'name': 'ECHO (Echocardiography)',
        'type': 'cardiac',
        'hasStructuredForm': true,
        'description': '2D Echocardiography',
      },
      {
        'name': '2D ECHO',
        'type': 'cardiac',
        'hasStructuredForm': true,
        'description': 'Two-dimensional echocardiography',
      },
      {
        'name': 'Holter Monitoring',
        'type': 'cardiac',
        'hasStructuredForm': false,
        'description': '24-hour ECG monitoring',
      },
      {
        'name': 'Stress Test',
        'type': 'cardiac',
        'hasStructuredForm': false,
        'description': 'Cardiac stress testing',
      },
    ],

    // ==================== X-RAY ====================
    'X-Ray': [
      {
        'name': 'X-Ray Chest PA',
        'type': 'xray',
        'hasStructuredForm': false,
        'description': 'Chest X-ray posteroanterior view',
      },
      {
        'name': 'X-Ray Chest AP',
        'type': 'xray',
        'hasStructuredForm': false,
        'description': 'Chest X-ray anteroposterior view',
      },
      {
        'name': 'X-Ray Neck Soft Tissue',
        'type': 'xray',
        'hasStructuredForm': false,
        'description': 'Soft tissue X-ray of neck',
      },
      {
        'name': 'X-Ray Skull',
        'type': 'xray',
        'hasStructuredForm': false,
        'description': 'Skull X-ray',
      },
    ],

    // ==================== OTHER INVESTIGATIONS ====================
    'Other': [
      {
        'name': 'Bone Density Scan (DEXA)',
        'type': 'other',
        'hasStructuredForm': false,
        'description': 'Dual-energy X-ray absorptiometry',
      },
      {
        'name': 'Laryngoscopy',
        'type': 'other',
        'hasStructuredForm': false,
        'description': 'Examination of larynx',
      },
      {
        'name': 'Vocal Cord Assessment',
        'type': 'other',
        'hasStructuredForm': false,
        'description': 'Evaluation of vocal cord function',
      },
    ],
  };

  // Get all categories
  static List<String> get categories => investigationsByCategory.keys.toList();

  // Get investigations for a specific category
  static List<String> getInvestigationsForCategory(String category) {
    final investigations = investigationsByCategory[category];
    if (investigations == null) return [];
    return investigations.map((i) => i['name'] as String).toList();
  }

  // Get investigation details
  static Map<String, dynamic>? getInvestigationDetails(
      String category, String investigationName) {
    final investigations = investigationsByCategory[category];
    if (investigations == null) return null;
    try {
      return investigations.firstWhere((i) => i['name'] == investigationName);
    } catch (e) {
      return null;
    }
  }

  // Check if investigation has structured form
  static bool hasStructuredForm(String investigationName) {
    for (final category in investigationsByCategory.values) {
      for (final investigation in category) {
        if (investigation['name'] == investigationName) {
          return investigation['hasStructuredForm'] as bool;
        }
      }
    }
    return false;
  }

  // Get investigation type
  static String? getInvestigationType(String investigationName) {
    for (final category in investigationsByCategory.values) {
      for (final investigation in category) {
        if (investigation['name'] == investigationName) {
          return investigation['type'] as String;
        }
      }
    }
    return null;
  }

  // Get all investigations
  static List<Map<String, dynamic>> getAllInvestigations() {
    final allInvestigations = <Map<String, dynamic>>[];
    for (final category in investigationsByCategory.entries) {
      for (final investigation in category.value) {
        allInvestigations.add({
          ...investigation,
          'category': category.key,
        });
      }
    }
    return allInvestigations;
  }

  // Search investigations
  static List<Map<String, dynamic>> searchInvestigations(String query) {
    if (query.isEmpty) return [];

    final allInvestigations = getAllInvestigations();
    final lowercaseQuery = query.toLowerCase();

    return allInvestigations.where((investigation) {
      final name = (investigation['name'] as String).toLowerCase();
      final description =
      (investigation['description'] as String).toLowerCase();
      return name.contains(lowercaseQuery) ||
          description.contains(lowercaseQuery);
    }).toList();
  }
}