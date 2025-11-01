// lib/screens/medical_templates/system_disease_categories_screen.dart

import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../config/medical_systems_config.dart';
import '../endocrine/thyroid_disease_module_screen.dart';

class SystemDiseaseCategoriesScreen extends StatefulWidget {
  final Patient patient;
  final MedicalSystemConfig system;
  final bool isQuickMode;
  final String? initialSearchQuery; // NEW: Optional initial search to highlight specific disease

  const SystemDiseaseCategoriesScreen({
    super.key,
    required this.patient,
    required this.system,
    this.isQuickMode = false,
    this.initialSearchQuery, // NEW parameter
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

    // NEW: If there's an initial search query, set it and expand relevant categories
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
      _filterDiseases(widget.initialSearchQuery!);

      // Expand categories that contain the searched disease
      for (var category in widget.system.categories) {
        for (var disease in category.diseases) {
          if (disease.toLowerCase().contains(widget.initialSearchQuery!.toLowerCase())) {
            _expandedCategories.add(category.id);
            break;
          }
        }
      }
    } else {
      // Expand all by default for better UX when no search
      for (var category in widget.system.categories) {
        _expandedCategories.add(category.id);
      }
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
                .where((disease) => disease.toLowerCase().contains(queryLower))
                .toList();

            if (matchingDiseases.isEmpty) {
              return category;
            }

            // Return category with filtered diseases
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
        title: Text(widget.system.name),
        backgroundColor: widget.system.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Patient Info Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.system.color.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: widget.system.color.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: widget.isQuickMode
                      ? Colors.orange
                      : widget.system.color,
                  child: Icon(
                    widget.isQuickMode ? Icons.flash_on : Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isQuickMode
                            ? 'Temporary assessment'
                            : widget.patient.age > 0
                            ? '${widget.patient.age} years • ${widget.patient.id}'
                            : widget.patient.id,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.all(20),
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
                hintText: 'Search diseases in ${widget.system.name}...',
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
                    'No diseases found',
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
                return _buildCategoryCard(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(DiseaseCategory category) {
    final isExpanded = _expandedCategories.contains(category.id);
    final queryLower = _searchController.text.toLowerCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Category Header
          InkWell(
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
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    category.icon,
                    color: widget.system.color,
                    size: 24,
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
                            color: Color(0xFF1E293B),
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

          // Disease List
          if (isExpanded)
            Column(
              children: category.diseases.map((disease) {
                // NEW: Highlight the disease if it matches the search query
                final isHighlighted = queryLower.isNotEmpty &&
                    disease.toLowerCase().contains(queryLower);

                return Container(
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? widget.system.color.withOpacity(0.1)
                        : null,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: ListTile(
                    onTap: () {
                      // Navigate to disease template
                      // For now, only thyroid diseases have implementation
                      if (widget.system.id == 'endocrine' &&
                          category.id == 'thyroid') {
                        // Convert disease name to ID format
                        final diseaseId = disease
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
                              diseaseName: disease,
                              isQuickMode: widget.isQuickMode,
                            ),
                          ),
                        );
                      } else {
                        // Show coming soon dialog for other systems
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(disease),
                            content: const Text(
                              'This disease template is coming soon!\n\n'
                                  'Currently, only Endocrine > Thyroid disorders are fully implemented.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? widget.system.color.withOpacity(0.2)
                            : widget.system.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.medical_information,
                        size: 20,
                        color: widget.system.color,
                      ),
                    ),
                    title: Text(
                      disease,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}