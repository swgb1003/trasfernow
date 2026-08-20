import assert from 'node:assert/strict';
import test from 'node:test';

import {
  buildTransferAudit,
  formatTransferAudit,
} from '../api-football-audit.js';

test('summarizes transfer quality without changing source records', () => {
  const records = [
    transfer({
      playerName: 'Paid Player',
      transferType: '€20M',
      estimatedFeeMillionsEur: 20,
      direction: 'internal',
    }),
    transfer({
      playerName: 'Loan Player',
      transferType: 'Loan',
      toTeam: team(42, 'Premier FC', null),
      direction: 'in',
    }),
    transfer({
      playerName: 'Free Player',
      transferType: 'Free',
      fromTeam: team(8, 'Without Club'),
      direction: 'in',
    }),
    transfer({
      playerName: 'Unknown Player',
      transferType: '-',
      occurredAt: 'not-a-date',
      fromTeam: team(42, 'Premier FC'),
      toTeam: team(42, 'Premier FC'),
      direction: 'unknown',
    }),
  ];

  const audit = buildTransferAudit(records);

  assert.equal(audit.total, 4);
  assert.equal(audit.reviewReadyCount, 3);
  assert.equal(audit.knownFeeCount, 1);
  assert.equal(audit.knownFeePercent, 25);
  assert.deepEqual(audit.dateRange, { first: '2024-08-01', last: '2024-08-01' });
  assert.deepEqual(countMap(audit.categories), {
    free: 1,
    loan: 1,
    paid_fee: 1,
    unknown: 1,
  });
  assert.equal(countMap(audit.reviewFlags).missing_fee, 3);
  assert.equal(countMap(audit.reviewFlags).missing_core_fields, 1);
  assert.equal(countMap(audit.reviewFlags).same_team, 1);
  assert.equal(countMap(audit.reviewFlags).unknown_transfer_type, 1);
  assert.equal(countMap(audit.reviewFlags).free_agent_route, 1);
  assert.equal(countMap(audit.reviewFlags).missing_club_logo, 1);
  assert.match(formatTransferAudit(audit), /Total records: 4/);
});

test('handles an empty staging collection', () => {
  const audit = buildTransferAudit([]);

  assert.equal(audit.total, 0);
  assert.equal(audit.knownFeePercent, 0);
  assert.deepEqual(audit.dateRange, { first: null, last: null });
});

test('blocks alternate API wording for a loan return', () => {
  const audit = buildTransferAudit([
    transfer({ playerName: 'Returning Player', transferType: 'Back from Loan' }),
  ]);

  assert.equal(audit.reviewReadyCount, 0);
  assert.deepEqual(countMap(audit.categories), { loan_return: 1 });
  assert.equal(countMap(audit.reviewFlags).loan_return, 1);
});

function transfer({
  playerName,
  transferType,
  estimatedFeeMillionsEur = null,
  occurredAt = new Date('2024-08-01T00:00:00Z'),
  fromTeam = team(8, 'Outside FC'),
  toTeam = team(42, 'Premier FC'),
  direction,
}) {
  return {
    playerName,
    transferType,
    estimatedFeeMillionsEur,
    occurredAt,
    fromTeam,
    toTeam,
    premierLeagueDirection: direction,
  };
}

function team(externalId, name, logoUrl = 'https://example.test/club.png') {
  return { externalId, name, logoUrl };
}

function countMap(values) {
  return Object.fromEntries(values.map(({ name, count }) => [name, count]));
}
