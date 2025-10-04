import 'dart:convert';
import 'vitals.dart';

class Patient {
  final String id;
  final String name;
  final int age;
  final String phone;
  final String date;
  final List<String> conditions;
  final String? notes;
  final int visits;
  final Vitals? vitals;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.phone,
    required this.date,
    this.conditions = const [],
    this.notes,
    this.visits = 0,
    this.vitals,
  });

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? phone,
    String? date,
    List<String>? conditions,
    String? notes,
    int? visits,
    Vitals? vitals,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      date: date ?? this.date,
      conditions: conditions ?? this.conditions,
      notes: notes ?? this.notes,
      visits: visits ?? this.visits,
      vitals: vitals ?? this.vitals,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'phone': phone,
      'date': date,
      'conditions': jsonEncode(conditions),
      'notes': notes,
      'visits': visits,
      'vitals': vitals?.toJson(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      phone: map['phone'] as String,
      date: map['date'] as String,
      conditions: map['conditions'] != null
          ? List<String>.from(jsonDecode(map['conditions'] as String))
          : [],
      notes: map['notes'] as String?,
      visits: map['visits'] as int? ?? 0,
      vitals: map['vitals'] != null
          ? Vitals.fromJson(map['vitals'] as String)
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Patient.fromJson(String source) =>
      Patient.fromMap(jsonDecode(source) as Map<String, dynamic>);
}