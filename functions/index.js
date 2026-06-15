const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

/**
 * Callable function: return a short-lived signed URL for a Storage model.
 *
 * The caller must be authenticated (anonymous or email Firebase Auth).
 * The signed URL is valid for 1 hour and is generated server-side using
 * the Admin SDK, so no public download token is ever embedded in the app.
 *
 * Request data: { path: "models/obs/placenta_previa/previa_stage1.glb" }
 * Response:     { url: "https://storage.googleapis.com/...?X-Goog-Signature=..." }
 */
exports.getModelDownloadUrl = functions.https.onCall(async (data, context) => {
  // Reject unauthenticated callers (covers anonymous Firebase Auth too)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to download models."
    );
  }

  const storagePath = data.path;
  if (!storagePath || typeof storagePath !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A valid storage path is required."
    );
  }

  // Only allow paths under models/ to prevent misuse
  if (!storagePath.startsWith("models/")) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Access to this path is not allowed."
    );
  }

  const bucket = admin.storage().bucket();
  const file = bucket.file(storagePath);

  const [exists] = await file.exists();
  if (!exists) {
    throw new functions.https.HttpsError(
      "not-found",
      `Model not found: ${storagePath}`
    );
  }

  const [url] = await file.getSignedUrl({
    action: "read",
    expires: Date.now() + 60 * 60 * 1000, // 1 hour
  });

  return { url };
});

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
  "twins": "Twin Pregnancy",
  "ectopic_pregnancy": "Ectopic Pregnancy",
  "placental_pathology": "Placental Pathology",
  "Fetus_cord_loop": "Loop of Cord",
  "endometrium": "Endometrium",
  "mullerian": "Mullerian Anomaly",
  "fibroids": "Fibroids",
  "ovary": "Ovary",
};

// Master switch for automatic Draco compression on upload.
//
// All existing models were already bulk-compressed once, so auto-compression
// is no longer needed for the catalog — and it has actively broken some models
// (gltf-pipeline mangles certain geometry, causing "can't access property
// extensions" in model-viewer). With this OFF, NOTHING uploaded gets
// compressed, which removes the deploy-before-upload timing race entirely:
// you can re-upload a file any number of times and it stays exactly as-is.
//
// Set back to true only if you want new uploads auto-compressed again.
const AUTO_COMPRESS_ENABLED = false;

// Models that must NOT be Draco-compressed even when AUTO_COMPRESS_ENABLED is
// true — gltf-pipeline breaks their geometry structure.
const COMPRESSION_SKIP_LIST = new Set([
  "models/gynaec/ovary/ovary_dermoid_Cyst_2.glb",
]);

exports.onModelUploaded = functions
  .runWith({ memory: "2GB", timeoutSeconds: 540 })
  .storage.object()
  .onFinalize(async (object) => {
    const filePath = object.name; // e.g. "models/obs/placenta_previa/previa_stage1.glb"
    const contentType = object.contentType;

    // Only process .glb files under models/
    if (!filePath || !filePath.startsWith("models/") || !filePath.endsWith(".glb")) {
      console.log(`Skipping non-model file: ${filePath}`);
      return null;
    }

    // If this upload is our own Draco-compressed re-upload, skip compression
    // and go straight to cataloguing (using the final, smaller size).
    const alreadyCompressed =
      object.metadata && object.metadata.dracoCompressed === "true";
    const skipCompression =
      !AUTO_COMPRESS_ENABLED || COMPRESSION_SKIP_LIST.has(filePath);

    if (!alreadyCompressed && !skipCompression) {
      const didCompress = await _compressAndReupload(object, filePath);
      if (didCompress) {
        // The re-upload re-triggers this function with dracoCompressed=true,
        // which creates the catalog entry with the compressed size. Stop here
        // so we don't catalog the (now stale) original size.
        return null;
      }
      // Compression skipped or not beneficial — catalog the original below.
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
 * Download a freshly-uploaded .glb, apply Draco mesh compression, and
 * re-upload it in place if the result is meaningfully smaller.
 *
 * Returns true if a compressed version was uploaded (which re-triggers this
 * function), false if compression was skipped, failed, or not beneficial.
 *
 * The original Firebase download token is preserved so any URLs with an
 * embedded ?token=... (e.g. those hardcoded in the app) keep working. A
 * `dracoCompressed: "true"` custom-metadata flag marks the file so the
 * re-upload doesn't trigger an endless compress loop.
 */
async function _compressAndReupload(object, filePath) {
  // gltf-pipeline does Draco geometry compression via draco3d (WebAssembly).
  // It has no native/platform-specific binaries (unlike gltf-transform, which
  // pulls in `sharp`), so the lock file works on Firebase's Linux builders.
  const gltfPipeline = require("gltf-pipeline");

  const bucket = admin.storage().bucket(object.bucket);
  const file = bucket.file(filePath);

  try {
    const [inputBuffer] = await file.download();
    const originalSize = inputBuffer.length;

    const result = await gltfPipeline.processGlb(inputBuffer, {
      dracoOptions: { compressionLevel: 10 },
    });
    const outputBuffer = result.glb;
    const compressedSize = outputBuffer.length;
    const pct = (100 * (1 - compressedSize / originalSize)).toFixed(1);
    console.log(
      `Draco ${filePath}: ${originalSize} → ${compressedSize} bytes (${pct}% smaller)`
    );

    // Skip the re-upload if it barely helped (<5% savings) — not worth the
    // token churn / extra write.
    if (compressedSize >= originalSize * 0.95) {
      console.log(`Compression not beneficial, keeping original: ${filePath}`);
      return false;
    }

    // Preserve the existing download token so embedded ?token=... URLs survive.
    const originalToken =
      object.metadata && object.metadata.firebaseStorageDownloadTokens;

    await file.save(outputBuffer, {
      metadata: {
        contentType: "model/gltf-binary",
        metadata: {
          dracoCompressed: "true",
          ...(originalToken
            ? { firebaseStorageDownloadTokens: originalToken }
            : {}),
        },
      },
    });
    console.log(`Re-uploaded Draco-compressed model: ${filePath}`);
    return true;
  } catch (e) {
    console.error(`Draco compression failed for ${filePath}:`, e);
    return false;
  }
}

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
