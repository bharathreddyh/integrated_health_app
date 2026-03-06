// lib/screens/favorites/favorites_screen.dart
// Shows favorited 3D models for quick access

import 'package:flutter/material.dart';
import '../../config/model_3d_config.dart';
import '../../services/favorites_service.dart';
import '../model_viewer_screen.dart';
import '../models_3d/model_before_after_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favService = FavoritesService.instance;

  @override
  void initState() {
    super.initState();
    _favService.load();
    _favService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _favService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  List<_FavoriteModelInfo> _getFavoriteModels() {
    final allModels = Model3DConfig.getAllModels();
    final result = <_FavoriteModelInfo>[];
    for (final model in allModels) {
      if (_favService.isFavorite(model.id)) {
        final category = Model3DConfig.categories.firstWhere(
          (c) => c.models.any((m) => m.id == model.id),
        );
        result.add(_FavoriteModelInfo(model: model, category: category));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _getFavoriteModels();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
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
                          'Favourites',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${favorites.length} saved model${favorites.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: favorites.isEmpty
                  ? _buildEmptyState()
                  : _buildFavoritesList(favorites),
            ),
          ],
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
            Icons.favorite_border_rounded,
            size: 80,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 24),
          Text(
            'No Favourites Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart icon on any 3D model\nto add it to your favourites',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(List<_FavoriteModelInfo> favorites) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final info = favorites[index];
        return _buildFavoriteCard(info);
      },
    );
  }

  Widget _buildFavoriteCard(_FavoriteModelInfo info) {
    final model = info.model;
    final category = info.category;
    final isPathology = model.tags.contains('pathology');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openModel(model, category.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with favorite badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.view_in_ar_rounded,
                      size: 32,
                      color: category.color,
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => _favService.toggle(model.id),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F172A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.red,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              // Category tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPathology
                      ? Colors.red.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
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
            ],
          ),
        ),
      ),
    );
  }

  void _openModel(Model3DItem model, String systemId) {
    if (model.isComparisonModel &&
        model.beforeModelFileName != null &&
        model.afterModelFileName != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ModelBeforeAfterScreen(
            model: model,
            systemId: systemId,
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
            systemId: systemId,
          ),
        ),
      );
    }
  }
}

class _FavoriteModelInfo {
  final Model3DItem model;
  final Model3DCategory category;

  _FavoriteModelInfo({required this.model, required this.category});
}
