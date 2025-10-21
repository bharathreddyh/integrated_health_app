// ==================== THYROID NAVIGATION SCREENS ====================
// lib/screens/endocrine/thyroid_category_selection_screen.dart

import 'package:flutter/material.dart';
import '../../config/thyroid_disease_config.dart';
import 'thyroid_disease_selection_screen.dart';

class ThyroidCategorySelectionScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const ThyroidCategorySelectionScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thyroid Conditions'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Patient Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF2563EB), const Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🦋 THYROID GLAND',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Patient: $patientName',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select a condition category',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),

          // Category Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: ThyroidDiseaseConfig.categories.length,
                itemBuilder: (context, index) {
                  final category = ThyroidDiseaseConfig.categories[index];
                  return _buildCategoryCard(context, category);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, String> category) {
    final categoryId = category['id']!;
    final categoryName = category['name']!;
    final icon = category['icon']!;

    // Count diseases in this category
    final diseaseCount = ThyroidDiseaseConfig.getDiseasesForCategory(categoryId).length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThyroidDiseaseSelectionScreen(
                patientId: patientId,
                patientName: patientName,
                category: categoryId,
                categoryName: categoryName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$diseaseCount conditions',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ==================== DISEASE SELECTION SCREEN ====================
// lib/screens/endocrine/thyroid_disease_selection_screen.dart

class ThyroidDiseaseSelectionScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  final String category;
  final String categoryName;

  const ThyroidDiseaseSelectionScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.category,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final diseases = ThyroidDiseaseConfig.getDiseasesForCategory(category);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF2563EB).withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select specific condition',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient: $patientName',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Disease List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: diseases.length,
              itemBuilder: (context, index) {
                final disease = diseases[index];
                return _buildDiseaseCard(context, disease);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(BuildContext context, Map<String, String> disease) {
    final diseaseId = disease['id']!;
    final diseaseName = disease['name']!;
    final config = ThyroidDiseaseConfig.getDiseaseConfig(diseaseId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to the 4-tab disease module
          _openDiseaseModule(context, diseaseId, diseaseName);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diseaseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (config != null && config['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        config['description'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (config != null && config['icd10'] != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ICD-10: ${config['icd10']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDiseaseModule(BuildContext context, String diseaseId, String diseaseName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThyroidDiseaseModuleScreen(
          patientId: widget.patientId,
          patientName: widget.patientName, // ✅ Pass patient name
          diseaseId: diseaseId,
          diseaseName: diseaseName,
          isQuickMode: false,
        ),
      ),
    );
  }
}