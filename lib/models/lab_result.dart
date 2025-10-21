// lib/models/lab_result.dart
// ✅ COMPLETE FIXED VERSION

class LabResult {
  final String testName;
  final String value;
  final String unit;
  final bool isAbnormal;

  LabResult({
    required this.testName,
    required this.value,
    required this.unit,
    this.isAbnormal = false,
  });

  // ✅ NEW: toJson() for consultation draft saving
  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'value': value,
      'unit': unit,
      'isAbnormal': isAbnormal,
    };
  }

  // ✅ NEW: fromJson() for consultation draft loading
  factory LabResult.fromJson(Map<String, dynamic> json) {
    return LabResult(
      testName: json['testName'] ?? '',
      value: json['value'] ?? '',
      unit: json['unit'] ?? '',
      isAbnormal: json['isAbnormal'] ?? false,
    );
  }

  // toMap() for database storage (if needed)
  Map<String, dynamic> toMap() {
    return {
      'test_name': testName,
      'value': value,
      'unit': unit,
      'is_abnormal': isAbnormal ? 1 : 0,
    };
  }

  // fromMap() for database retrieval (if needed)
  factory LabResult.fromMap(Map<String, dynamic> map) {
    return LabResult(
      testName: map['test_name'] ?? '',
      value: map['value'] ?? '',
      unit: map['unit'] ?? '',
      isAbnormal: (map['is_abnormal'] ?? 0) == 1,
    );
  }

  // copyWith() for creating modified copies
  LabResult copyWith({
    String? testName,
    String? value,
    String? unit,
    bool? isAbnormal,
  }) {
    return LabResult(
      testName: testName ?? this.testName,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      isAbnormal: isAbnormal ?? this.isAbnormal,
    );
  }

  @override
  String toString() {
    return 'LabResult{testName: $testName, value: $value $unit, isAbnormal: $isAbnormal}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LabResult &&
              runtimeType == other.runtimeType &&
              testName == other.testName &&
              value == other.value &&
              unit == other.unit &&
              isAbnormal == other.isAbnormal;

  @override
  int get hashCode =>
      testName.hashCode ^
      value.hashCode ^
      unit.hashCode ^
      isAbnormal.hashCode;
}