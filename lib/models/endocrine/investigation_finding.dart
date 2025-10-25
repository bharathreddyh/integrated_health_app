// ==================== INVESTIGATION MODELS ====================
// File: lib/models/endocrine/investigation_finding.dart

class InvestigationFinding {
  final String id;
  final String investigationType; // 'ultrasound', 'ct', 'mri', 'biopsy', 'nuclear_medicine', 'cardiac', 'other'
  final String investigationName;
  final DateTime performedDate;
  final String findings; // Main findings text
  final String impression; // Radiologist/pathologist impression
  final Map<String, dynamic>? structuredData; // Type-specific data (USG dimensions, FNAC category, etc.)
  final List<String>? imageUrls;
  final String? performedBy; // Doctor/technician name
  final String? referringDoctor;
  final String? notes;

  InvestigationFinding({
    required this.id,
    required this.investigationType,
    required this.investigationName,
    required this.performedDate,
    required this.findings,
    required this.impression,
    this.structuredData,
    this.imageUrls,
    this.performedBy,
    this.referringDoctor,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'investigationType': investigationType,
    'investigationName': investigationName,
    'performedDate': performedDate.toIso8601String(),
    'findings': findings,
    'impression': impression,
    'structuredData': structuredData,
    'imageUrls': imageUrls,
    'performedBy': performedBy,
    'referringDoctor': referringDoctor,
    'notes': notes,
  };

  factory InvestigationFinding.fromJson(Map<String, dynamic> json) {
    return InvestigationFinding(
      id: json['id'] as String,
      investigationType: json['investigationType'] as String,
      investigationName: json['investigationName'] as String,
      performedDate: DateTime.parse(json['performedDate'] as String),
      findings: json['findings'] as String,
      impression: json['impression'] as String,
      structuredData: json['structuredData'] as Map<String, dynamic>?,
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'] as List)
          : null,
      performedBy: json['performedBy'] as String?,
      referringDoctor: json['referringDoctor'] as String?,
      notes: json['notes'] as String?,
    );
  }

  InvestigationFinding copyWith({
    String? id,
    String? investigationType,
    String? investigationName,
    DateTime? performedDate,
    String? findings,
    String? impression,
    Map<String, dynamic>? structuredData,
    List<String>? imageUrls,
    String? performedBy,
    String? referringDoctor,
    String? notes,
  }) {
    return InvestigationFinding(
      id: id ?? this.id,
      investigationType: investigationType ?? this.investigationType,
      investigationName: investigationName ?? this.investigationName,
      performedDate: performedDate ?? this.performedDate,
      findings: findings ?? this.findings,
      impression: impression ?? this.impression,
      structuredData: structuredData ?? this.structuredData,
      imageUrls: imageUrls ?? this.imageUrls,
      performedBy: performedBy ?? this.performedBy,
      referringDoctor: referringDoctor ?? this.referringDoctor,
      notes: notes ?? this.notes,
    );
  }
}

// ==================== USG THYROID STRUCTURED DATA ====================
class USGThyroidData {
  // Dimensions
  final double? rightLobeLength; // cm
  final double? rightLobeWidth; // cm
  final double? rightLobeDepth; // cm
  final double? leftLobeLength;
  final double? leftLobeWidth;
  final double? leftLobeDepth;
  final double? isthmusThickness; // mm

  // Characteristics
  final String echogenicity; // 'normal', 'hypoechoic', 'hyperechoic', 'heterogeneous'
  final String vascularity; // 'normal', 'increased', 'decreased'

  // Nodules
  final bool nodulesPresent;
  final int? noduleCount;
  final List<ThyroidNodule>? nodules;

  // Lymph Nodes
  final String lymphNodes; // 'normal', 'abnormal'
  final String? lymphNodeDescription;

  USGThyroidData({
    this.rightLobeLength,
    this.rightLobeWidth,
    this.rightLobeDepth,
    this.leftLobeLength,
    this.leftLobeWidth,
    this.leftLobeDepth,
    this.isthmusThickness,
    required this.echogenicity,
    required this.vascularity,
    required this.nodulesPresent,
    this.noduleCount,
    this.nodules,
    required this.lymphNodes,
    this.lymphNodeDescription,
  });

