import { parseTokenResponse, type ParsedTokens, type TokenProveResponse } from "./token-parser.js";

/**
 * NEPSE rotates tokens roughly every 45s server-side. We refresh ahead of that.
 */
const MAX_AGE_SEC = 40;
const PROVE_PATH = "/api/authenticate/prove";

export interface RawJsonFetcher {
  /** Fetches JSON from an unauthenticated path (no Authorization header). */
  fetchJson<T>(path: string): Promise<T>;
}

/**
 * Concurrent-safe token holder. Multiple in-flight callers all await the same
 * refresh promise rather than each kicking off their own.
 */
export class TokenManager {
  private tokens: ParsedTokens | null = null;
  private inflight: Promise<ParsedTokens> | null = null;

  constructor(private readonly client: RawJsonFetcher, private readonly nowSec: () => number = () => Math.floor(Date.now() / 1000)) {}

  async getAccessToken(): Promise<string> {
    const t = await this.ensureFresh();
    return t.accessToken;
  }

  /** Exposed for jobs that need salts (e.g. POST payload generation, not needed for v1). */
  async getSalts(): Promise<readonly number[]> {
    const t = await this.ensureFresh();
    return t.salts;
  }

  /** Force-refresh on next call. Useful when a request unexpectedly returns 401. */
  invalidate(): void {
    this.tokens = null;
  }

  private async ensureFresh(): Promise<ParsedTokens> {
    if (this.tokens && this.nowSec() - this.tokens.serverTimeSec < MAX_AGE_SEC) {
      return this.tokens;
    }
    if (!this.inflight) {
      this.inflight = this.refresh().finally(() => {
        this.inflight = null;
      });
    }
    return this.inflight;
  }

  private async refresh(): Promise<ParsedTokens> {
    const res = await this.client.fetchJson<TokenProveResponse>(PROVE_PATH);
    const parsed = await parseTokenResponse(res);
    this.tokens = parsed;
    return parsed;
  }
}
