const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

/**
 * Cloud Function: Auto-create a Firestore `model_catalog` document
 * when a .glb file is uploaded to Firebase Storage under models/.
 *
 * Storage path convention:
 *   models/{categoryId}/{subcategory}/{modelFileName}.glb
 *
 * Examples:
 *   models/obs/placenta_previa/previa_stage1.glb
 *     → categoryId: "obstetric", subcategory: "Placenta Previa"
 *   models/normal_uterus_3d.glb
 *     → categoryId: "gynaecology", subcategory: "General"
 *   models/endometrium/uterus_endo_polyp.glb
 *     → categoryId: "gynaecology", subcategory: "Endometrium"
 *
 * The function derives metadata from the file path. You can update
 * the Firestore document afterwards to add richer descriptions.
 */

// Map storage folder prefixes to app category IDs
const CATEGORY_MAP = {
  "obs": "obstetric",
  "gyn": "gynaecology",
  "cardiac": "cardiac",
  "renal": "renal",
  "respiratory": "respiratory",
  "neuro": "neuro",
  "hepatic": "hepatic",
  "musculoskeletal": "musculoskeletal",
  "endocrine": "endocrine",
  "endometrium": "gynaecology",
};

// Map storage folder names to readable subcategory names
const SUBCATEGORY_MAP = {
  "placenta_previa": "Placenta Previa",
  "placental_abruption": "Placental Abruption",
  "fetus_presentation": "Fetal Presentation",
  "fetal_lie": "Fetal Lie",
  "amniotic_fluid": "Amniotic Fluid",
  "twin_pregnancy": "Twin Pregnancy",
  "ectopic_pregnancy": "Ectopic Pregnancy",
  "placental_pathology": "Placental Pathology",
  "Fetus_cord_loop": "Loop of Cord",
  "endometrium": "Endometrium",
  "mullerian": "Mullerian Anomaly",
  "fibroids": "Fibroids",
  "ovary": "Ovary",
};

exports.onModelUploaded = functions.storage
  .object()
  .onFinalize(async (object) => {
    const filePath = object.name; // e.g. "models/obs/placenta_previa/previa_stage1.glb"
    const contentType = object.contentType;

    // Only process .glb files under models/
    if (!filePath || !filePath.startsWith("models/") || !filePath.endsWith(".glb")) {
      console.log(`Skipping non-model file: ${filePath}`);
      return null;
    }

    // Parse the path
    const parts = filePath.replace("models/", "").replace(".glb", "").split("/");
    // parts could be: ["normal_uterus_3d"] or ["obs", "placenta_previa", "previa_stage1"]

    let categoryId = "gynaecology"; // default
    let subcategory = "General";
    let modelFileName;

    if (parts.length === 1) {
      // models/filename.glb → gynaecology / General
      modelFileName = parts[0];
    } else if (parts.length === 2) {
      // models/folder/filename.glb
      const folder = parts[0];
      modelFileName = parts[1];
      categoryId = CATEGORY_MAP[folder] || folder;
      subcategory = SUBCATEGORY_MAP[folder] || _toReadable(folder);
    } else if (parts.length >= 3) {
      // models/category/subcategory/filename.glb
      const catFolder = parts[0];
      const subFolder = parts[1];
      modelFileName = parts[parts.length - 1];
      categoryId = CATEGORY_MAP[catFolder] || catFolder;
      subcategory = SUBCATEGORY_MAP[subFolder] || _toReadable(subFolder);
    }

    // Generate a readable name from the filename
    const name = _toReadable(modelFileName);

    // Build the download URL (without public token — app uses Firebase SDK)
    const bucket = object.bucket;
    const encodedPath = encodeURIComponent(filePath);
    const downloadUrl =
      `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodedPath}?alt=media`;

    const size = parseInt(object.size, 10) || 0;

    // Check if document already exists
    const docRef = db.collection("model_catalog").doc(modelFileName);
    const existing = await docRef.get();
    if (existing.exists) {
      // Update the updatedAt timestamp so the app detects the change
      await docRef.update({
        downloadUrl: downloadUrl,
        sizeBytes: size,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Updated existing model_catalog entry: ${modelFileName}`);
      return null;
    }

    // Create new document
    await docRef.set({
      name: name,
      categoryId: categoryId,
      subcategory: subcategory,
      description: name,
      modelFileName: modelFileName,
      downloadUrl: downloadUrl,
      sizeBytes: size,
      tags: [categoryId, subcategory.toLowerCase()],
      isAnatomy: false,
      isPremium: false,
      isComparisonModel: false,
      addedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Created model_catalog entry: ${modelFileName} (${categoryId}/${subcategory})`);
    return null;
  });

/**
 * Convert snake_case or camelCase filename to readable name.
 * e.g. "previa_stage1" → "Previa Stage1"
 *       "placenta_previa" → "Placenta Previa"
 */
function _toReadable(str) {
  return str
    .replace(/_/g, " ")
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}
