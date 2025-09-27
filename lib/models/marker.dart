class Marker {
  final String id;
  final String type;
  final double x;
  final double y;
  final double size;
  final String label;

  const Marker({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.size,
    required this.label,
  });

  Marker copyWith({
    String? id,
    String? type,
    double? x,
    double? y,
    double? size,
    String? label,
  }) {
    return Marker(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      size: size ?? this.size,
      label: label ?? this.label,
    );
  }
}