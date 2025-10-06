// lib/models/prescription.dart

class Prescription {
  final int? id;
  final int visitId;
  final String patientId; // Changed to String to match Patient.id
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

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'],
      visitId: map['visit_id'],
      patientId: map['patient_id'].toString(), // Convert to String
      medicationName: map['medication_name'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      duration: map['duration'],
      instructions: map['instructions'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

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