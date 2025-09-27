import 'package:flutter/material.dart';
import '../../../models/organ_system.dart';

class OrganTile extends StatelessWidget {
  final OrganSystem organSystem;
  final VoidCallback onTap;

  const OrganTile({
    super.key,
    required this.organSystem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: organSystem.implemented ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced from 20 to 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge and icon row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48, // Reduced from 64
                    height: 48, // Reduced from 64
                    decoration: BoxDecoration(
                      color: organSystem.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      organSystem.icon,
                      color: Colors.white,
                      size: 24, // Reduced from 32
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, // Reduced from 8
                      vertical: 3,   // Reduced from 4
                    ),
                    decoration: BoxDecoration(
                      color: organSystem.implemented
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8), // Reduced from 12
                    ),
                    child: Text(
                      organSystem.implemented ? 'Available' : 'Coming Soon',
                      style: TextStyle(
                        fontSize: 9, // Reduced from 10
                        fontWeight: FontWeight.w500,
                        color: organSystem.implemented
                            ? Colors.green.shade800
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // Reduced from 16

              // Title
              Text(
                organSystem.name,
                style: const TextStyle(
                  fontSize: 16, // Reduced from 18
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2, // Allow 2 lines for long titles
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                organSystem.subtitle,
                style: TextStyle(
                  fontSize: 11, // Reduced from 12
                  color: Colors.grey.shade600,
                ),
                maxLines: 2, // Allow 2 lines
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(), // Push description to bottom

              // Description
              Text(
                organSystem.description,
                style: TextStyle(
                  fontSize: 10, // Reduced from 12
                  color: Colors.grey.shade500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}