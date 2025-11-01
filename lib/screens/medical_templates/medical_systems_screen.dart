// lib/screens/medical_templates/medical_systems_screen.dart

import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../config/medical_systems_config.dart';
import 'system_disease_categories_screen.dart';

// Search result model to track individual disease matches
class DiseaseSearchResult {
  final String diseaseName;
  final DiseaseCategory category;
  final MedicalSystemConfig system;

  DiseaseSearchResult({
    required this.diseaseName,
    required this.category,
    required this.system,
  });
}

class MedicalSystemsScreen extends StatefulWidget {
  final Patient patient;
  final bool isQuickMode;

  const MedicalSystemsScreen({
    super.key,
    required this.patient,
    this.isQuickMode = false,
  });

  @override
  State<MedicalSystemsScreen> createState() => _MedicalSystemsScreenState();
}

class _MedicalSystemsScreenState extends State<MedicalSystemsScreen> {
  final _searchController = TextEditingController();
  List<MedicalSystemConfig> _filteredSystems = [];
  List<DiseaseSearchResult> _diseaseSearchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredSystems = MedicalSystemsConfig.allSystems;
  }

  void _filterSystems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSystems = MedicalSystemsConfig.allSystems;
        _diseaseSearchResults = [];
        _isSearching = false;
      } else {
        _isSearching = true;
        final queryLower = query.toLowerCase();

        // Clear previous results
        _diseaseSearchResults = [];

        // Search through all systems, categories, and diseases
        for (var system in MedicalSystemsConfig.allSystems) {
          for (var category in system.categories) {
            for (var disease in category.diseases) {
              if (disease.toLowerCase().contains(queryLower)) {
                _diseaseSearchResults.add(
                  DiseaseSearchResult(
                    diseaseName: disease,
                    category: category,
                    system: system,
                  ),
                );
              }
            }
          }
        }

        // Also keep system-level filtering for when no specific diseases match
        _filteredSystems = MedicalSystemsConfig.allSystems.where((system) {
          // Search by system name
          if (system.name.toLowerCase().contains(queryLower)) {
            return true;
          }
          // Search by system description
          if (system.description.toLowerCase().contains(queryLower)) {
            return true;
          }
          return false;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Medical Systems'),
        backgroundColor: const Color(0xFF9333EA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Patient Info Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isQuickMode
                  ? Colors.orange.shade50
                  : Colors.purple.shade50,
              border: Border(
                bottom: BorderSide(
                  color: widget.isQuickMode
                      ? Colors.orange.shade200
                      : Colors.purple.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: widget.isQuickMode
                      ? Colors.orange
                      : const Color(0xFF9333EA),
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
                            ? 'Temporary assessment - Can be saved to patient later'
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

          // Persistent Search Bar
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
              onChanged: _filterSystems,
              decoration: InputDecoration(
                hintText: 'Search systems or diseases...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9333EA)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterSystems('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF9333EA), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // Content Area - Show either disease search results or system grid
          Expanded(
            child: _isSearching && _diseaseSearchResults.isNotEmpty
                ? _buildDiseaseSearchResults()
                : _isSearching && _diseaseSearchResults.isEmpty && _filteredSystems.isEmpty
                ? _buildNoResults()
                : _buildSystemsGrid(),
          ),
        ],
      ),
    );
  }

  // Build individual disease search results
  Widget _buildDiseaseSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _diseaseSearchResults.length,
      itemBuilder: (context, index) {
        final result = _diseaseSearchResults[index];
        return _buildDiseaseSearchResultCard(result);
      },
    );
  }

  Widget _buildDiseaseSearchResultCard(DiseaseSearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate directly to the system's disease categories screen
          // This will show the disease within its category
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SystemDiseaseCategoriesScreen(
                patient: widget.patient,
                system: result.system,
                isQuickMode: widget.isQuickMode,
                initialSearchQuery: result.diseaseName, // Pass the disease name to highlight it
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // System Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.system.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  result.system.icon,
                  color: result.system.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Disease and System Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disease Name (Main result)
                    Text(
                      result.diseaseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category
                    Text(
                      result.category.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // System Name (Parent)
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          result.system.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
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
            'No systems or diseases found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _filteredSystems.length,
      itemBuilder: (context, index) {
        final system = _filteredSystems[index];
        return _buildSystemCard(system);
      },
    );
  }

  Widget _buildSystemCard(MedicalSystemConfig system) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SystemDiseaseCategoriesScreen(
                patient: widget.patient,
                system: system,
                isQuickMode: widget.isQuickMode,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: system.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  system.icon,
                  size: 36,
                  color: system.color,
                ),
              ),
              const SizedBox(height: 12),
              // System Name
              Text(
                system.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              // Description
              Text(
                system.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              // Condition Count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: system.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 14,
                      color: system.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${system.totalDiseaseCount} conditions',
                      style: TextStyle(
                        fontSize: 11,
                        color: system.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}