import 'package:flutter/material.dart';
import '../../models/organ_system.dart';
import 'widgets/organ_tile.dart';
import '../kidney/kidney_screen.dart';
import '../kidney/kidney_screen.dart';  // This import is crucial


class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final organSystems = [
      const OrganSystem(
        id: 'kidney',
        name: 'Urinary System',
        subtitle: 'Kidneys, Bladder, Ureters',
        description: 'Interactive kidney diagrams for patient education',
        icon: Icons.water_drop,
        color: Color(0xFF3B82F6),
        implemented: true,
      ),
      const OrganSystem(
        id: 'cardiovascular',
        name: 'Cardiovascular System',
        subtitle: 'Heart, Blood Vessels',
        description: 'Heart and circulatory system diagrams',
        icon: Icons.favorite,
        color: Color(0xFFEF4444),
        implemented: false,
      ),
      const OrganSystem(
        id: 'respiratory',
        name: 'Respiratory System',
        subtitle: 'Lungs, Airways, Bronchi',
        description: 'Lung and breathing system diagrams',
        icon: Icons.air,
        color: Color(0xFF10B981),
        implemented: false,
      ),
      const OrganSystem(
        id: 'nervous',
        name: 'Nervous System',
        subtitle: 'Brain, Spinal Cord, Nerves',
        description: 'Neurological system diagrams',
        icon: Icons.psychology,
        color: Color(0xFF8B5CF6),
        implemented: false,
      ),
      const OrganSystem(
        id: 'musculoskeletal',
        name: 'Musculoskeletal System',
        subtitle: 'Bones, Joints, Muscles',
        description: 'Bone and muscle system diagrams',
        icon: Icons.accessibility_new,
        color: Color(0xFFF59E0B),
        implemented: false,
      ),
      const OrganSystem(
        id: 'ophthalmic',
        name: 'Ophthalmic System',
        subtitle: 'Eyes, Vision, Retina',
        description: 'Eye and vision system diagrams',
        icon: Icons.visibility,
        color: Color(0xFF6366F1),
        implemented: false,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF),
              Color(0xFFE0E7FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: const Column(
                  children: [
                    Text(
                      'IHA',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Integrated health app for patient education and consultation',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select an Organ System',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose from our comprehensive collection of medical diagrams to help explain conditions to your patients.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Organ System Grid
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: organSystems.length,
                          itemBuilder: (context, index) {
                            final organSystem = organSystems[index];
                            return OrganTile(
                              organSystem: organSystem,
                              onTap: () => _handleOrganTap(context, organSystem),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleOrganTap(BuildContext context, OrganSystem organSystem) {
    if (organSystem.id == 'kidney') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KidneyScreen (), // ← Removed 'const'
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${organSystem.name} coming soon!')),
      );
    }
  }}
