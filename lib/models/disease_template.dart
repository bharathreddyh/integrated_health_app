import 'dart:convert';

class DiseaseTemplate {
  final int? id;
  final String name;
  final String category;
  final Map<String, dynamic> details;

  DiseaseTemplate({
    this.id,
    required this.name,
    required this.category,
    required this.details,
  });

  /// Empty template for new entries
  factory DiseaseTemplate.empty() => DiseaseTemplate(
    name: '',
    category: '',
    details: {},
  );

  /// Convert object → map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'details': jsonEncode(details),
    };
  }

  /// Convert SQLite row → object
  factory DiseaseTemplate.fromMap(Map<String, dynamic> map) {
    return DiseaseTemplate(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      details: map['details'] is String
          ? jsonDecode(map['details'])
          : (map['details'] ?? {}),
    );
  }

  DiseaseTemplate copyWith({
    int? id,
    String? name,
    String? category,
    Map<String, dynamic>? details,
  }) {
    return DiseaseTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      details: details ?? this.details,
    );
  }
}
