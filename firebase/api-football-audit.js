// Produces a read-only quality report for private API-Football staging data.
// It does not infer rumours or publish records to `transferCases`.
// See SPEC.md §24, §26-§28, §36.
export function buildTransferAudit(records) {
  if (!Array.isArray(records)) throw new TypeError('records must be an array.');

  const typeCounts = new Map();
  const categoryCounts = new Map();
  const directionCounts = new Map();
  const teamCounts = new Map();
  const flagCounts = new Map();
  const dates = [];
  let knownFeeCount = 0;
  let reviewReadyCount = 0;

  for (const record of records) {
    const transferType = text(record?.transferType) ?? 'N/A';
    increment(typeCounts, transferType);
    increment(categoryCounts, transferCategory(record));
    increment(directionCounts, text(record?.premierLeagueDirection) ?? 'unknown');

    addTeam(teamCounts, record?.fromTeam);
    addTeam(teamCounts, record?.toTeam);

    if (Number.isFinite(record?.estimatedFeeMillionsEur)) knownFeeCount += 1;
    const occurredAt = toDate(record?.occurredAt);
    if (occurredAt) dates.push(occurredAt);

    const flags = reviewFlags(record, occurredAt);
    for (const flag of flags) increment(flagCounts, flag);
    if (!flags.some((flag) => BLOCKING_FLAGS.has(flag))) reviewReadyCount += 1;
  }

  dates.sort((left, right) => left.getTime() - right.getTime());
  const total = records.length;
  return {
    total,
    reviewReadyCount,
    knownFeeCount,
    knownFeePercent: total === 0 ? 0 : roundPercent(knownFeeCount / total),
    dateRange: {
      first: dates.at(0)?.toISOString().slice(0, 10) ?? null,
      last: dates.at(-1)?.toISOString().slice(0, 10) ?? null,
    },
    categories: sortedCounts(categoryCounts),
    directions: sortedCounts(directionCounts),
    transferTypes: sortedCounts(typeCounts).slice(0, 15),
    reviewFlags: sortedCounts(flagCounts),
    topTeams: sortedCounts(teamCounts).slice(0, 20),
  };
}

export function formatTransferAudit(audit) {
  const lines = [
    'API-Football staging quality audit',
    `Total records: ${audit.total}`,
    `Review-ready records: ${audit.reviewReadyCount}`,
    `Known fees: ${audit.knownFeeCount} (${audit.knownFeePercent}%)`,
    `Date range: ${audit.dateRange.first ?? 'N/A'} to ${audit.dateRange.last ?? 'N/A'}`,
    '',
    'Transfer categories:',
    ...formatCounts(audit.categories),
    '',
    'Premier League direction:',
    ...formatCounts(audit.directions),
    '',
    'Review flags:',
    ...(audit.reviewFlags.length > 0 ? formatCounts(audit.reviewFlags) : ['  none']),
    '',
    'Most common raw transfer types:',
    ...formatCounts(audit.transferTypes),
    '',
    'Top clubs by involvement:',
    ...formatCounts(audit.topTeams),
  ];
  return lines.join('\n');
}

const BLOCKING_FLAGS = new Set([
  'missing_core_fields',
  'loan_return',
  'same_team',
  'unknown_transfer_type',
]);

function reviewFlags(record, occurredAt) {
  const flags = [];
  const fromName = text(record?.fromTeam?.name);
  const toName = text(record?.toTeam?.name);
  const type = text(record?.transferType);
  if (!text(record?.playerName) || !fromName || !toName || !occurredAt) {
    flags.push('missing_core_fields');
  }
  if (
    record?.fromTeam?.externalId != null &&
    record?.fromTeam?.externalId === record?.toTeam?.externalId
  ) {
    flags.push('same_team');
  }
  if (!type || type.toUpperCase() === 'N/A' || type === '-') {
    flags.push('unknown_transfer_type');
  }
  if (isLoanReturn(type)) flags.push('loan_return');
  if (!Number.isFinite(record?.estimatedFeeMillionsEur)) flags.push('missing_fee');
  if (!text(record?.fromTeam?.logoUrl) || !text(record?.toTeam?.logoUrl)) {
    flags.push('missing_club_logo');
  }
  if (isFreeAgentTeam(fromName) || isFreeAgentTeam(toName)) {
    flags.push('free_agent_route');
  }
  if (isDevelopmentTeam(fromName) || isDevelopmentTeam(toName)) {
    flags.push('development_team_route');
  }
  return flags;
}

function transferCategory(record) {
  if (Number.isFinite(record?.estimatedFeeMillionsEur)) return 'paid_fee';
  const normalized = text(record?.transferType)?.toLowerCase() ?? '';
  if (isLoanReturn(normalized)) return 'loan_return';
  if (normalized.includes('loan')) return 'loan';
  if (normalized.includes('free')) return 'free';
  if (!normalized || normalized === 'n/a' || normalized === '-') return 'unknown';
  return 'other';
}

function addTeam(counts, team) {
  const name = text(team?.name);
  if (name) increment(counts, name);
}

function isFreeAgentTeam(value) {
  return /without club|free agent|retired/i.test(value ?? '');
}

function isDevelopmentTeam(value) {
  return /(^|\s)(u-?\d{2}|ii|b|youth|academy|reserves?)(\s|$)/i.test(value ?? '');
}

function isLoanReturn(value) {
  return /^(return|back) from loan$/i.test(value ?? '');
}

function toDate(value) {
  if (value instanceof Date && !Number.isNaN(value.getTime())) return value;
  if (typeof value === 'string') {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  try {
    const converted = value?.toDate();
    return converted instanceof Date && !Number.isNaN(converted.getTime())
      ? converted
      : null;
  } catch (_) {
    return null;
  }
}

function text(value) {
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}

function increment(counts, key) {
  counts.set(key, (counts.get(key) ?? 0) + 1);
}

function sortedCounts(counts) {
  return [...counts.entries()]
    .map(([name, count]) => ({ name, count }))
    .sort((left, right) => right.count - left.count || left.name.localeCompare(right.name));
}

function formatCounts(values) {
  return values.map(({ name, count }) => `  ${name}: ${count}`);
}

function roundPercent(value) {
  return Math.round(value * 1000) / 10;
}
