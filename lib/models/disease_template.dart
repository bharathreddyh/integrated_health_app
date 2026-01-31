import 'dart:convert';

class TemplateDiagram {
  final String id;
  final String title;
  final String description;
  final String imageAsset;

  const TemplateDiagram({
    required this.id,
    required this.title,
    required this.description,
    required this.imageAsset,
  });
}

class TemplateDataField {
  final String id;
  final String label;
  final String fieldType;
  final String? unit;
  final String? autoFillFromLab;

  const TemplateDataField({
    required this.id,
    required this.label,
    required this.fieldType,
    this.unit,
    this.autoFillFromLab,
  });
}

class DiseaseTemplate {
  final dynamic id;
  final String name;
  final String category;
  final String? system;
  final List<TemplateDiagram> diagrams;
  final List<TemplateDataField> dataFields;
  final Map<String, dynamic> details;

  DiseaseTemplate({
    this.id,
    required this.name,
    required this.category,
    this.system,
    this.diagrams = const [],
    this.dataFields = const [],
    Map<String, dynamic>? details,
  }) : details = details ?? {};

  /// Lab test field labels derived from dataFields
  List<String> get requiredLabTests =>
      dataFields.map((f) => f.label).toList();

  /// Empty template for new entries
  factory DiseaseTemplate.empty() => DiseaseTemplate(
    name: '',
    category: '',
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
      id: map['id'],
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      details: map['details'] is String
          ? jsonDecode(map['details'])
          : (map['details'] ?? {}),
    );
  }

  DiseaseTemplate copyWith({
    dynamic id,
    String? name,
    String? category,
    String? system,
    List<TemplateDiagram>? diagrams,
    List<TemplateDataField>? dataFields,
    Map<String, dynamic>? details,
  }) {
    return DiseaseTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      system: system ?? this.system,
      diagrams: diagrams ?? this.diagrams,
      dataFields: dataFields ?? this.dataFields,
      details: details ?? this.details,
    );
  }
}
