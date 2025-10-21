// lib/models/visit.dart - UPDATED

import 'dart:convert';
import 'dart:typed_data';
import 'marker.dart';
import 'drawing_path.dart';

class Visit {
  final int? id;
  final String patientId;
  final String system;        // NEW: kidney, cardiac, respiratory, etc.
  final String diagramType;
  final List<Marker> markers;
  final List<DrawingPath> drawingPaths;
  final String? notes;
  final DateTime createdAt;
  final Uint8List? canvasImage;

  const Visit({
    this.id,
    required this.patientId,
    this.system = 'kidney',  // NEW: Default to kidney
    required this.diagramType,
    required this.markers,
    this.drawingPaths = const [],
    this.notes,
    required this.createdAt,
    this.canvasImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'system': system,  // NEW
      'diagram_type': diagramType,
      'markers': jsonEncode(markers.map((m) => m.toMap()).toList()),
      'drawing_paths': jsonEncode(drawingPaths.map((d) => d.toMap()).toList()),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'canvas_image': canvasImage,
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    final markersJson = map['markers'] as String;
    final markersList = jsonDecode(markersJson) as List;

    List<DrawingPath> paths = [];
    if (map['drawing_paths'] != null) {
      final pathsJson = map['drawing_paths'] as String;
      final pathsList = jsonDecode(pathsJson) as List;
      paths = pathsList.map((p) => DrawingPath.fromMap(p as Map<String, dynamic>)).toList();
    }

    return Visit(
      id: map['id'] as int?,
      patientId: map['patient_id'] as String,
      system: map['system'] as String? ?? 'kidney',  // NEW: Default to kidney for old data
      diagramType: map['diagram_type'] as String,
      markers: markersList.map((m) => Marker.fromMap(m as Map<String, dynamic>)).toList(),
      drawingPaths: paths,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      canvasImage: map['canvas_image'] as Uint8List?,
    );
  }

  Visit copyWith({
    int? id,
    String? patientId,
    String? system,
    String? diagramType,
    List<Marker>? markers,
    List<DrawingPath>? drawingPaths,
    String? notes,
    DateTime? createdAt,
    Uint8List? canvasImage,
  }) {
    return Visit(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      system: system ?? this.system,
      diagramType: diagramType ?? this.diagramType,
      markers: markers ?? this.markers,
      drawingPaths: drawingPaths ?? this.drawingPaths,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      canvasImage: canvasImage ?? this.canvasImage,
    );
  }
}

// DATABASE MIGRATION NEEDED:
// Add this to your DatabaseHelper _onUpgrade method:
/*
if (oldVersion < 9) {
  try {
    await db.execute('ALTER TABLE visits ADD COLUMN system TEXT DEFAULT "kidney"');
    print('✅ Added system column to visits table');
  } catch (e) {
    print('system column may already exist: $e');
  }
}
*/

// And update your database version from 8 to 9 in _initDB method