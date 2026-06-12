// lib/services/model_3d_service.dart
// Downloads 3D models via a Cloud Function that verifies Firebase Auth
// and returns a short-lived signed URL. Direct Storage access is blocked.

import 'package:flutter/material.dart';

import 'dart:convert' as json;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Metadata for a single downloadable asset.
class AssetInfo {
  final String id;
  final String name;
  final String systemId;
  final String url;
  final int sizeBytes; // approximate size in bytes
  final String fileExtension;

  const AssetInfo({
    required this.id,
    required this.name,
    required this.systemId,
    required this.url,
    required this.sizeBytes,
    this.fileExtension = 'glb',
  });

  /// Extract Firebase Storage path from the full URL.
  /// e.g. "https://...firebasestorage.app/o/models%2Ffile.glb?alt=media&token=..."
  ///   → "models/file.glb"
  String get storagePath {
    // Extract the encoded path between "/o/" and "?"
    final oIndex = url.indexOf('/o/');
    final qIndex = url.indexOf('?', oIndex);
    final encoded = url.substring(oIndex + 3, qIndex > 0 ? qIndex : url.length);
    return Uri.decodeComponent(encoded);
  }
}

/// A medical system with its downloadable assets.
class SystemAssetGroup {
  final String systemId;
  final String name;
  final String description;
  final int colorValue;
  final IconData icon;
  final List<AssetInfo> assets;

  const SystemAssetGroup({
    required this.systemId,
    required this.name,
    required this.description,
    required this.colorValue,
    required this.icon,
    required this.assets,
  });

  /// Total download size for this system in bytes.
  int get totalSizeBytes => assets.fold(0, (sum, a) => sum + a.sizeBytes);

  /// Human-readable size string.
  String get formattedSize {
    final mb = totalSizeBytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    final kb = totalSizeBytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }
}

class Model3DService {
  static final Model3DService instance = Model3DService._();
  Model3DService._();

  static const _prefKeySetupDone = 'asset_download_setup_done';

  // ─── Asset Registry ────────────────────────────────────────────────
  // Add new assets here. Sizes are approximate (used for UI display).
  // After uploading a file to Firebase Storage > models/ folder,
  // paste the download URL below.

