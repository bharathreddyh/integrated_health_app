// lib/models/prescription.dart
// ✅ COMPLETE FIXED VERSION

class Prescription {
  final int? id;
  final int visitId;
  final String patientId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;
  final DateTime createdAt;

  Prescription({
    this.id,
    required this.visitId,
    required this.patientId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
    required this.createdAt,
  });

  // ✅ FIXED: toJson() for consultation draft saving
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitId': visitId,
      'patientId': patientId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ✅ FIXED: fromJson() for consultation draft loading
  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      visitId: json['visitId'] ?? 0,
      patientId: json['patientId'] ?? '',
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
      instructions: json['instructions'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // toMap() for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visit_id': visitId,
      'patient_id': patientId,
      'medication_name': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // fromMap() for database retrieval
  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'],
      visitId: map['visit_id'],
      patientId: map['patient_id'].toString(),
      medicationName: map['medication_name'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      duration: map['duration'],
      instructions: map['instructions'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // copyWith() for creating modified copies
  Prescription copyWith({
    int? id,
    int? visitId,
    String? patientId,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
    DateTime? createdAt,
  }) {
    return Prescription(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      patientId: patientId ?? this.patientId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Prescription{id: $id, medication: $medicationName, dosage: $dosage, frequency: $frequency, duration: $duration}';
  }
}