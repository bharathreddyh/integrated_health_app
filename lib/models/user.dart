enum UserRole {
  doctor,
  nurse,
  patient;

  String toJson() => name;

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere((e) => e.name == value);
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? specialty;
  final String? patientId;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.specialty,
    this.patientId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'specialty': specialty,
      'patient_id': patientId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: UserRole.fromJson(map['role'] as String),
      specialty: map['specialty'] as String?,
      patientId: map['patient_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? specialty,
    String? patientId,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      specialty: specialty ?? this.specialty,
      patientId: patientId ?? this.patientId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}