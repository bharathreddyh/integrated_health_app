import 'package:flutter/material.dart';

class OrganSystem {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final bool implemented;

  const OrganSystem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.implemented = false,
  });
}