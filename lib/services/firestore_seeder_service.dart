// lib/services/firestore_seeder_service.dart
// One-time seeder: populates the Firestore `model_catalog` collection by
// joining Model3DService (download URLs) with Model3DConfig (rich metadata).
// Safe to re-run — skips documents that already exist.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_3d_service.dart';
import '../config/model_3d_config.dart';

class FirestoreSeederService {
  static final FirestoreSeederService instance = FirestoreSeederService._();
  FirestoreSeederService._();

  /// Build a lookup from modelFileName → Model3DItem so we can grab
  /// description, subcategory, tags etc. for any asset automatically.
  static Map<String, _ConfigMatch> _buildConfigIndex() {
    final index = <String, _ConfigMatch>{};
    for (final category in Model3DConfig.categories) {
      for (final model in category.models) {
        // Primary key: the modelFileName used for downloading
        index[model.modelFileName] = _ConfigMatch(model, category.id);
        // Also index by model id (for cases where asset.id == model.id)
        index[model.id] = _ConfigMatch(model, category.id);
        // Index before/after comparison filenames
        if (model.beforeModelFileName != null) {
          index[model.beforeModelFileName!] = _ConfigMatch(model, category.id);
        }
        if (model.afterModelFileName != null) {
          index[model.afterModelFileName!] = _ConfigMatch(model, category.id);
        }
      }
    }
    return index;
  }

  /// Seed the `model_catalog` collection from the static asset list.
  /// Metadata (description, subcategory, tags) is pulled automatically from
  /// Model3DConfig — no hardcoded maps needed.
  /// Returns the number of new documents created.
  Future<int> seedModelCatalog() async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('model_catalog');
    final now = FieldValue.serverTimestamp();
    final configIndex = _buildConfigIndex();

    int created = 0;

    for (final group in Model3DService.systemAssets) {
      for (final asset in group.assets) {
        // Skip if already exists
        final docRef = collection.doc(asset.id);
        final docSnap = await docRef.get();
        if (docSnap.exists) continue;

        // Try to find rich metadata from Model3DConfig
        final match = configIndex[asset.id];
        final configModel = match?.model;

        // Derive fields — use config when available, fall back to asset info
        final description = configModel?.description ?? asset.name;
        final subcategory = configModel?.subcategory ?? 'General';
        final tags = configModel?.tags ?? <String>[asset.systemId];
        final isAnatomy = tags.contains('anatomy');

        await docRef.set({
          'name': asset.name,
          'categoryId': asset.systemId,
          'subcategory': subcategory,
          'description': description,
          'modelFileName': asset.id,
          'downloadUrl': asset.url,
          'sizeBytes': asset.sizeBytes,
          'tags': tags,
          'isAnatomy': isAnatomy,
          'isPremium': configModel?.isPremium ?? false,
          'isComparisonModel': configModel?.isComparisonModel ?? false,
          if (configModel?.beforeModelFileName != null)
            'beforeModelFileName': configModel!.beforeModelFileName,
          if (configModel?.afterModelFileName != null)
            'afterModelFileName': configModel!.afterModelFileName,
          if (configModel?.beforeLabel != null)
            'beforeLabel': configModel!.beforeLabel,
          if (configModel?.afterLabel != null)
            'afterLabel': configModel!.afterLabel,
          'addedAt': now,
          'updatedAt': now,
        });

        created++;
      }
    }

    return created;
  }

  /// Check if seeding has already been done.
  Future<bool> isCatalogSeeded() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('model_catalog')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}

/// Pairs a Model3DItem with its parent category ID.
class _ConfigMatch {
  final Model3DItem model;
  final String categoryId;
  const _ConfigMatch(this.model, this.categoryId);
}
