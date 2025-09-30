import 'package:flutter/material.dart';

class MedicalCondition {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int todayCount;
  final int totalCount;

  const MedicalCondition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.todayCount,
    required this.totalCount,
  });
}