  Map<String, dynamic> toJson() => {
    'rightLobeLength': rightLobeLength,
    'rightLobeWidth': rightLobeWidth,
    'rightLobeDepth': rightLobeDepth,
    'leftLobeLength': leftLobeLength,
    'leftLobeWidth': leftLobeWidth,
    'leftLobeDepth': leftLobeDepth,
    'isthmusThickness': isthmusThickness,
    'echogenicity': echogenicity,
    'vascularity': vascularity,
    'nodulesPresent': nodulesPresent,
    'noduleCount': noduleCount,
    'nodules': nodules?.map((n) => n.toJson()).toList(),
    'lymphNodes': lymphNodes,
    'lymphNodeDescription': lymphNodeDescription,
  };

  factory USGThyroidData.fromJson(Map<String, dynamic> json) {
    return USGThyroidData(
      rightLobeLength: json['rightLobeLength'] as double?,
      rightLobeWidth: json['rightLobeWidth'] as double?,
      rightLobeDepth: json['rightLobeDepth'] as double?,
      leftLobeLength: json['leftLobeLength'] as double?,
      leftLobeWidth: json['leftLobeWidth'] as double?,
      leftLobeDepth: json['leftLobeDepth'] as double?,
      isthmusThickness: json['isthmusThickness'] as double?,
      echogenicity: json['echogenicity'] as String,
      vascularity: json['vascularity'] as String,
      nodulesPresent: json['nodulesPresent'] as bool,
      noduleCount: json['noduleCount'] as int?,
      nodules: (json['nodules'] as List?)
          ?.map((n) => ThyroidNodule.fromJson(n as Map<String, dynamic>))
          .toList(),
      lymphNodes: json['lymphNodes'] as String,
      lymphNodeDescription: json['lymphNodeDescription'] as String?,
    );
  }
}

class ThyroidNodule {
  final String location; // 'right_lobe', 'left_lobe', 'isthmus'
  final double size; // cm
  final String characteristics;
  final String? tiradsScore; // 'TR1', 'TR2', 'TR3', 'TR4', 'TR5'

  ThyroidNodule({
    required this.location,
    required this.size,
    required this.characteristics,
    this.tiradsScore,
  });

  Map<String, dynamic> toJson() => {
    'location': location,
    'size': size,
    'characteristics': characteristics,
    'tiradsScore': tiradsScore,
  };

  factory ThyroidNodule.fromJson(Map<String, dynamic> json) {
    return ThyroidNodule(
      location: json['location'] as String,
      size: (json['size'] as num).toDouble(),
      characteristics: json['characteristics'] as String,
      tiradsScore: json['tiradsScore'] as String?,
    );
  }
}

// ==================== FNAC DATA ====================
class FNACData {
  final DateTime biopsyDate;
  final String site; // 'right_lobe', 'left_lobe', 'nodule'
  final String bethesdaCategory; // 'I', 'II', 'III', 'IV', 'V', 'VI'
  final String cytologyFindings;
  final String recommendation;
  final String? pathologistName;

  FNACData({
    required this.biopsyDate,
    required this.site,
    required this.bethesdaCategory,
    required this.cytologyFindings,
    required this.recommendation,
    this.pathologistName,
  });

  String get bethesdaDescription {
    switch (bethesdaCategory) {
      case 'I':
        return 'Nondiagnostic/Unsatisfactory';
      case 'II':
        return 'Benign';
      case 'III':
        return 'Atypia of Undetermined Significance (AUS)';
      case 'IV':
        return 'Follicular Neoplasm/Suspicious for Follicular Neoplasm';
      case 'V':
        return 'Suspicious for Malignancy';
      case 'VI':
        return 'Malignant';
      default:
        return 'Unknown';
    }
  }

  Map<String, dynamic> toJson() => {
    'biopsyDate': biopsyDate.toIso8601String(),
    'site': site,
    'bethesdaCategory': bethesdaCategory,
    'cytologyFindings': cytologyFindings,
    'recommendation': recommendation,
    'pathologistName': pathologistName,
  };

