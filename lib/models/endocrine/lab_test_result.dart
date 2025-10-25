// lib/models/endocrine/lab_test_result.dart
// Complete Lab Test Result Model

class LabTestResult {
  final String id;
  final String testName;
  final String category;
  final double value;
  final String unit;
  final double normalMin;
  final double normalMax;
  final DateTime testDate;
  final String? notes;
  final String? reportedBy;
  final String status; // 'low', 'normal', 'high'

  LabTestResult({
    required this.id,
    required this.testName,
    required this.category,
    required this.value,
    required this.unit,
    required this.normalMin,
    required this.normalMax,
    required this.testDate,
    this.notes,
    this.reportedBy,
  }) : status = _calculateStatus(value, normalMin, normalMax);

  static String _calculateStatus(double value, double min, double max) {
    if (value < min) return 'low';
    if (value > max) return 'high';
    return 'normal';
  }

  bool get isAbnormal => status != 'normal';

  Map<String, dynamic> toJson() => {
    'id': id,
    'testName': testName,
    'category': category,
    'value': value,
    'unit': unit,
    'normalMin': normalMin,
    'normalMax': normalMax,
    'testDate': testDate.toIso8601String(),
    'notes': notes,
    'reportedBy': reportedBy,
    'status': status,
  };

  factory LabTestResult.fromJson(Map<String, dynamic> json) {
    return LabTestResult(
      id: json['id'] as String,
      testName: json['testName'] as String,
      category: json['category'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      normalMin: (json['normalMin'] as num).toDouble(),
      normalMax: (json['normalMax'] as num).toDouble(),
      testDate: DateTime.parse(json['testDate'] as String),
      notes: json['notes'] as String?,
      reportedBy: json['reportedBy'] as String?,
    );
  }

  LabTestResult copyWith({
    String? id,
    String? testName,
    String? category,
    double? value,
    String? unit,
    double? normalMin,
    double? normalMax,
    DateTime? testDate,
    String? notes,
    String? reportedBy,
  }) {
    return LabTestResult(
      id: id ?? this.id,
      testName: testName ?? this.testName,
      category: category ?? this.category,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      normalMin: normalMin ?? this.normalMin,
      normalMax: normalMax ?? this.normalMax,
      testDate: testDate ?? this.testDate,
      notes: notes ?? this.notes,
      reportedBy: reportedBy ?? this.reportedBy,
    );
  }
}