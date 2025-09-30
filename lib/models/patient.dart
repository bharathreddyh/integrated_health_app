class Patient {
  final String id;
  final String name;
  final int age;
  final String phone;
  final String? diagnosis;
  final String date;
  final List<String> conditions;
  final int visits;
  final String? notes;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.phone,
    this.diagnosis,
    required this.date,
    this.conditions = const [],
    this.visits = 1,
    this.notes,
  });

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? phone,
    String? diagnosis,
    String? date,
    List<String>? conditions,
    int? visits,
    String? notes,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      diagnosis: diagnosis ?? this.diagnosis,
      date: date ?? this.date,
      conditions: conditions ?? this.conditions,
      visits: visits ?? this.visits,
      notes: notes ?? this.notes,
    );
  }
}