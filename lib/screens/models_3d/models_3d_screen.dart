// lib/screens/models_3d/models_3d_screen.dart
// Main 3D Models browser - Inspired by Complete Anatomy, Visible Body, 3D4Medical
// Features: System-based organization, search, visual cards

import 'package:flutter/material.dart';
import '../../config/model_3d_config.dart';
import 'model_category_screen.dart';

class Models3DScreen extends StatefulWidget {
  const Models3DScreen({super.key});

  @override
  State<Models3DScreen> createState() => _Models3DScreenState();
}

class _Models3DScreenState extends State<Models3DScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = Model3DConfig.getAllCategories();
    final searchResults = _searchQuery.isNotEmpty
        ? Model3DConfig.searchModels(_searchQuery)
        : <Model3DItem>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
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
                              const Text(
                                '3D Anatomy Models',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${Model3DConfig.totalModelCount} interactive models',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 3D Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.view_in_ar_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isSearching
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF334155),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        onTap: () => setState(() => _isSearching = true),
                        onEditingComplete: () {
                          setState(() => _isSearching = false);
                          FocusScope.of(context).unfocus();
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search models by name, system, or condition...',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          prefixIcon: Icon(
                            Icons.search,
                            color: _isSearching
                                ? const Color(0xFF8B5CF6)
                                : Colors.grey.shade600,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content: Search Results or Categories
            if (_searchQuery.isNotEmpty)
              _buildSearchResults(searchResults)
            else
              _buildCategoryGrid(categories),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<Model3DItem> results) {
    if (results.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                'No models found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${results.length} result${results.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              );
            }
            final model = results[index - 1];
            return _buildSearchResultItem(model);
          },
          childCount: results.length + 1,
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(Model3DItem model) {
    // Find the category this model belongs to
    final category = Model3DConfig.categories.firstWhere(
      (c) => c.models.any((m) => m.id == model.id),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openModelViewer(model, category.id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                // 3D Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.view_in_ar_rounded,
                      color: category.color,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: category.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<Model3DCategory> categories) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category);
          },
          childCount: categories.length,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Model3DCategory category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCategoryScreen(category),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Stack(
            children: [
              // Background Gradient
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        category.color.withOpacity(0.3),
                        category.color.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon & Count Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            category.icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${category.modelCount}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: category.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Text(
                      category.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // View Models Button
                    Row(
                      children: [
                        Text(
                          'View models',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: category.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: category.color,
                        ),
                      ],
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

  void _openCategoryScreen(Model3DCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelCategoryScreen(category: category),
      ),
    );
  }

  void _openModelViewer(Model3DItem model, String systemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelCategoryScreen(
          category: Model3DConfig.getCategoryById(systemId)!,
          initialModelId: model.id,
        ),
      ),
    );
  }
}