  factory FNACData.fromJson(Map<String, dynamic> json) {
    return FNACData(
      biopsyDate: DateTime.parse(json['biopsyDate'] as String),
      site: json['site'] as String,
      bethesdaCategory: json['bethesdaCategory'] as String,
      cytologyFindings: json['cytologyFindings'] as String,
      recommendation: json['recommendation'] as String,
      pathologistName: json['pathologistName'] as String?,
    );
  }
}

// ==================== THYROID SCAN DATA ====================
class ThyroidScanData {
  final DateTime scanDate;
  final String pattern; // 'diffuse', 'focal', 'multinodular', 'cold_nodule', 'hot_nodule'
  final String findings;

  ThyroidScanData({
    required this.scanDate,
    required this.pattern,
    required this.findings,
  });

  Map<String, dynamic> toJson() => {
    'scanDate': scanDate.toIso8601String(),
    'pattern': pattern,
    'findings': findings,
  };

  factory ThyroidScanData.fromJson(Map<String, dynamic> json) {
    return ThyroidScanData(
      scanDate: DateTime.parse(json['scanDate'] as String),
      pattern: json['pattern'] as String,
      findings: json['findings'] as String,
    );
  }
}

// ==================== RAI UPTAKE DATA ====================
class RAIUptakeData {
  final DateTime scanDate;
  final double sixHourUptake; // %
  final double twentyFourHourUptake; // %
  final String interpretation; // 'low', 'normal', 'high'

  RAIUptakeData({
    required this.scanDate,
    required this.sixHourUptake,
    required this.twentyFourHourUptake,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
    'scanDate': scanDate.toIso8601String(),
    'sixHourUptake': sixHourUptake,
    'twentyFourHourUptake': twentyFourHourUptake,
    'interpretation': interpretation,
  };

  factory RAIUptakeData.fromJson(Map<String, dynamic> json) {
    return RAIUptakeData(
      scanDate: DateTime.parse(json['scanDate'] as String),
      sixHourUptake: (json['sixHourUptake'] as num).toDouble(),
      twentyFourHourUptake: (json['twentyFourHourUptake'] as num).toDouble(),
      interpretation: json['interpretation'] as String,
    );
  }
}

// ==================== ECG DATA ====================
class ECGData {
  final DateTime ecgDate;
  final int heartRate; // bpm
  final String rhythm; // 'regular', 'irregular'
  final String findings;
  final String interpretation; // 'normal', 'abnormal'

  ECGData({
    required this.ecgDate,
    required this.heartRate,
    required this.rhythm,
    required this.findings,
    required this.interpretation,
  });

  Map<String, dynamic> toJson() => {
    'ecgDate': ecgDate.toIso8601String(),
    'heartRate': heartRate,
    'rhythm': rhythm,
    'findings': findings,
    'interpretation': interpretation,
  };

  factory ECGData.fromJson(Map<String, dynamic> json) {
    return ECGData(
      ecgDate: DateTime.parse(json['ecgDate'] as String),
      heartRate: json['heartRate'] as int,
      rhythm: json['rhythm'] as String,
      findings: json['findings'] as String,
      interpretation: json['interpretation'] as String,
    );
  }
}

// ==================== ECHO DATA ====================
class EchoData {
  final DateTime echoDate;
  final double? ejectionFraction; // %
  final String? chamberSizes;
  final String? valveFunction;
  final String keyFindings;
  final String assessment; // 'normal', 'abnormal'

  EchoData({
    required this.echoDate,
    this.ejectionFraction,
    this.chamberSizes,
    this.valveFunction,
    required this.keyFindings,
    required this.assessment,
  });

  Map<String, dynamic> toJson() => {
    'echoDate': echoDate.toIso8601String(),
    'ejectionFraction': ejectionFraction,
    'chamberSizes': chamberSizes,
    'valveFunction': valveFunction,
    'keyFindings': keyFindings,
    'assessment': assessment,
  };

  factory EchoData.fromJson(Map<String, dynamic> json) {
    return EchoData(
      echoDate: DateTime.parse(json['echoDate'] as String),
      ejectionFraction: json['ejectionFraction'] as double?,
      chamberSizes: json['chamberSizes'] as String?,
      valveFunction: json['valveFunction'] as String?,
      keyFindings: json['keyFindings'] as String,
      assessment: json['assessment'] as String,
    );
  }
}