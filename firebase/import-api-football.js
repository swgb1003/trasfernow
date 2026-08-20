import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';

import { ApiFootballClient } from './api-football-client.js';
import { normalizeTransferEntries } from './api-football-mapper.js';

// Staged external ingestion. Dry-run is the default and publishing into the
// app's live `transferCases` collection is intentionally a later review step.
// See SPEC.md §24, §27, §28, §36.
const options = parseArguments(process.argv.slice(2));
const apiKey = process.env.API_FOOTBALL_KEY;
if (!apiKey) {
  throw new Error(
    'API_FOOTBALL_KEY is missing. Set it only in your terminal environment.',
  );
}

const client = new ApiFootballClient({
  apiKey,
  minimumRequestIntervalMs: 7000,
  onRateLimitRetry: ({ attempt, maxAttempts, waitMs }) => {
    console.warn(
      `Per-minute limit reached. Waiting ${Math.ceil(waitMs / 1000)} seconds ` +
        `before retry ${attempt}/${maxAttempts}...`,
    );
  },
});
const teamsPayload = await client.getTeams({
  league: options.league,
  season: options.season,
});
const teams = teamsPayload
  .map((item) => item?.team)
  .filter((team) => Number.isInteger(team?.id) && team?.name)
  .slice(0, options.maxTeams);

if (teams.length === 0) {
  throw new Error('No teams were returned. Check league/season plan coverage.');
}

const transferEntries = [];
for (const [index, team] of teams.entries()) {
  console.log(`[${index + 1}/${teams.length}] Fetching ${team.name} transfers...`);
  transferEntries.push(...(await client.getTransfers({ team: team.id })));
}

const records = normalizeTransferEntries(transferEntries, {
  leagueTeamIds: teams.map((team) => team.id),
  season: options.season,
  includeLoanReturns: options.includeLoanReturns,
});
const quota = client.lastQuota?.remaining
  ? ` Remaining daily requests: ${client.lastQuota.remaining}.`
  : '';

console.log(
  `Prepared ${records.length} unique transfers from ${teams.length} teams.${quota}`,
);

if (!options.write) {
  console.log('Dry-run only: Firestore was not changed. Preview:');
  console.log(JSON.stringify(records.slice(0, 10), null, 2));
  console.log('Re-run with --write --project=PROJECT_ID after reviewing the preview.');
  process.exit(0);
}

if (!options.projectId) {
  throw new Error('--project=PROJECT_ID is required with --write.');
}

initializeApp({ credential: applicationDefault(), projectId: options.projectId });
const db = getFirestore();
const writer = db.bulkWriter();
for (const record of records) {
  const document = {
    ...record,
    occurredAt: Timestamp.fromDate(record.occurredAt),
    providerUpdatedAt: record.providerUpdatedAt
      ? Timestamp.fromDate(record.providerUpdatedAt)
      : null,
    fetchedAt: FieldValue.serverTimestamp(),
  };
  writer.set(db.collection('externalTransfers').doc(record.externalId), document, {
    merge: true,
  });
}
await writer.close();

await db.collection('externalImportRuns').add({
  provider: 'api-football',
  league: options.league,
  season: options.season,
  teamCount: teams.length,
  recordCount: records.length,
  completedAt: FieldValue.serverTimestamp(),
});

console.log(
  `Wrote ${records.length} staging records to ${options.projectId}/externalTransfers.`,
);

function parseArguments(argumentsList) {
  const values = new Map();
  let write = false;
  let includeLoanReturns = false;
  for (const argument of argumentsList) {
    if (argument === '--write') {
      write = true;
      continue;
    }
    if (argument === '--include-loan-returns') {
      includeLoanReturns = true;
      continue;
    }
    const match = /^--([^=]+)=(.+)$/.exec(argument);
    if (!match) throw new Error(`Unknown argument: ${argument}`);
    values.set(match[1], match[2]);
  }

  const league = positiveInteger(values.get('league') ?? '39', 'league');
  // 2024 is a conservative historical validation season. Exact free-plan
  // season availability depends on the user's API-Football subscription.
  const season = positiveInteger(values.get('season') ?? '2024', 'season');
  const maxTeams = positiveInteger(values.get('max-teams') ?? '2', 'max-teams');
  if (maxTeams > 20) throw new Error('max-teams must be 20 or less.');

  return {
    league,
    season,
    maxTeams,
    write,
    includeLoanReturns,
    projectId: values.get('project'),
  };
}

function positiveInteger(value, name) {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error(`${name} must be a positive integer.`);
  }
  return parsed;
}
