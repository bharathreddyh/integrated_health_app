import 'package:flutter/material.dart';

class DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  DrawingPath copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
  }) {
    return DrawingPath(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}