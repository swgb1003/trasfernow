const DEFAULT_BASE_URL = 'https://v3.football.api-sports.io';
const DEFAULT_RATE_LIMIT_RETRY_MS = 61_000;
const DEFAULT_MAX_RATE_LIMIT_RETRIES = 3;

// Server-side API boundary. The key must never be bundled into Flutter.
// See SPEC.md §24, §27, §28, §36.
export class ApiFootballClient {
  constructor({
    apiKey,
    fetchImpl = globalThis.fetch,
    baseUrl = DEFAULT_BASE_URL,
    sleepImpl = sleep,
    maxRateLimitRetries = DEFAULT_MAX_RATE_LIMIT_RETRIES,
    rateLimitRetryMs = DEFAULT_RATE_LIMIT_RETRY_MS,
    minimumRequestIntervalMs = 0,
    nowImpl = Date.now,
    onRateLimitRetry = () => {},
  }) {
    if (!apiKey) throw new Error('API_FOOTBALL_KEY is required.');
    if (typeof fetchImpl !== 'function') throw new Error('fetch is unavailable.');
    this.apiKey = apiKey;
    this.fetchImpl = fetchImpl;
    this.baseUrl = baseUrl;
    this.sleepImpl = sleepImpl;
    this.maxRateLimitRetries = maxRateLimitRetries;
    this.rateLimitRetryMs = rateLimitRetryMs;
    this.minimumRequestIntervalMs = minimumRequestIntervalMs;
    this.nowImpl = nowImpl;
    this.onRateLimitRetry = onRateLimitRetry;
    this.lastRequestStartedAt = null;
    this.lastQuota = null;
  }

  async getTeams({ league, season }) {
    return this.#get('/teams', { league, season });
  }

  async getTransfers({ team }) {
    return this.#get('/transfers', { team });
  }

  async #get(path, parameters) {
    const url = new URL(path, this.baseUrl);
    for (const [name, value] of Object.entries(parameters)) {
      if (value !== undefined && value !== null) {
        url.searchParams.set(name, String(value));
      }
    }

    for (let attempt = 0; ; attempt += 1) {
      await this.#waitForRequestSlot();
      const response = await this.fetchImpl(url, {
        headers: { 'x-apisports-key': this.apiKey },
      });
      this.lastQuota = {
        remaining: response.headers.get('x-ratelimit-requests-remaining'),
        limit: response.headers.get('x-ratelimit-requests-limit'),
      };

      let payload;
      try {
        payload = await response.json();
      } catch (_) {
        throw new Error(`API-Football returned invalid JSON (${response.status}).`);
      }

      if (response.status === 429 && attempt < this.maxRateLimitRetries) {
        const waitMs = Math.max(
          retryDelayMs(response, this.rateLimitRetryMs),
          this.rateLimitRetryMs,
        );
        this.onRateLimitRetry({
          attempt: attempt + 1,
          maxAttempts: this.maxRateLimitRetries,
          waitMs,
        });
        await this.sleepImpl(waitMs);
        continue;
      }
      if (!response.ok) {
        throw new Error(
          `API-Football request failed (${response.status}): ${formatApiErrors(payload?.errors)}`,
        );
      }
      const apiErrors = collectApiErrors(payload?.errors);
      if (isRateLimitError(apiErrors) && attempt < this.maxRateLimitRetries) {
        const waitMs = this.rateLimitRetryMs;
        this.onRateLimitRetry({
          attempt: attempt + 1,
          maxAttempts: this.maxRateLimitRetries,
          waitMs,
        });
        await this.sleepImpl(waitMs);
        continue;
      }
      if (apiErrors.length > 0) {
        throw new Error(`API-Football error: ${apiErrors.join('; ')}`);
      }
      if (!Array.isArray(payload?.response)) {
        throw new Error('API-Football response must contain an array.');
      }
      return payload.response;
    }
  }

  async #waitForRequestSlot() {
    if (this.lastRequestStartedAt !== null) {
      const elapsedMs = this.nowImpl() - this.lastRequestStartedAt;
      const waitMs = this.minimumRequestIntervalMs - elapsedMs;
      if (waitMs > 0) await this.sleepImpl(waitMs);
    }
    this.lastRequestStartedAt = this.nowImpl();
  }
}

function retryDelayMs(response, fallbackMs) {
  const retryAfterSeconds = Number(response.headers.get('retry-after'));
  if (Number.isFinite(retryAfterSeconds) && retryAfterSeconds > 0) {
    return Math.ceil(retryAfterSeconds * 1000) + 1000;
  }
  return fallbackMs;
}

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function isRateLimitError(messages) {
  return messages.some((message) =>
    /too many requests|rate limit|requests per minute/i.test(message),
  );
}

function collectApiErrors(value) {
  if (Array.isArray(value)) return value.filter(Boolean).map(String);
  if (value && typeof value === 'object') {
    return Object.values(value).filter(Boolean).map(String);
  }
  if (value) return [String(value)];
  return [];
}

function formatApiErrors(value) {
  const messages = collectApiErrors(value);
  return messages.length > 0 ? messages.join('; ') : 'unknown error';
}
