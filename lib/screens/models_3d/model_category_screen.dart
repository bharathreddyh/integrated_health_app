// lib/screens/models_3d/model_category_screen.dart
// Displays all 3D models within a specific anatomical system category
// Features: Grid view, model cards, quick launch to viewer, comparison mode

import 'package:flutter/material.dart';
import '../../config/model_3d_config.dart';
import '../../services/favorites_service.dart';
import '../../services/model_3d_service.dart';
import '../../services/model_catalog_service.dart';
import '../model_viewer_screen.dart';
import 'model_compare_screen.dart';
import 'model_before_after_screen.dart';

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
    FavoritesService.instance.load();
    _loadRemoteCatalog();

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
    final isObstetric = widget.category.id == 'obstetric';

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    const SizedBox(height: 8),
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

                  const SizedBox(height: 8),

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

                  const SizedBox(height: 8),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All', null),
                        if (hasAnatomy)
                          _buildFilterChip('anatomy', isObstetric ? 'Normal' : 'Normal Anatomy', Icons.check_circle_outline),
                        if (hasPathology)
                          _buildFilterChip('pathology', isObstetric ? 'Abnormal' : 'Pathology', Icons.medical_services_outlined),
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

            // Models Grid with subheadings
            Expanded(
              child: _filteredModels.isEmpty
                  ? _buildEmptyState()
                  : _buildGroupedModelsList(),
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

  Widget _buildGroupedModelsList() {
    // Group models by subcategory
    final Map<String?, List<Model3DItem>> groupedModels = {};

    // Define the order of subcategories
    const subcategoryOrder = ['Fibroids', 'Mullerian Anomaly', 'Ovary', 'Ovulation', 'Endometrium', 'Fetal Lie', 'Fetal Presentation', 'Amniotic Fluid', 'Placenta Previa', 'Placental Abruption', 'Twin Pregnancy', 'Ectopic Pregnancy', 'Placental Pathology', 'Loop of Cord'];

    for (final model in _filteredModels) {
      final key = model.subcategory;
      if (!groupedModels.containsKey(key)) {
        groupedModels[key] = [];
      }
      groupedModels[key]!.add(model);
    }

    // Build ordered list of subcategories
    final orderedSubcategories = <String?>[];

    // First add models without subcategory (general/anatomy)
    if (groupedModels.containsKey(null)) {
      orderedSubcategories.add(null);
    }

    // Then add subcategories in specified order
    for (final subcategory in subcategoryOrder) {
      if (groupedModels.containsKey(subcategory)) {
        orderedSubcategories.add(subcategory);
      }
    }

    // Add any remaining subcategories not in the order list
    for (final key in groupedModels.keys) {
      if (!orderedSubcategories.contains(key)) {
        orderedSubcategories.add(key);
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: orderedSubcategories.length,
      itemBuilder: (context, index) {
        final subcategory = orderedSubcategories[index];
        final models = groupedModels[subcategory]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subheading (only if subcategory is not null)
            if (subcategory != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: widget.category.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      subcategory,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${models.length})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (index == 0) ...[
              const SizedBox(height: 8),
            ],
            // Grid of models in this subcategory
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemCount: models.length,
              itemBuilder: (context, modelIndex) {
                return _buildModelCard(models[modelIndex]);
              },
            ),
          ],
        );
      },
    );
  }

  /// Cached remote catalog asset IDs for availability checks.
  Set<String>? _remoteCatalogIds;

  Future<void> _loadRemoteCatalog() async {
    final remoteModels = await ModelCatalogService.instance.getAllRemoteModels();
    if (mounted) {
      setState(() {
        _remoteCatalogIds = {
          ...remoteModels.map((m) => m.id),
          ...remoteModels.map((m) => m.modelFileName),
        };
      });
    }
  }

  /// Check if a model has a real uploaded asset (not a placeholder fallback).
  bool _hasUploadedAsset(Model3DItem model) {
    // Check static assets
    final assets = Model3DService.allAssets;
    if (assets.any((a) => a.id == model.id || a.id == model.modelFileName) ||
        assets.any((a) => a.url.contains('${model.modelFileName}.glb'))) {
      return true;
    }
    // Check remote catalog
    final remote = _remoteCatalogIds;
    if (remote != null) {
      return remote.contains(model.id) || remote.contains(model.modelFileName);
    }
    return false;
  }

  Widget _buildModelCard(Model3DItem model) {
    final isPathology = model.tags.contains('pathology');
    final isSelected = _selectedForCompare.contains(model);
    final selectionIndex = _selectedForCompare.indexOf(model) + 1;
    final isComparison = model.isComparisonModel;
    final isFav = FavoritesService.instance.isFavorite(model.id);
    final isAvailable = _hasUploadedAsset(model);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAvailable ? () {
          if (_compareMode) {
            _toggleModelSelection(model);
          } else {
            _openModelViewer(model);
          }
        } : null,
        onLongPress: () {
          if (!_compareMode && widget.category.modelCount >= 2) {
            setState(() {
              _compareMode = true;
              _selectedForCompare.add(model);
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.45,
          child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.orange
                  : isComparison
                      ? Colors.cyan.withOpacity(0.5)
                      : const Color(0xFF334155),
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3D icon with selection/comparison indicator and favorite
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.category.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isComparison
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.view_in_ar_rounded,
                                size: 22,
                                color: widget.category.color.withOpacity(0.7),
                              ),
                              Icon(
                                Icons.view_in_ar_rounded,
                                size: 22,
                                color: widget.category.color,
                              ),
                            ],
                          )
                        : Icon(
                            Icons.view_in_ar_rounded,
                            size: 32,
                            color: widget.category.color,
                          ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 20,
                        height: 20,
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
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Before/After badge for comparison models
                  if (isComparison && !isSelected)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.cyan,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${model.beforeLabel?.substring(0, 1) ?? 'B'}/${model.afterLabel?.substring(0, 1) ?? 'A'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  // Favorite heart icon
                  if (!_compareMode)
                    Positioned(
                      top: -6,
                      left: -6,
                      child: GestureDetector(
                        onTap: () async {
                          await FavoritesService.instance.toggle(model.id);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFav ? Colors.red : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Model Name
              Text(
                model.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              // Type Badge - show "Coming Soon" for unavailable models
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: !isAvailable
                      ? Colors.grey.withOpacity(0.15)
                      : isComparison
                          ? Colors.cyan.withOpacity(0.15)
                          : isPathology
                              ? Colors.red.withOpacity(0.15)
                              : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  !isAvailable
                      ? 'Coming Soon'
                      : isComparison
                          ? '${model.beforeLabel ?? 'Before'}/${model.afterLabel ?? 'After'}'
                          : isPathology
                              ? (widget.category.id == 'obstetric' ? 'Abnormal' : 'Pathology')
                              : (widget.category.id == 'obstetric' ? 'Normal' : 'Anatomy'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: !isAvailable
                        ? Colors.grey
                        : isComparison
                            ? Colors.cyan.shade400
                            : isPathology
                                ? Colors.red.shade400
                                : Colors.green.shade400,
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _openModelViewer(Model3DItem model) {
    // Check if this is a comparison model (before/after)
    if (model.isComparisonModel &&
        model.beforeModelFileName != null &&
        model.afterModelFileName != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ModelBeforeAfterScreen(
            model: model,
            systemId: widget.category.id,
          ),
        ),
      );
    } else {
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
