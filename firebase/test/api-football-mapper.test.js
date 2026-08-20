import assert from 'node:assert/strict';
import test from 'node:test';

import {
  normalizeTransferEntries,
  parseFeeMillionsEur,
} from '../api-football-mapper.js';

test('normalizes in/out transfers, filters seasons and removes duplicates', () => {
  const sharedTransfer = {
    date: '2024-08-10',
    type: '€45M',
    teams: {
      out: { id: 10, name: 'Outside FC', logo: 'https://example.test/out.png' },
      in: { id: 42, name: 'Premier FC', logo: 'https://example.test/in.png' },
    },
  };
  const result = normalizeTransferEntries(
    [
      {
        player: { id: 7, name: 'Test Player' },
        update: '2024-08-11T10:00:00Z',
        transfers: [sharedTransfer, { ...sharedTransfer, date: '2023-08-10' }],
      },
      {
        player: { id: 7, name: 'Test Player' },
        update: '2024-08-12T10:00:00Z',
        transfers: [sharedTransfer],
      },
    ],
    { leagueTeamIds: [42], season: 2024 },
  );

  assert.equal(result.length, 1);
  assert.equal(result[0].externalId, 'api-football-7-2024-08-10-10-42');
  assert.equal(result[0].premierLeagueDirection, 'in');
  assert.equal(result[0].estimatedFeeMillionsEur, 45);
  assert.equal(result[0].providerUpdatedAt.toISOString(), '2024-08-12T10:00:00.000Z');
});

test('parses only explicit euro fees without guessing exchange rates', () => {
  assert.equal(parseFeeMillionsEur('€ 1.5M'), 1.5);
  assert.equal(parseFeeMillionsEur('€850K'), 0.85);
  assert.equal(parseFeeMillionsEur('€1000000'), 1);
  assert.equal(parseFeeMillionsEur('Loan'), null);
  assert.equal(parseFeeMillionsEur('£45M'), null);
});

test('ignores malformed and out-of-scope entries', () => {
  const result = normalizeTransferEntries(
    [
      { player: { id: null, name: 'Missing ID' }, transfers: [] },
      {
        player: { id: 1, name: 'Outside Player' },
        transfers: [
          {
            date: '2024-09-01',
            type: 'Free',
            teams: {
              out: { id: 8, name: 'Outside A' },
              in: { id: 9, name: 'Outside B' },
            },
          },
        ],
      },
    ],
    { leagueTeamIds: [42], season: 2024 },
  );

  assert.deepEqual(result, []);
});

test('excludes loan returns by default while keeping ordinary loans', () => {
  const baseTeams = {
    out: { id: 8, name: 'Outside FC' },
    in: { id: 42, name: 'Premier FC' },
  };
  const entries = [
    {
      player: { id: 1, name: 'Returning Player' },
      transfers: [
        { date: '2024-08-01', type: 'Return from loan', teams: baseTeams },
      ],
    },
    {
      player: { id: 2, name: 'Loan Player' },
      transfers: [{ date: '2024-08-02', type: 'Loan', teams: baseTeams }],
    },
    {
      player: { id: 3, name: 'Back from Loan Player' },
      transfers: [
        { date: '2024-08-03', type: 'Back from Loan', teams: baseTeams },
      ],
    },
  ];

  const filtered = normalizeTransferEntries(entries, {
    leagueTeamIds: [42],
    season: 2024,
  });
  const unfiltered = normalizeTransferEntries(entries, {
    leagueTeamIds: [42],
    season: 2024,
    includeLoanReturns: true,
  });

  assert.deepEqual(filtered.map((record) => record.playerName), ['Loan Player']);
  assert.equal(unfiltered.length, 3);
});
