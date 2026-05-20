import { request, Agent } from "undici";
import { TokenManager, type RawJsonFetcher } from "./token-manager.js";

const DEFAULT_BASE = "https://www.nepalstock.com";

export interface NepalStockClientOptions {
  baseUrl?: string;
  userAgent: string;
  /** Request timeout in ms. */
  timeoutMs?: number;
  /** Disable TLS verification (only for local debugging). */
  insecureTls?: boolean;
}

class HttpError extends Error {
  constructor(public readonly status: number, public readonly path: string, public readonly bodySnippet: string) {
    super(`HTTP ${status} from ${path}: ${bodySnippet.slice(0, 200)}`);
  }
}

export class TokenExpiredError extends Error {
  constructor() {
    super("NEPSE token expired (401) — caller should retry once after invalidation");
  }
}

/**
 * Thin HTTP client over undici. Handles two roles via two methods:
 *   - `fetchUnauthed` for /authenticate/prove (no Authorization)
 *   - `fetchAuthed` for /api/nots/* (Authorization: Salter <token>)
 *
 * On 401 from an authed call we throw TokenExpiredError so the caller can
 * invalidate the TokenManager and retry once.
 */
export class NepalStockHttpClient implements RawJsonFetcher {
  private readonly baseUrl: string;
  private readonly userAgent: string;
  private readonly timeoutMs: number;
  private readonly agent: Agent;
  // Lazily wired by NepalStockAdapter so that TokenManager can use this client
  // for /authenticate/prove without a circular constructor dependency.
  private tokenManager: TokenManager | null = null;

  constructor(opts: NepalStockClientOptions) {
    this.baseUrl = opts.baseUrl ?? DEFAULT_BASE;
    this.userAgent = opts.userAgent;
    this.timeoutMs = opts.timeoutMs ?? 30_000;
    this.agent = new Agent({
      connect: {
        timeout: this.timeoutMs,
        rejectUnauthorized: opts.insecureTls ? false : true,
      },
    });
  }

  attachTokenManager(tm: TokenManager): void {
    this.tokenManager = tm;
  }

  /** RawJsonFetcher impl — used by TokenManager itself. */
  async fetchJson<T>(path: string): Promise<T> {
    return this.fetchUnauthed<T>(path);
  }

  async fetchUnauthed<T>(path: string): Promise<T> {
    return this.doGet<T>(path, this.baseHeaders());
  }

  async fetchAuthed<T>(path: string): Promise<T> {
    if (!this.tokenManager) {
      throw new Error("NepalStockHttpClient: tokenManager not attached");
    }
    const headers = this.baseHeaders();
    headers["Authorization"] = `Salter ${await this.tokenManager.getAccessToken()}`;
    try {
      return await this.doGet<T>(path, headers);
    } catch (err) {
      if (err instanceof HttpError && err.status === 401) {
        // One retry after invalidation — covers natural token expiry mid-flight.
        this.tokenManager.invalidate();
        headers["Authorization"] = `Salter ${await this.tokenManager.getAccessToken()}`;
        return await this.doGet<T>(path, headers);
      }
      throw err;
    }
  }

  private baseHeaders(): Record<string, string> {
    const host = this.baseUrl.replace(/^https?:\/\//, "");
    return {
      "User-Agent": this.userAgent,
      Accept: "application/json, text/plain, */*",
      "Accept-Language": "en-US,en;q=0.5",
      Referer: `${this.baseUrl}/`,
      Host: host,
      Pragma: "no-cache",
      "Cache-Control": "no-cache",
    };
  }

  private async doGet<T>(path: string, headers: Record<string, string>): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    const res = await request(url, {
      method: "GET",
      headers,
      dispatcher: this.agent,
      headersTimeout: this.timeoutMs,
      bodyTimeout: this.timeoutMs,
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      const body = await res.body.text();
      throw new HttpError(res.statusCode, path, body);
    }

    return (await res.body.json()) as T;
  }
}
