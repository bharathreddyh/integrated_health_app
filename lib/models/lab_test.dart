// lib/models/lab_test.dart

enum LabTestStatus {
  pending,
  completed,
  cancelled;

  String toJson() => name;

  static LabTestStatus fromJson(String value) {
    return LabTestStatus.values.firstWhere((e) => e.name == value);
  }
}

enum LabTestCategory {
  hematology,
  biochemistry,
  microbiology,
  immunology,
  radiology,
  other;

  String toJson() => name;

  static LabTestCategory fromJson(String value) {
    return LabTestCategory.values.firstWhere((e) => e.name == value);
  }

  String get displayName {
    switch (this) {
      case LabTestCategory.hematology:
        return 'Hematology';
      case LabTestCategory.biochemistry:
        return 'Biochemistry';
      case LabTestCategory.microbiology:
        return 'Microbiology';
      case LabTestCategory.immunology:
        return 'Immunology';
      case LabTestCategory.radiology:
        return 'Radiology';
      case LabTestCategory.other:
        return 'Other';
    }
  }
}

class LabTest {
  final int? id;
  final int visitId;
  final String patientId;
  final String testName;
  final LabTestCategory testCategory;
  final DateTime orderedDate;
  final DateTime? resultDate;
  final String? resultValue;
  final String? resultUnit;
  final String? normalRangeMin;
  final String? normalRangeMax;
  final bool isAbnormal;
  final LabTestStatus status;
  final String? notes;
  final DateTime createdAt;

  LabTest({
    this.id,
    required this.visitId,
    required this.patientId,
    required this.testName,
    required this.testCategory,
    required this.orderedDate,
    this.resultDate,
    this.resultValue,
    this.resultUnit,
    this.normalRangeMin,
    this.normalRangeMax,
    this.isAbnormal = false,
    this.status = LabTestStatus.pending,
    this.notes,
    required this.createdAt,
  });

  // Check if result is abnormal based on range
  bool checkIfAbnormal() {
    if (resultValue == null || resultValue!.isEmpty) return false;
    if (normalRangeMin == null && normalRangeMax == null) return false;

    try {
      final value = double.parse(resultValue!);
      final min = normalRangeMin != null ? double.parse(normalRangeMin!) : null;
      final max = normalRangeMax != null ? double.parse(normalRangeMax!) : null;

      if (min != null && value < min) return true;
      if (max != null && value > max) return true;
      return false;
    } catch (e) {
      return false; // Can't parse numbers, assume normal
    }
  }

  String get normalRangeDisplay {
    if (normalRangeMin != null && normalRangeMax != null) {
      return '$normalRangeMin - $normalRangeMax';
    } else if (normalRangeMin != null) {
      return '≥ $normalRangeMin';
    } else if (normalRangeMax != null) {
      return '≤ $normalRangeMax';
    }
    return 'N/A';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visit_id': visitId,
      'patient_id': patientId,
      'test_name': testName,
      'test_category': testCategory.name,
      'ordered_date': orderedDate.toIso8601String(),
      'result_date': resultDate?.toIso8601String(),
      'result_value': resultValue,
      'result_unit': resultUnit,
      'normal_range_min': normalRangeMin,
      'normal_range_max': normalRangeMax,
      'is_abnormal': isAbnormal ? 1 : 0,
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LabTest.fromMap(Map<String, dynamic> map) {
    return LabTest(
      id: map['id'] as int?,
      visitId: map['visit_id'] as int,
      patientId: map['patient_id'] as String,
      testName: map['test_name'] as String,
      testCategory: LabTestCategory.fromJson(map['test_category'] as String),
      orderedDate: DateTime.parse(map['ordered_date'] as String),
      resultDate: map['result_date'] != null
          ? DateTime.parse(map['result_date'] as String)
          : null,
      resultValue: map['result_value'] as String?,
      resultUnit: map['result_unit'] as String?,
      normalRangeMin: map['normal_range_min'] as String?,
      normalRangeMax: map['normal_range_max'] as String?,
      isAbnormal: (map['is_abnormal'] as int) == 1,
      status: LabTestStatus.fromJson(map['status'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  LabTest copyWith({
    int? id,
    int? visitId,
    String? patientId,
    String? testName,
    LabTestCategory? testCategory,
    DateTime? orderedDate,
    DateTime? resultDate,
    String? resultValue,
    String? resultUnit,
    String? normalRangeMin,
    String? normalRangeMax,
    bool? isAbnormal,
    LabTestStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return LabTest(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      patientId: patientId ?? this.patientId,
      testName: testName ?? this.testName,
      testCategory: testCategory ?? this.testCategory,
      orderedDate: orderedDate ?? this.orderedDate,
      resultDate: resultDate ?? this.resultDate,
      resultValue: resultValue ?? this.resultValue,
      resultUnit: resultUnit ?? this.resultUnit,
      normalRangeMin: normalRangeMin ?? this.normalRangeMin,
      normalRangeMax: normalRangeMax ?? this.normalRangeMax,
      isAbnormal: isAbnormal ?? this.isAbnormal,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'LabTest{id: $id, test: $testName, status: $status, value: $resultValue}';
  }
}