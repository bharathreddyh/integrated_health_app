// lib/services/firestore_seeder_service.dart
// One-time seeder: populates the Firestore `model_catalog` collection from
// the static asset list in Model3DService. Run once, then never again.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_3d_service.dart';

class FirestoreSeederService {
  static final FirestoreSeederService instance = FirestoreSeederService._();
  FirestoreSeederService._();

  /// Seed the `model_catalog` collection from the static asset list.
  /// Skips documents that already exist (safe to run multiple times).
  /// Returns the number of new documents created.
  Future<int> seedModelCatalog() async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('model_catalog');
    final now = FieldValue.serverTimestamp();

    // Subcategory mapping based on model_3d_config.dart
    final subcategoryMap = {
      'uterus': 'Normal Anatomy',
      'fibroid_cervical': 'Fibroids',
      'fibroid_subserosal': 'Fibroids',
      'fibroid_submucosal': 'Fibroids',
      'fibroid_intramural': 'Fibroids',
      'uterus_fibroid_compression_before': 'Fibroids',
      'uterus_fibroid_compression_after': 'Fibroids',
      'uterus_endo_polyp': 'Endometrium',
      'uterus_endo_hyperplasia': 'Endometrium',
      'uterus_endo_ca': 'Endometrium',
      'uterus_endo_normal': 'Endometrium',
    };

    final descriptionMap = {
      'uterus': 'Normal uterine anatomy showing myometrium, endometrium, and cervix',
      'fibroid_cervical': 'Fibroid located in the cervical region',
      'fibroid_subserosal': 'Fibroid projecting outward from the uterine surface',
      'fibroid_submucosal': 'Fibroid projecting into the uterine cavity',
      'fibroid_intramural': 'Fibroid within the muscular wall of the uterus',
      'uterus_fibroid_compression_before': 'Fibroid compression effects on bladder and rectum (Before)',
      'uterus_fibroid_compression_after': 'Fibroid compression effects on bladder and rectum (After)',
      'uterus_endo_polyp': 'Polypoid growth from the endometrium',
      'uterus_endo_hyperplasia': 'Thickened endometrial lining',
      'uterus_endo_ca': 'Malignant tumor of the endometrium',
      'uterus_endo_normal': 'Normal endometrial lining of the uterus',
    };

    final tagsMap = {
      'uterus': ['anatomy', 'normal', 'uterus'],
      'fibroid_cervical': ['pathology', 'fibroid', 'cervix'],
      'fibroid_subserosal': ['pathology', 'fibroid', 'uterus'],
      'fibroid_submucosal': ['pathology', 'fibroid', 'uterus'],
      'fibroid_intramural': ['pathology', 'fibroid', 'uterus'],
      'uterus_fibroid_compression_before': ['pathology', 'fibroid', 'uterus', 'compression'],
      'uterus_fibroid_compression_after': ['pathology', 'fibroid', 'uterus', 'compression'],
      'uterus_endo_polyp': ['pathology', 'polyp', 'endometrium'],
      'uterus_endo_hyperplasia': ['pathology', 'endometrium', 'hyperplasia'],
      'uterus_endo_ca': ['pathology', 'cancer', 'endometrium'],
      'uterus_endo_normal': ['anatomy', 'normal', 'endometrium'],
    };

    int created = 0;

    // Get all asset groups from the static config
    final groups = Model3DService.systemAssets;

    for (final group in groups) {
      for (final asset in group.assets) {
        // Check if document already exists
        final docRef = collection.doc(asset.id);
        final docSnap = await docRef.get();
        if (docSnap.exists) continue;

        await docRef.set({
          'name': asset.name,
          'categoryId': asset.systemId,
          'subcategory': subcategoryMap[asset.id] ?? 'General',
          'description': descriptionMap[asset.id] ?? asset.name,
          'modelFileName': asset.id,
          'downloadUrl': asset.url,
          'sizeBytes': asset.sizeBytes,
          'tags': tagsMap[asset.id] ?? [asset.systemId],
          'isAnatomy': (tagsMap[asset.id] ?? []).contains('anatomy'),
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
