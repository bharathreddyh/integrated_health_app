// lib/screens/medical_templates/system_disease_categories_screen.dart

import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../config/medical_systems_config.dart';
import '../endocrine/thyroid_disease_module_screen.dart';

class SystemDiseaseCategoriesScreen extends StatefulWidget {
  final Patient patient;
  final MedicalSystemConfig system;
  final bool isQuickMode;

  const SystemDiseaseCategoriesScreen({
    super.key,
    required this.patient,
    required this.system,
    this.isQuickMode = false,
  });

  @override
  State<SystemDiseaseCategoriesScreen> createState() =>
      _SystemDiseaseCategoriesScreenState();
}

class _SystemDiseaseCategoriesScreenState
    extends State<SystemDiseaseCategoriesScreen> {
  final _searchController = TextEditingController();
  List<DiseaseCategory> _filteredCategories = [];
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.system.categories;
    // Expand all by default for better UX
    for (var category in widget.system.categories) {
      _expandedCategories.add(category.id);
    }
  }

  void _filterDiseases(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = widget.system.categories;
      } else {
        final queryLower = query.toLowerCase();
        _filteredCategories = widget.system.categories
            .where((category) {
          // Match category name
          if (category.name.toLowerCase().contains(queryLower)) {
            return true;
          }
          // Match any disease in category
          return category.diseases
              .any((disease) => disease.toLowerCase().contains(queryLower));
        })
            .map((category) {
          // If searching, only show matching diseases
          if (category.name.toLowerCase().contains(queryLower)) {
            return category; // Show all diseases if category matches
          } else {
            // Filter diseases
            final matchingDiseases = category.diseases
                .where((disease) =>
                disease.toLowerCase().contains(queryLower))
                .toList();
            return DiseaseCategory(
              id: category.id,
              name: category.name,
              icon: category.icon,
              diseases: matchingDiseases,
            );
          }
        })
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(widget.system.icon, size: 24),
            const SizedBox(width: 12),
            Text(widget.system.name),
          ],
        ),
        backgroundColor: widget.system.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Patient Info Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isQuickMode
                  ? Colors.orange.shade50
                  : widget.system.color.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: widget.isQuickMode
                      ? Colors.orange.shade200
                      : widget.system.color.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.isQuickMode
                      ? Colors.orange.shade700
                      : widget.system.color,
                  child: Icon(
                    widget.isQuickMode ? Icons.flash_on : Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.system.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Persistent Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterDiseases,
              decoration: InputDecoration(
                hintText: 'Search conditions or diseases...',
                prefixIcon: Icon(Icons.search, color: widget.system.color),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterDiseases('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.system.color, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // Disease Categories List
          Expanded(
            child: _filteredCategories.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conditions found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                final isExpanded = _expandedCategories.contains(category.id);
                return _buildCategoryCard(category, isExpanded);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(DiseaseCategory category, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedCategories.remove(category.id);
                  } else {
                    _expandedCategories.add(category.id);
                  }
                });
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.system.color.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.system.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        category.icon,
                        color: widget.system.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${category.diseases.length} conditions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: widget.system.color,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Disease List
          if (isExpanded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: category.diseases.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final disease = category.diseases[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.system.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.system.color,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    disease,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _openDiseaseModule(disease, category.name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.system.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openDiseaseModule(String diseaseName, String categoryName) {
    if (widget.system.id == 'endocrine') {
      // Convert disease name to ID (lowercase, replace spaces with underscores)
      final diseaseId = diseaseName
          .toLowerCase()
          .replaceAll('\'', '')
          .replaceAll(' ', '_');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ThyroidDiseaseModuleScreen(
            patientId: widget.patient.id,
            patientName: widget.patient.name,
            diseaseId: diseaseId,
            diseaseName: diseaseName,
            isQuickMode: widget.isQuickMode, // ✅ Now this works!
          ),
        ),
      );
    } else {
      // Placeholder for other systems
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$diseaseName module coming soon!'),
          backgroundColor: widget.system.color,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}