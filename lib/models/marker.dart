import 'package:flutter/material.dart';
import 'dart:convert';

class Marker {
  final String type;
  final double x;
  final double y;
  final double size;
  final String label;
  final Color color;

  const Marker({
    required this.type,
    required this.x,
    required this.y,
    required this.size,
    this.label = '',
    required this.color,
  });

  Marker copyWith({
    String? type,
    double? x,
    double? y,
    double? size,
    String? label,
    Color? color,
  }) {
    return Marker(
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      size: size ?? this.size,
      label: label ?? this.label,
      color: color ?? this.color,
    );
  }

  static Marker fromScreenCoordinates({
    required String type,
    required Offset screenPosition,
    required Size canvasSize,
    required double zoom,
    required Offset pan,
    required double size,
    required Color color,
    String label = '',
  }) {
    final adjustedX = screenPosition.dx - pan.dx;
    final adjustedY = screenPosition.dy - pan.dy;

    final canvasX = adjustedX / zoom;
    final canvasY = adjustedY / zoom;

    final relativeX = canvasX / canvasSize.width;
    final relativeY = canvasY / canvasSize.height;

    return Marker(
      type: type,
      x: relativeX.clamp(0.0, 1.0),
      y: relativeY.clamp(0.0, 1.0),
      size: size,
      color: color,
      label: label,
    );
  }

  Offset toScreenCoordinates({
    required Size canvasSize,
    required double zoom,
    required Offset pan,
  }) {
    final canvasX = x * canvasSize.width;
    final canvasY = y * canvasSize.height;

    final screenX = (canvasX * zoom) + pan.dx;
    final screenY = (canvasY * zoom) + pan.dy;

    return Offset(screenX, screenY);
  }

  double getScaledSize(double zoom) {
    return size * zoom;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'x': x,
      'y': y,
      'size': size,
      'label': label,
      'color': color.value,
    };
  }

  factory Marker.fromMap(Map<String, dynamic> map) {
    return Marker(
      type: map['type'] as String,
      x: map['x'] as double,
      y: map['y'] as double,
      size: map['size'] as double,
      label: map['label'] as String? ?? '',
      color: Color(map['color'] as int),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Marker.fromJson(String source) =>
      Marker.fromMap(jsonDecode(source) as Map<String, dynamic>);
}