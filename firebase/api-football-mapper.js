// Normalizes API-Football transfer history into a private Firestore staging
// record. It deliberately does not publish directly to `transferCases` because
// confirmed transfers lack the rumours, sources and player detail required by
// the product model. See SPEC.md §24, §26-§28, §36.
export function normalizeTransferEntries(
  entries,
  { leagueTeamIds, season, includeLoanReturns = false },
) {
  const knownTeams = new Set([...leagueTeamIds].map(Number));
  const start = new Date(Date.UTC(season, 6, 1));
  const end = new Date(Date.UTC(season + 1, 5, 30, 23, 59, 59, 999));
  const records = new Map();

  for (const entry of entries) {
    const player = entry?.player;
    if (!Number.isInteger(player?.id) || !nonEmptyString(player?.name)) continue;

    for (const transfer of Array.isArray(entry?.transfers) ? entry.transfers : []) {
      const occurredAt = parseTransferDate(transfer?.date);
      const fromTeam = normalizeTeam(transfer?.teams?.out);
      const toTeam = normalizeTeam(transfer?.teams?.in);
      if (!occurredAt || !fromTeam || !toTeam) continue;
      if (occurredAt < start || occurredAt > end) continue;
      if (!knownTeams.has(fromTeam.externalId) && !knownTeams.has(toTeam.externalId)) {
        continue;
      }

      const externalId = [
        'api-football',
        player.id,
        dateOnly(occurredAt),
        fromTeam.externalId,
        toTeam.externalId,
      ].join('-');
      const transferType = nonEmptyString(transfer?.type)
        ? transfer.type.trim()
        : 'N/A';
      if (!includeLoanReturns && isLoanReturn(transferType)) continue;
      const record = {
        externalId,
        provider: 'api-football',
        providerPlayerId: player.id,
        playerName: player.name.trim(),
        occurredAt,
        transferType,
        estimatedFeeMillionsEur: parseFeeMillionsEur(transferType),
        fromTeam,
        toTeam,
        premierLeagueDirection:
          knownTeams.has(fromTeam.externalId) && knownTeams.has(toTeam.externalId)
            ? 'internal'
            : knownTeams.has(toTeam.externalId)
              ? 'in'
              : 'out',
        season,
        providerUpdatedAt: parseDateTime(entry?.update),
      };

      const existing = records.get(externalId);
      if (!existing || isNewer(record.providerUpdatedAt, existing.providerUpdatedAt)) {
        records.set(externalId, record);
      }
    }
  }

  return [...records.values()].sort(
    (left, right) => right.occurredAt.getTime() - left.occurredAt.getTime(),
  );
}

function isLoanReturn(value) {
  return /^(return|back) from loan$/i.test(value.trim());
}

export function parseFeeMillionsEur(value) {
  if (!nonEmptyString(value)) return null;
  const compact = value.replaceAll(' ', '').replaceAll(',', '').toUpperCase();
  const match = /^€([0-9]+(?:\.[0-9]+)?)([MK])?$/.exec(compact);
  if (!match) return null;
  const amount = Number(match[1]);
  if (!Number.isFinite(amount)) return null;
  if (match[2] === 'K') return amount / 1000;
  if (match[2] === 'M') return amount;
  return amount / 1_000_000;
}

function normalizeTeam(value) {
  if (!Number.isInteger(value?.id) || !nonEmptyString(value?.name)) return null;
  return {
    externalId: value.id,
    name: value.name.trim(),
    logoUrl: nonEmptyString(value.logo) ? value.logo.trim() : null,
  };
}

function parseTransferDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value ?? '')) return null;
  const parsed = new Date(`${value}T00:00:00.000Z`);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function parseDateTime(value) {
  if (!nonEmptyString(value)) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function dateOnly(value) {
  return value.toISOString().slice(0, 10);
}

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isNewer(left, right) {
  if (!right) return Boolean(left);
  if (!left) return false;
  return left.getTime() > right.getTime();
}
