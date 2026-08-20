import { randomUUID } from 'node:crypto';
import { readdir } from 'node:fs/promises';
import { extname, join, parse } from 'node:path';
import { fileURLToPath } from 'node:url';

import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

const args = new Map(
  process.argv.slice(2).map((argument) => {
    const separator = argument.indexOf('=');
    return separator === -1
      ? [argument, true]
      : [argument.slice(0, separator), argument.slice(separator + 1)];
  }),
);

const projectId = args.get('--project');
const dryRun = args.has('--dry-run');
const bucketName = args.get('--bucket') || `${projectId}.firebasestorage.app`;

if (!projectId) {
  throw new Error(
    'Usage: npm run sync-assets -- --project=YOUR_PROJECT_ID [--bucket=BUCKET] [--dry-run]',
  );
}

const assetsRoot = fileURLToPath(new URL('./assets/', import.meta.url));
const supportedExtensions = new Set(['.jpg', '.jpeg', '.png', '.webp']);
const contentTypes = new Map([
  ['.jpg', 'image/jpeg'],
  ['.jpeg', 'image/jpeg'],
  ['.png', 'image/png'],
  ['.webp', 'image/webp'],
]);

const assetGroups = [
  {
    kind: 'player',
    localDirectory: 'players',
    objectPrefix: 'players',
    collection: 'players',
    urlField: 'imageUrl',
  },
  {
    kind: 'club',
    localDirectory: 'club-crests',
    objectPrefix: 'club-crests',
    collection: 'clubs',
    urlField: 'crestUrl',
  },
];

async function discoverAssets(group) {
  const directory = join(assetsRoot, group.localDirectory);
  const entries = await readdir(directory, { withFileTypes: true });
  const assets = entries
    .filter((entry) => entry.isFile())
    .map((entry) => {
      const extension = extname(entry.name).toLowerCase();
      return {
        ...group,
        id: parse(entry.name).name,
        extension,
        localPath: join(directory, entry.name),
        objectPath: `${group.objectPrefix}/${entry.name}`,
      };
    })
    .filter((asset) => supportedExtensions.has(asset.extension));

  const ids = new Set();
  for (const asset of assets) {
    if (ids.has(asset.id)) {
      throw new Error(
        `Duplicate ${group.kind} ID "${asset.id}" in ${group.localDirectory}`,
      );
    }
    ids.add(asset.id);
  }
  return assets;
}

const assets = (await Promise.all(assetGroups.map(discoverAssets))).flat();

if (assets.length === 0) {
  console.log(
    `No images found in ${assetsRoot}. Add files as described in assets/README.md.`,
  );
  process.exit(0);
}

console.log(`Found ${assets.length} asset(s):`);
for (const asset of assets) {
  console.log(`- ${asset.kind}: ${asset.id} -> ${asset.objectPath}`);
}

if (dryRun) {
  console.log('Dry run complete; no Firebase resources were changed.');
  process.exit(0);
}

initializeApp({
  credential: applicationDefault(),
  projectId,
  storageBucket: bucketName,
});

const db = getFirestore();
const bucket = getStorage().bucket();
const [bucketExists] = await bucket.exists();
if (!bucketExists) {
  throw new Error(
    `Storage bucket ${bucketName} was not found. Create the default bucket in ` +
      'Firebase Console > Storage, then deploy storage.rules before syncing.',
  );
}

const caseSnapshot = await db.collection('transferCases').get();
const caseUpdates = new Map();
const masterWrites = [];

for (const asset of assets) {
  const masterRef = db.collection(asset.collection).doc(asset.id);
  const masterSnapshot = await masterRef.get();
  if (!masterSnapshot.exists) {
    throw new Error(
      `${asset.collection}/${asset.id} does not exist. Check the filename or run the seed first.`,
    );
  }

  const token = randomUUID();
  await bucket.upload(asset.localPath, {
    destination: asset.objectPath,
    resumable: false,
    metadata: {
      cacheControl: 'public,max-age=31536000,immutable',
      contentType: contentTypes.get(asset.extension),
      metadata: { firebaseStorageDownloadTokens: token },
    },
  });

  const downloadUrl =
    `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/` +
    `${encodeURIComponent(asset.objectPath)}?alt=media&token=${token}`;
  masterWrites.push({ ref: masterRef, field: asset.urlField, downloadUrl });

  const master = masterSnapshot.data();
  for (const caseDocument of caseSnapshot.docs) {
    const data = caseDocument.data();
    const update = caseUpdates.get(caseDocument.id) ?? {};

    if (
      asset.kind === 'player' &&
      (data.player?.id === asset.id || data.player?.name === master.name)
    ) {
      update['player.id'] = asset.id;
      update['player.imageUrl'] = downloadUrl;
    }
    if (asset.kind === 'club' && data.fromClub?.id === asset.id) {
      update['fromClub.crestUrl'] = downloadUrl;
    }
    if (asset.kind === 'club' && data.toClub?.id === asset.id) {
      update['toClub.crestUrl'] = downloadUrl;
    }

    if (Object.keys(update).length > 0) {
      caseUpdates.set(caseDocument.id, update);
    }
  }
}

const batch = db.batch();
for (const write of masterWrites) {
  batch.set(write.ref, { [write.field]: write.downloadUrl }, { merge: true });
}
for (const [caseId, update] of caseUpdates) {
  batch.update(db.collection('transferCases').doc(caseId), update);
}
await batch.commit();

console.log(
  `Uploaded ${assets.length} asset(s) to ${bucketName} and updated ` +
    `${caseUpdates.size} transfer case(s).`,
);
