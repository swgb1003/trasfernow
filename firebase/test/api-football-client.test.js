import assert from 'node:assert/strict';
import test from 'node:test';

import { ApiFootballClient } from '../api-football-client.js';

test('sends the API key only as a header and reports quota', async () => {
  let captured;
  const client = new ApiFootballClient({
    apiKey: 'secret-test-key',
    fetchImpl: async (url, options) => {
      captured = { url, options };
      return fakeResponse({ response: [{ team: { id: 39 } }] }, {
        'x-ratelimit-requests-remaining': '98',
        'x-ratelimit-requests-limit': '100',
      });
    },
  });

  const response = await client.getTeams({ league: 39, season: 2024 });

  assert.equal(response.length, 1);
  assert.equal(captured.options.headers['x-apisports-key'], 'secret-test-key');
  assert.equal(captured.url.searchParams.get('league'), '39');
  assert.equal(captured.url.toString().includes('secret-test-key'), false);
  assert.deepEqual(client.lastQuota, { remaining: '98', limit: '100' });
});

test('turns API-level errors into a stable failure', async () => {
  const client = new ApiFootballClient({
    apiKey: 'secret-test-key',
    fetchImpl: async () => fakeResponse({ errors: { plan: 'Season unavailable' } }),
  });

  await assert.rejects(
    client.getTransfers({ team: 42 }),
    /API-Football error: Season unavailable/,
  );
});

test('waits and retries a per-minute rate limit response', async () => {
  let requestCount = 0;
  const waits = [];
  const retries = [];
  const client = new ApiFootballClient({
    apiKey: 'secret-test-key',
    fetchImpl: async () => {
      requestCount += 1;
      if (requestCount === 1) {
        return fakeResponse(
          { errors: { rateLimit: 'Too many requests' } },
          { 'retry-after': '2' },
          { ok: false, status: 429 },
        );
      }
      return fakeResponse({ response: [{ player: { id: 7 } }] });
    },
    sleepImpl: async (milliseconds) => waits.push(milliseconds),
    rateLimitRetryMs: 1000,
    onRateLimitRetry: (retry) => retries.push(retry),
  });

  const response = await client.getTransfers({ team: 42 });

  assert.equal(response.length, 1);
  assert.equal(requestCount, 2);
  assert.deepEqual(waits, [3000]);
  assert.deepEqual(retries, [{ attempt: 1, maxAttempts: 3, waitMs: 3000 }]);
});

test('retries a rate limit reported inside a successful response', async () => {
  let requestCount = 0;
  const waits = [];
  const client = new ApiFootballClient({
    apiKey: 'secret-test-key',
    fetchImpl: async () => {
      requestCount += 1;
      if (requestCount === 1) {
        return fakeResponse({
          errors: { rateLimit: 'Your rate limit is 10 requests per minute.' },
        });
      }
      return fakeResponse({ response: [{ player: { id: 8 } }] });
    },
    sleepImpl: async (milliseconds) => waits.push(milliseconds),
    rateLimitRetryMs: 1000,
  });

  const response = await client.getTransfers({ team: 42 });

  assert.equal(response.length, 1);
  assert.equal(requestCount, 2);
  assert.deepEqual(waits, [1000]);
});

test('paces consecutive requests below the free-plan per-minute limit', async () => {
  let now = 0;
  const requestTimes = [];
  const waits = [];
  const client = new ApiFootballClient({
    apiKey: 'secret-test-key',
    fetchImpl: async () => {
      requestTimes.push(now);
      return fakeResponse({ response: [] });
    },
    sleepImpl: async (milliseconds) => {
      waits.push(milliseconds);
      now += milliseconds;
    },
    minimumRequestIntervalMs: 7000,
    nowImpl: () => now,
  });

  await client.getTeams({ league: 39, season: 2024 });
  await client.getTransfers({ team: 42 });

  assert.deepEqual(requestTimes, [0, 7000]);
  assert.deepEqual(waits, [7000]);
});

function fakeResponse(payload, headerValues = {}, overrides = {}) {
  return {
    ok: true,
    status: 200,
    headers: { get: (name) => headerValues[name] ?? null },
    json: async () => ({ errors: [], response: [], ...payload }),
    ...overrides,
  };
}
