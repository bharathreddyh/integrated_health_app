// lib/screens/models_3d/model_category_screen.dart
// Displays all 3D models within a specific anatomical system category
// Features: Grid view, model cards, quick launch to viewer, comparison mode

import 'package:flutter/material.dart';
import '../../config/model_3d_config.dart';
import '../../widgets/model_thumbnail_widget.dart';
import '../model_viewer_screen.dart';
import 'model_compare_screen.dart';

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

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Compare mode
  bool _compareMode = false;
  final List<Model3DItem> _selectedForCompare = [];

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleCompareMode() {
    setState(() {
      _compareMode = !_compareMode;
      if (!_compareMode) {
        _selectedForCompare.clear();
      }
    });
  }

  void _toggleModelSelection(Model3DItem model) {
    setState(() {
      if (_selectedForCompare.contains(model)) {
        _selectedForCompare.remove(model);
      } else if (_selectedForCompare.length < 2) {
        _selectedForCompare.add(model);
      }
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _updateFilteredModels();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _updateFilteredModels();
    });
  }

  void _updateFilteredModels() {
    var models = widget.category.models.toList();

    // Apply tag filter
    if (_selectedFilter != 'all') {
      models = models.where((m) => m.tags.contains(_selectedFilter)).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      models = models.where((m) {
        return m.name.toLowerCase().contains(_searchQuery) ||
            m.description.toLowerCase().contains(_searchQuery) ||
            m.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    _filteredModels = models;
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
      floatingActionButton: _compareMode && _selectedForCompare.length == 2
          ? FloatingActionButton.extended(
              onPressed: _launchComparison,
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.compare_arrows, color: Colors.white),
              label: const Text(
                'Compare',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
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
                      // Compare button in header
                      if (widget.category.modelCount >= 2)
                        IconButton(
                          onPressed: _toggleCompareMode,
                          icon: Icon(
                            _compareMode ? Icons.close : Icons.compare_arrows,
                            color: _compareMode
                                ? Colors.orange
                                : Colors.grey.shade400,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _compareMode
                                ? Colors.orange.withOpacity(0.15)
                                : const Color(0xFF1E293B),
                          ),
                          tooltip: _compareMode ? 'Exit compare' : 'Compare models',
                        ),
                    ],
                  ),

                  // Compare mode banner
                  if (_compareMode) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.compare_arrows,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedForCompare.isEmpty
                                  ? 'Select 2 models to compare'
                                  : _selectedForCompare.length == 1
                                      ? '1 selected - pick one more'
                                      : '2 models selected',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_selectedForCompare.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() => _selectedForCompare.clear());
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search models...',
                        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: Colors.grey.shade500, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
    final isSearching = _searchQuery.isNotEmpty;
    final isFiltering = _selectedFilter != 'all';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.view_in_ar_outlined,
            size: 64,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'No results for "$_searchQuery"'
                : 'No models in this filter',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          if (isSearching || isFiltering)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'all';
                  _updateFilteredModels();
                });
              },
              child: Text(
                'Clear filters',
                style: TextStyle(color: widget.category.color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelCard(Model3DItem model) {
    final isPathology = model.tags.contains('pathology');
    final isSelected = _selectedForCompare.contains(model);
    final selectionIndex = _selectedForCompare.indexOf(model) + 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_compareMode) {
            _toggleModelSelection(model);
          } else {
            _openModelViewer(model);
          }
        },
        onLongPress: () {
          if (!_compareMode && widget.category.modelCount >= 2) {
            setState(() {
              _compareMode = true;
              _selectedForCompare.add(model);
            });
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.orange
                  : const Color(0xFF334155),
              width: isSelected ? 2 : 1,
            ),
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
                        isSelected
                            ? Colors.orange.withOpacity(0.3)
                            : widget.category.color.withOpacity(0.2),
                        widget.category.color.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$selectionIndex',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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

                    // 3D Preview Thumbnail
                    Center(
                      child: ModelThumbnailWidget(
                        modelId: model.modelFileName,
                        accentColor: widget.category.color,
                        size: 80,
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

  void _launchComparison() {
    if (_selectedForCompare.length != 2) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelCompareScreen(
          leftModel: _selectedForCompare[0],
          rightModel: _selectedForCompare[1],
          systemId: widget.category.id,
        ),
      ),
    ).then((_) {
      // Clear selection after returning from comparison
      setState(() {
        _selectedForCompare.clear();
        _compareMode = false;
      });
    });
  }
}
