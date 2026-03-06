// lib/services/favorites_service.dart
// Persists favorite 3D model IDs using SharedPreferences

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService instance = FavoritesService._();
  FavoritesService._();

  static const _prefKey = 'favorite_model_ids';
  Set<String> _favoriteIds = {};
  bool _loaded = false;

  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _favoriteIds = (prefs.getStringList(_prefKey) ?? []).toSet();
    _loaded = true;
    notifyListeners();
  }

  bool isFavorite(String modelId) => _favoriteIds.contains(modelId);

  Future<void> toggle(String modelId) async {
    if (_favoriteIds.contains(modelId)) {
      _favoriteIds.remove(modelId);
    } else {
      _favoriteIds.add(modelId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _favoriteIds.toList());
  }

  Future<void> add(String modelId) async {
    if (_favoriteIds.contains(modelId)) return;
    _favoriteIds.add(modelId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _favoriteIds.toList());
  }

  Future<void> remove(String modelId) async {
    if (!_favoriteIds.contains(modelId)) return;
    _favoriteIds.remove(modelId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _favoriteIds.toList());
  }
}
