import 'package:flutter/material.dart';

class DrawingPath {
  final List<Offset> points; // NOW RELATIVE (0.0-1.0)
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

  // Convert screen coordinates to relative coordinates
  static DrawingPath fromScreenCoordinates({
    required List<Offset> screenPoints,
    required Size canvasSize,
    required double zoom,
    required Offset pan,
    required Color color,
    required double strokeWidth,
  }) {
    final relativePoints = screenPoints.map((screenPoint) {
      // Reverse the zoom/pan transformation
      final adjustedX = screenPoint.dx - pan.dx;
      final adjustedY = screenPoint.dy - pan.dy;

      final canvasX = adjustedX / zoom;
      final canvasY = adjustedY / zoom;

      final relativeX = canvasX / canvasSize.width;
      final relativeY = canvasY / canvasSize.height;

      return Offset(
        relativeX.clamp(0.0, 1.0),
        relativeY.clamp(0.0, 1.0),
      );
    }).toList();

    return DrawingPath(
      points: relativePoints,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  // Convert relative coordinates to screen coordinates for painting
  List<Offset> toScreenCoordinates({
    required Size canvasSize,
    required double zoom,
    required Offset pan,
  }) {
    return points.map((relativePoint) {
      final canvasX = relativePoint.dx * canvasSize.width;
      final canvasY = relativePoint.dy * canvasSize.height;

      final screenX = (canvasX * zoom) + pan.dx;
      final screenY = (canvasY * zoom) + pan.dy;

      return Offset(screenX, screenY);
    }).toList();
  }

  // Check if a tap is near this path
  bool containsPoint(Offset tapPosition, Size canvasSize, double zoom, Offset pan) {
    final screenPoints = toScreenCoordinates(
      canvasSize: canvasSize,
      zoom: zoom,
      pan: pan,
    );

    const hitRadius = 15.0; // Tap tolerance in pixels

    for (int i = 0; i < screenPoints.length - 1; i++) {
      final p1 = screenPoints[i];
      final p2 = screenPoints[i + 1];

      // Distance from point to line segment
      final distance = _distanceToLineSegment(tapPosition, p1, p2);
      if (distance <= hitRadius) {
        return true;
      }
    }
    return false;
  }

  double _distanceToLineSegment(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    if (dx == 0 && dy == 0) {
      return (point - start).distance;
    }

    final t = ((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) /
        (dx * dx + dy * dy);

    if (t < 0) {
      return (point - start).distance;
    } else if (t > 1) {
      return (point - end).distance;
    } else {
      final projection = Offset(start.dx + t * dx, start.dy + t * dy);
      return (point - projection).distance;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }

  factory DrawingPath.fromMap(Map<String, dynamic> map) {
    final pointsList = map['points'] as List;
    return DrawingPath(
      points: pointsList.map((p) => Offset(p['dx'] as double, p['dy'] as double)).toList(),
      color: Color(map['color'] as int),
      strokeWidth: map['strokeWidth'] as double,
    );
  }
}