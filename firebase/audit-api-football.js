import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import { buildTransferAudit, formatTransferAudit } from './api-football-audit.js';

// Read-only inspection of private staging data. No Firestore writes occur.
// See SPEC.md §24, §27, §28, §36.
const options = parseArguments(process.argv.slice(2));
initializeApp({ credential: applicationDefault(), projectId: options.projectId });
const snapshot = await getFirestore()
  .collection('externalTransfers')
  .where('provider', '==', 'api-football')
  .get();
const audit = buildTransferAudit(snapshot.docs.map((document) => document.data()));

if (options.json) {
  console.log(JSON.stringify(audit, null, 2));
} else {
  console.log(formatTransferAudit(audit));
}

function parseArguments(argumentsList) {
  let projectId;
  let json = false;
  for (const argument of argumentsList) {
    if (argument === '--json') {
      json = true;
      continue;
    }
    if (argument.startsWith('--project=')) {
      projectId = argument.slice('--project='.length);
      continue;
    }
    throw new Error(`Unknown argument: ${argument}`);
  }
  if (!projectId) {
    throw new Error('Usage: npm run audit-api-football -- --project=PROJECT_ID [--json]');
  }
  return { projectId, json };
}
