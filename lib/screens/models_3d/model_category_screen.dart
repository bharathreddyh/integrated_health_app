// lib/screens/models_3d/model_category_screen.dart
// Displays all 3D models within a specific anatomical system category
// Features: Grid view, model cards, quick launch to viewer

import 'package:flutter/material.dart';
import '../../config/model_3d_config.dart';
import '../model_viewer_screen.dart';

class ModelCategoryScreen extends StatefulWidget {
  final Model3DCategory category;
  final String? initialModelId;

  const ModelCategoryScreen({
    super.key,
    required this.category,
    this.initialModelId,
  });

  @override
  State<ModelCategoryScreen> createState() => _ModelCategoryScreenState();
}

class _ModelCategoryScreenState extends State<ModelCategoryScreen> {
  String _selectedFilter = 'all';
  late List<Model3DItem> _filteredModels;

  @override
  void initState() {
    super.initState();
    _filteredModels = widget.category.models;

    // If initial model specified, open it immediately
    if (widget.initialModelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final model = widget.category.models.firstWhere(
          (m) => m.id == widget.initialModelId,
          orElse: () => widget.category.models.first,
        );
        _openModelViewer(model);
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'all') {
        _filteredModels = widget.category.models;
      } else {
        _filteredModels = widget.category.models
            .where((m) => m.tags.contains(filter))
            .toList();
      }
    });
  }

  Set<String> _getAvailableTags() {
    final tags = <String>{};
    for (final model in widget.category.models) {
      tags.addAll(model.tags);
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final availableTags = _getAvailableTags();
    final hasPathology = availableTags.contains('pathology');
    final hasAnatomy = availableTags.contains('anatomy');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back & Title Row
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.category.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.category.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.category.modelCount} 3D models available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All', null),
                        if (hasAnatomy)
                          _buildFilterChip('anatomy', 'Normal Anatomy', Icons.check_circle_outline),
                        if (hasPathology)
                          _buildFilterChip('pathology', 'Pathology', Icons.medical_services_outlined),
                        // Add specific pathology filters
                        if (availableTags.contains('fibroid'))
                          _buildFilterChip('fibroid', 'Fibroids', null),
                        if (availableTags.contains('cyst'))
                          _buildFilterChip('cyst', 'Cysts', null),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Models Grid
            Expanded(
              child: _filteredModels.isEmpty
                  ? _buildEmptyState()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _filteredModels.length,
                        itemBuilder: (context, index) {
                          return _buildModelCard(_filteredModels[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData? icon) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _applyFilter(value),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.category.color
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? widget.category.color
                    : const Color(0xFF334155),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.view_in_ar_outlined,
            size: 64,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'No models in this filter',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _applyFilter('all'),
            child: Text(
              'Show all models',
              style: TextStyle(color: widget.category.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(Model3DItem model) {
    final isPathology = model.tags.contains('pathology');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openModelViewer(model),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Stack(
            children: [
              // Background gradient
              Positioned(
                bottom: -40,
                left: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.category.color.withOpacity(0.2),
                        widget.category.color.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isPathology
                                ? Colors.red.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPathology ? 'Pathology' : 'Anatomy',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isPathology
                                  ? Colors.red.shade400
                                  : Colors.green.shade400,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.view_in_ar_rounded,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),

                    const Spacer(),

                    // 3D Preview Placeholder
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: widget.category.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.view_in_ar_rounded,
                          size: 40,
                          color: widget.category.color,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Model Name
                    Text(
                      model.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Text(
                      model.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // View Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.category.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 18,
                            color: widget.category.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'View 3D',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.category.color,
                            ),
                          ),
                        ],
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

  void _openModelViewer(Model3DItem model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelViewerScreen(
          modelName: model.modelFileName,
          title: model.name,
          systemId: widget.category.id,
        ),
      ),
    );
  }
}