  static const List<SystemAssetGroup> systemAssets = [
    SystemAssetGroup(
      systemId: 'gynaecology',
      name: 'Gynaecology',
      description: '3D models: Uterus, Fibroids, Ovarian cysts, PCOS',
      colorValue: 0xFFEC4899,
      icon: Icons.favorite,
      assets: [
        AssetInfo(
          id: 'uterus',
          name: '3D Uterus (Normal)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fnormal_uterus_3d.glb?alt=media&token=e709f444-f0ff-461e-bf93-bd5db2685410',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'fibroid_cervical',
          name: '3D Cervical Fibroid',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_cervical_fibroid_3d.glb?alt=media&token=81508b33-7db4-438a-8438-0843d7314235',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'fibroid_subserosal',
          name: '3D Subserosal Fibroid',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_serosal_fibroid_3d.glb?alt=media&token=cf637b60-5825-42ef-aea7-3e62fec7b81c',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'fibroid_submucosal',
          name: '3D Submucosal Fibroid',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_submucosal_fibroid_3d.glb?alt=media&token=906ef034-3a6f-4805-a402-cbac9b550fee',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'fibroid_intramural',
          name: '3D Intramural Fibroid',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_intramural_fibroid_3d.glb?alt=media&token=1b3bf313-0ded-41fd-a1ac-c28a282fb654',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_fibroid_compression_before',
          name: '3D Fibroid Compression (Before)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_fibroid_compression_before.glb?alt=media&token=9ad5e56d-6a54-4161-875a-021920435c03',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_fibroid_compression_after',
          name: '3D Fibroid Compression (After)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_fibroid_compression_after.glb?alt=media&token=92d89ce0-6373-42dd-829d-3b2854ac6837',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_endo_polyp',
          name: '3D Endometrial Polyp',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fendometrium%2Futerus_endo_polyp.glb?alt=media&token=fcd7a18e-c243-4a9a-b9a1-b83f5849dfce',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_endo_hyperplasia',
          name: '3D Endometrial Hyperplasia',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fendometrium%2Futerus_endo_hyperplasia.glb?alt=media&token=fefb97c5-5da0-4731-aee9-3e1c4ce56136',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_endo_ca',
          name: '3D Endometrial Carcinoma',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fendometrium%2Futerus_endo_ca.glb?alt=media&token=1603bb4e-dffa-44b6-a004-edb22b488af9',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_endo_normal',
          name: '3D Normal Endometrium',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fendometrium%2Futerus_endo_normal.glb?alt=media&token=4148b820-41de-4d30-a76e-9b50281d1e37',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_endo_cystic',
          name: '3D Cystic Endometrial Hyperplasia',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fendometrium%2Futerus_endo_cystic.glb?alt=media&token=5e2d4868-e748-45be-9fa6-9e0e9b3b14bc',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_endo_adenoendo',
          name: '3D Adenomyosis & Endometriosis',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fendometrium%2Futerus_endo_adenoendo.glb?alt=media&token=62781751-d574-457a-be4c-70e613c3258c',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'bicornuate_bicollis',
          name: '3D Bicornuate Bicollis',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_mullerian%2FUterus_bicornuate_bicollis.glb?alt=media&token=aff274b0-f478-4a9b-9841-162cc3f797ef',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'bicornuate_unicollis',
          name: '3D Bicornuate Unicollis',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_mullerian%2FUterus_bicornuate_unicollis.glb?alt=media&token=df73fd3f-2640-4c51-90fd-78d3cc015202',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_didelphys',
          name: '3D Uterus Didelphys',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_mullerian%2Futerus_dideplhys.glb?alt=media&token=e656fc30-f447-4b1f-a122-0fe5785564d9',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_subseptate',
          name: '3D Subseptate Uterus',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_mullerian%2Futerus_subseptate.glb?alt=media&token=5bf94329-342d-4a9c-9329-1d25831fff24',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_septate',
          name: '3D Septate Uterus',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_mullerian%2FUterus_septate.glb?alt=media&token=05ca4660-f6bd-4e50-a117-b58c4897619e',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'uterus_unicornuate',
          name: '3D Unicornuate Uterus',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_mullerian%2FUterus_unicornuate.glb?alt=media&token=ce2298e1-8a3d-4bef-a9c5-022fafd6b25a',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'unicornuate_uterus_rudimentary_horn',
          name: '3D Unicornuate Uterus with Rudimentary Horn',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_mullerian%2FUterus_unicornuate_rudiment.glb?alt=media&token=7500ec9f-e198-466f-a407-593e80d23ac0',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'arcuate_uterus',
          name: '3D Arcuate Uterus',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_mullerian%2FUterus_Arcuate.glb?alt=media&token=dfa07528-d3ee-4370-8931-79d05421b910',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'normal_uterus_mullerian',
          name: '3D Normal Uterus (Mullerian)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Futerus_mullerian%2FUterus_Normal.glb?alt=media&token=02eadfdf-5947-402e-8979-cec2084e917d',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'ovary_simple_Cyst',
          name: '3D Simple Ovarian Cyst (View 1)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fgynaec%2Fovary%2Fovary_simple_Cyst.glb?alt=media&token=dbad29c6-b0e2-4b4b-b458-6f60f713c55c',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'ovary_simple_Cyst_2',
          name: '3D Simple Ovarian Cyst (View 2)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fgynaec%2Fovary%2Fovary_simple_Cyst_2.glb?alt=media&token=b3c30838-399a-4fdd-b1ce-106070f1a540',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'ovary_hemorrhagic_cyst_3',
          name: '3D Hemorrhagic Cyst (View 1)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fgynaec%2Fovary%2Fovary_hemorrhagic_cyst_3.glb?alt=media&token=6ce463ea-d4b2-4f00-b719-3bc232c37a61',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'ovary_hemorrhagic_cyst_2',
          name: '3D Hemorrhagic Cyst (View 2)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fgynaec%2Fovary%2Fovary_hemorrhagic_cyst_2.glb?alt=media&token=604166a6-f3b3-4e85-bb7e-0dd9cf9e59cb',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'ovary_dermoid_Cyst_2',
          name: '3D Dermoid Cyst',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fgynaec%2Fovary%2Fovary_dermoid_Cyst_2.glb?alt=media&token=d1a1cb35-3d7f-4f9a-a789-cacb1f2293ea',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'ovary_Polycystic_1',
          name: '3D Polycystic Ovary (View 1)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fgynaec%2Fovary%2Fovary_Polycystic_1.glb?alt=media&token=f8733fb2-f560-4bed-9203-bf0a7f3853b5',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'ovary_Polycystic_2',
          name: '3D Polycystic Ovary (View 2)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fgynaec%2Fovary%2Fovary_Polycystic_2.glb?alt=media&token=7dd354bc-f2b5-4542-a44d-d0e8987ce817',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'Ovary_ovulation_1',
          name: '3D Ovulation (View 1)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fgynaec%2Fovary%2FOvary_ovulation_1.glb?alt=media&token=a7178edb-a189-4a8a-a028-db5a29c9df41',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'Ovary_ovulation_2',
          name: '3D Ovulation (View 2)',
          systemId: 'gynaecology',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fgynaec%2Fovary%2FOvary_ovulation_2.glb?alt=media&token=afffe19e-a2c3-4f32-882a-af92a75825ec',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
      ],
    ),
    SystemAssetGroup(
      systemId: 'obstetric',
      name: 'Obstetric',
      description: '3D models: Fetal Presentation, Fetal Lie, Placenta',
      colorValue: 0xFFE879F9,
      icon: Icons.pregnant_woman,
      assets: [
        AssetInfo(
          id: 'fetal_cephalic',
          name: '3D Cephalic Presentation',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Ffetus_presentation%2Ffetus_present_cephalic.glb?alt=media&token=2bba4a07-77d9-4818-8cca-e53420c67211',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'fetal_breech',
          name: '3D Breech Presentation',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Ffetus_presentation%2Ffetus_present_breech.glb?alt=media&token=cef8e5d0-fab6-41fa-b282-63880ccff3f2',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'fetal_transverse',
          name: '3D Transverse Lie',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Ffetus_presentation%2Ffetus_present_Transverse.glb?alt=media&token=2c18b3a5-d5da-4dae-80c8-96e8b066a75d',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'fetus_present_transverse_2',
          name: 'Transverse Lie Video',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Ffetus_presentation%2Ffetus_present_transverse_2.mp4?alt=media&token=162a4930-76f8-49b9-8979-4ab209133bac',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
          fileExtension: 'mp4',
        ),
        AssetInfo(
          id: 'fetal_oblique',
          name: '3D Oblique Lie',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Ffetus_presentation%2Ffetus_present_oblique.glb?alt=media&token=6b0594af-e0b9-4d43-a3a7-84167617ad1a',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'fetal_cord_loop',
          name: '3D Loop of Cord',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2FFetus_cord_loop%2Ffetal_cord_loop_.glb?alt=media&token=b6d2d533-9cdd-4943-9f70-21f7ab1ae78a',
          sizeBytes: 15 * 1024 * 1024, // ~15 MB
        ),
        AssetInfo(
          id: 'obs_polyhydramnios',
          name: '3D Polyhydramnios',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Fhydramnios%2Fpolyhydramnios.glb?alt=media&token=8df75a0b-5360-4422-a823-ed5d6868575c',
          sizeBytes: 25 * 1024 * 1024, // ~25 MB
        ),
        AssetInfo(
          id: 'obs_oligohydramnios',
          name: '3D Oligohydramnios',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Fhydramnios%2Foligohydramnios.glb?alt=media&token=5090ee6f-e592-4ef8-80e0-5ab7a07093c9',
          sizeBytes: 25 * 1024 * 1024, // ~25 MB
        ),
        AssetInfo(
          id: 'obs_twins_dcda',
          name: '3D DCDA Twins',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Ftwins%2Fobs_twins_dcda.glb?alt=media&token=43920c08-e6c9-46af-8082-5cf85d53d853',
          sizeBytes: 25 * 1024 * 1024,
        ),
        AssetInfo(
          id: 'obs_twins_mcda',
          name: '3D MCDA Twins',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Ftwins%2Fobs_twins_mcda.glb?alt=media&token=51ee384f-f9e1-4f0c-9a87-e1ebed2d7405',
          sizeBytes: 25 * 1024 * 1024,
        ),
        AssetInfo(
          id: 'obs_twins_mcma',
          name: '3D MCMA Twins',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Ftwins%2Fobs_twins_mcma.glb?alt=media&token=a9972ac7-d3ac-493d-a48c-9be8af7f1e09',
          sizeBytes: 25 * 1024 * 1024,
        ),
        AssetInfo(
          id: 'normal_pregnancy',
          name: '3D Normal Pregnancy',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Fectopic%2Fnormal_pregnancy.glb?alt=media&token=9efddfd3-d0b6-49d4-8dbb-f3daac1633eb',
          sizeBytes: 25 * 1024 * 1024,
        ),
        AssetInfo(
          id: 'tubal_ectopic',
          name: '3D Tubal Ectopic',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Fectopic%2Ftubal_ectopic.glb?alt=media&token=f322b6b5-40fe-4d4e-b45f-9da43d7a5914',
          sizeBytes: 25 * 1024 * 1024,
        ),
        AssetInfo(
          id: 'ectopic_cervical',
          name: '3D Cervical Ectopic',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Fectopic%2Fcervical_ectopic.glb?alt=media&token=d8d50ca9-ce82-4efc-92a8-17d34a1a7b8e',
          sizeBytes: 25 * 1024 * 1024,
        ),
        AssetInfo(
          id: 'ectopic_cornual',
          name: '3D Cornual Ectopic',
          systemId: 'obstetric',
          url:
              'https://firebasestorage.googleapis.com/v0/b/integrated-health-app-285e9.firebasestorage.app/o/models%2Fobs%2Fectopic%2Fcornual_ectopic.glb?alt=media&token=bc3b0dc7-cf05-4481-adc7-b3a5b2baa981',
          sizeBytes: 25 * 1024 * 1024,
        ),
      ],
    ),
    SystemAssetGroup(
      systemId: 'endocrine',
      name: 'Endocrine System',
      description: '3D models: Thyroid, Pituitary, Adrenal',
      colorValue: 0xFFEC4899,
      icon: Icons.science,
      assets: [
        // Add assets here when available
        // AssetInfo(id: 'thyroid', name: '3D Thyroid', ...),
      ],
    ),
    SystemAssetGroup(
      systemId: 'renal',
      name: 'Renal System',
      description: '3D models: Kidney, Nephron',
      colorValue: 0xFF3B82F6,
      icon: Icons.water_drop,
      assets: [
        // Add assets here when available
      ],
    ),
    SystemAssetGroup(
      systemId: 'cardiovascular',
      name: 'Cardiovascular System',
      description: '3D models: Heart, Vessels',
      colorValue: 0xFFEF4444,
      icon: Icons.favorite,
      assets: [
        // Add assets here when available
      ],
    ),
    SystemAssetGroup(
      systemId: 'respiratory',
      name: 'Respiratory System',
      description: '3D models: Lungs, Airways',
      colorValue: 0xFF10B981,
      icon: Icons.air,
      assets: [
        // Add assets here when available
      ],
    ),
    SystemAssetGroup(
      systemId: 'hepatobiliary',
      name: 'Hepatobiliary System',
      description: '3D models: Liver, Gallbladder',
      colorValue: 0xFFF59E0B,
      icon: Icons.local_hospital,
      assets: [
        // Add assets here when available
      ],
    ),
    SystemAssetGroup(
      systemId: 'neurological',
      name: 'Neurological System',
      description: '3D models: Brain, Nerves',
      colorValue: 0xFF6366F1,
      icon: Icons.psychology,
      assets: [
        // Add assets here when available
      ],
    ),
    SystemAssetGroup(
      systemId: 'musculoskeletal',
      name: 'Musculoskeletal System',
      description: '3D models: Bones, Joints',
      colorValue: 0xFFA855F7,
      icon: Icons.accessibility_new,
      assets: [
        // Add assets here when available
      ],
    ),
  ];

  /// Systems that actually have assets to download.
  static List<SystemAssetGroup> get availableSystems =>
      systemAssets.where((s) => s.assets.isNotEmpty).toList();

  /// All downloadable assets across all systems.
  static List<AssetInfo> get allAssets =>
      systemAssets.expand((s) => s.assets).toList();

  // ─── First-launch check ────────────────────────────────────────────

  /// Returns true if the user has already been through the download setup.
  static Future<bool> isSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeySetupDone) ?? false;
  }

  /// Mark the download setup as completed (user can skip or finish).
  static Future<void> markSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeySetupDone, true);
  }

  // ─── Cache directory (app-scoped, deleted on uninstall) ────────────

  Future<String> getCacheDirectory() async {
    final dir = await _cacheDir;
    return dir.path;
  }

  Future<Directory> get _cacheDir async {
    // getApplicationSupportDirectory is app-scoped on both Android & iOS
    // and is automatically deleted when the app is uninstalled.
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory('${appDir.path}/models_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _localFile(String assetId, String extension) async {
    final dir = await _cacheDir;
    return File('${dir.path}/$assetId.$extension');
  }

  // ─── Cache queries ─────────────────────────────────────────────────

  /// URL for the model-viewer web component JS library.
  static const _modelViewerJsUrl =
      'https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js';

  /// Get the cached path for model-viewer.min.js, downloading if needed.
  /// Returns the local file path for serving via local HTTP server.
  Future<String> getModelViewerJsPath() async {
    final dir = await _cacheDir;
    final file = File('${dir.path}/model-viewer.min.js');
    if (await file.exists()) return file.path;

    // Download and cache
    final response = await http.get(Uri.parse(_modelViewerJsUrl));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    }
    throw Exception('Failed to download model-viewer.js: HTTP ${response.statusCode}');
  }

  /// Check if the model-viewer JS is already cached locally.
  Future<bool> isModelViewerJsCached() async {
    final dir = await _cacheDir;
    final file = File('${dir.path}/model-viewer.min.js');
    return file.exists();
  }

  Future<bool> isCached(String assetId, {String ext = 'glb'}) async {
    final file = await _localFile(assetId, ext);
    return file.exists();
  }

  Future<String?> getCachedPath(String assetId, {String ext = 'glb'}) async {
    final file = await _localFile(assetId, ext);
    if (await file.exists()) return file.path;
    return null;
  }

  /// Check which assets in a system are already downloaded.
  Future<Map<String, bool>> getSystemCacheStatus(String systemId) async {
    final group = systemAssets.firstWhere((s) => s.systemId == systemId);
    final result = <String, bool>{};
    for (final asset in group.assets) {
      result[asset.id] = await isCached(asset.id, ext: asset.fileExtension);
    }
    return result;
  }

  /// Total cached size on disk (in bytes).
  Future<int> getCachedSizeBytes() async {
    final dir = await _cacheDir;
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  // ─── Download ──────────────────────────────────────────────────────

  /// Download a single asset with progress reporting.
  /// Uses FirebaseStorage.getDownloadURL() (requires Firebase Auth — anonymous
  /// sign-in is sufficient) to get a fresh token URL, then streams via HTTP.
  Future<String> downloadAsset(
    AssetInfo asset, {
    ValueChanged<double>? onProgress,
  }) async {
    // Check cache first
    final cached = await getCachedPath(asset.id, ext: asset.fileExtension);
    if (cached != null) {
      onProgress?.call(1.0);
      return cached;
    }

    // Ensure Firebase Auth is active — sign in anonymously if needed
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    // Get a fresh download URL — requires Firebase Auth, blocks unauthenticated access
    final ref = FirebaseStorage.instance.ref(asset.storagePath);
    final downloadUrl = await ref.getDownloadURL();

    final file = await _localFile(asset.id, asset.fileExtension);
    final request = http.Request('GET', Uri.parse(downloadUrl));
    final response = await http.Client().send(request);

    if (response.statusCode == 404) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'object-not-found',
        message: 'No object exists at the desired reference.',
      );
    }
    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    final total = response.contentLength ?? 0;
    int received = 0;
    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress?.call(received / total);
    }
    await sink.close();
    onProgress?.call(1.0);
    return file.path;
  }

  /// Download all assets for a given system.
  /// Missing assets (not yet uploaded) are skipped — they won't block others.
  /// [onProgress] receives overall progress 0.0 to 1.0.
  Future<void> downloadSystem(
    String systemId, {
    ValueChanged<double>? onProgress,
  }) async {
    final group = systemAssets.firstWhere((s) => s.systemId == systemId);
    if (group.assets.isEmpty) return;

    for (int i = 0; i < group.assets.length; i++) {
      try {
        await downloadAsset(
          group.assets[i],
          onProgress: (p) {
            final overall = (i + p) / group.assets.length;
            onProgress?.call(overall);
          },
        );
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          debugPrint('Skipping missing asset ${group.assets[i].id}: ${e.message}');
        } else {
          rethrow;
        }
      } catch (e) {
        if (e.toString().contains('404') || e.toString().contains('object-not-found') || e.toString().contains('not-found')) {
          debugPrint('Skipping missing asset ${group.assets[i].id}');
        } else {
          rethrow;
        }
      }
    }
    onProgress?.call(1.0);
  }

  // ─── Legacy helper (for ModelViewerScreen compatibility) ───────────

  /// Download a model by name. Falls back to 'uterus' if model not found.
  /// Also checks the remote catalog for dynamically added models.
  Future<String> downloadModel(
    String modelName, {
    ValueChanged<double>? onProgress,
  }) async {
    // First try the static asset list by id
    AssetInfo? asset;
    try {
      asset = allAssets.firstWhere((a) => a.id == modelName);
    } catch (_) {
      asset = null;
    }

    // Also try matching by modelFileName (URL contains the file name)
    if (asset == null) {
      try {
        asset = allAssets.firstWhere(
          (a) => a.url.contains('$modelName.glb') || a.url.contains('$modelName.mp4') || a.url.contains('$modelName%2F') || a.url.contains('%2F$modelName.'),
        );
      } catch (_) {
        // Not found by file name either
      }
    }

    // If not found in static list, check the remote catalog cache
    if (asset == null) {
      try {
        final catalog = await _getRemoteCatalogAssets();
        asset = catalog.firstWhere((a) => a.id == modelName);
      } catch (_) {
        // Not in remote catalog either
      }
    }

    // Last resort: fallback to uterus
    if (asset == null) {
      try {
        asset = allAssets.firstWhere((a) => a.id == 'uterus');
      } catch (_) {
        throw Exception('No fallback model available');
      }
    }

    return downloadAsset(asset, onProgress: onProgress);
  }

  /// Get AssetInfo entries from the cached remote catalog.
  Future<List<AssetInfo>> _getRemoteCatalogAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('remote_catalog_cache') ?? [];
    final assets = <AssetInfo>[];
    for (final s in jsonList) {
      try {
        final map = Map<String, dynamic>.from(
          json.jsonDecode(s) as Map,
        );
        assets.add(AssetInfo(
          id: map['modelFileName'] ?? '',
          name: map['name'] ?? '',
          systemId: map['categoryId'] ?? '',
          url: map['downloadUrl'] ?? '',
          sizeBytes: map['sizeBytes'] ?? 0,
        ));
      } catch (_) {}
    }
    return assets;
  }

  // ─── Cache management ──────────────────────────────────────────────

  Future<void> clearAssetCache(String assetId, {String ext = 'glb'}) async {
    final file = await _localFile(assetId, ext);
    if (await file.exists()) await file.delete();
  }

  Future<void> clearSystemCache(String systemId) async {
    final group = systemAssets.firstWhere((s) => s.systemId == systemId);
    for (final asset in group.assets) {
      await clearAssetCache(asset.id, ext: asset.fileExtension);
    }
  }

  Future<void> clearAllCache() async {
    final dir = await _cacheDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
