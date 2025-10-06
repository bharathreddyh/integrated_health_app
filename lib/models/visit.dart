import 'dart:convert';
import 'marker.dart';
import 'drawing_path.dart';

class Visit {
  final int? id;
  final String patientId;
  final String diagramType;
  final List<Marker> markers;
  final List<DrawingPath> drawingPaths; // NEW
  final String? notes;
  final DateTime createdAt;

  const Visit({
    this.id,
    required this.patientId,
    required this.diagramType,
    required this.markers,
    this.drawingPaths = const [], // NEW
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'diagram_type': diagramType,
      'markers': jsonEncode(markers.map((m) => m.toMap()).toList()),
      'drawing_paths': jsonEncode(drawingPaths.map((d) => d.toMap()).toList()), // NEW
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    final markersJson = map['markers'] as String;
    final markersList = jsonDecode(markersJson) as List;

    List<DrawingPath> paths = [];
    if (map['drawing_paths'] != null) { // NEW
      final pathsJson = map['drawing_paths'] as String;
      final pathsList = jsonDecode(pathsJson) as List;
      paths = pathsList.map((p) => DrawingPath.fromMap(p as Map<String, dynamic>)).toList();
    }

    return Visit(
      id: map['id'] as int?,
      patientId: map['patient_id'] as String,
      diagramType: map['diagram_type'] as String,
      markers: markersList.map((m) => Marker.fromMap(m as Map<String, dynamic>)).toList(),
      drawingPaths: paths, // NEW
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}