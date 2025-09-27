class Patient {
  final String name;
  final String age;
  final String diagnosis;
  final String date;

  const Patient({
    required this.name,
    required this.age,
    required this.diagnosis,
    required this.date,
  });

  Patient copyWith({
    String? name,
    String? age,
    String? diagnosis,
    String? date,
  }) {
    return Patient(
      name: name ?? this.name,
      age: age ?? this.age,
      diagnosis: diagnosis ?? this.diagnosis,
      date: date ?? this.date,
    );
  }
}