import { request, Agent } from "undici";
import { load } from "cheerio";
import { logger } from "../../lib/logger.js";

const DEFAULT_BASE = "https://www.sharesansar.com";
const DEFAULT_UA =
  "Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0";

/**
 * One dividend-history row as returned by ShareSansar's
 * `POST /company-dividend` DataTables endpoint.
 */
export interface ShareSansarDividendRow {
  /** Bonus share percent (e.g., "12.00"). Empty string when no bonus that FY. */
  bonusShare: string;
  /** Cash dividend percent (e.g., "22.00"). */
  cashDividend: string;
  /** Sum bonus + cash (their pre-computed field). */
  totalDividend: string;
  /** YYYY-MM-DD when the dividend was announced. */
  announcementDate: string;
  /** YYYY-MM-DD when the bookclose ran (may include " [Closed]" suffix). */
  bookCloseDate: string;
  /** Nepali fiscal year in BS, e.g., "2081/2082". */
  fiscalYear: string;
}

export interface ShareSansarOptions {
  baseUrl?: string;
  userAgent?: string;
  timeoutMs?: number;
}

/**
 * ShareSansar's company page exposes a DataTables-backed JSON endpoint with
 * full dividend history (cash + bonus) per company. We auth by:
 *  1. GET `/company/<symbol>` to receive a session cookie + extract the
 *     CSRF `_token` (meta tag) and the internal `companyid` numeric.
 *  2. POST `/company-dividend` with `company=<id>` body, X-CSRF-TOKEN header,
 *     and the session cookie.
 *
 * Returns the full history (typically 10-15 fiscal years).
 */
export class ShareSansarAdapter {
  private readonly baseUrl: string;
  private readonly userAgent: string;
  private readonly timeoutMs: number;
  private readonly agent: Agent;

  constructor(opts: ShareSansarOptions = {}) {
    this.baseUrl = opts.baseUrl ?? DEFAULT_BASE;
    this.userAgent = opts.userAgent ?? DEFAULT_UA;
    this.timeoutMs = opts.timeoutMs ?? 30_000;
    this.agent = new Agent({ connect: { timeout: this.timeoutMs } });
  }

  async fetchDividendHistory(symbol: string): Promise<ShareSansarDividendRow[]> {
    const sym = symbol.toLowerCase();
    // Step 1: fetch the company page to get _token + companyid + session cookie.
    const pageUrl = `${this.baseUrl}/company/${sym}`;
    const pageRes = await request(pageUrl, {
      method: "GET",
      headers: { "User-Agent": this.userAgent, Accept: "text/html" },
      dispatcher: this.agent,
      headersTimeout: this.timeoutMs,
      bodyTimeout: this.timeoutMs,
    });
    if (pageRes.statusCode !== 200) {
      throw new Error(`ShareSansar GET /company/${sym} → HTTP ${pageRes.statusCode}`);
    }
    const html = await pageRes.body.text();
    const setCookie = pageRes.headers["set-cookie"];
    const cookieHeader = Array.isArray(setCookie)
      ? setCookie.map((c) => c.split(";")[0]).join("; ")
      : (setCookie ?? "").split(";")[0];

    const $ = load(html);
    const token = $('meta[name="_token"]').attr("content");
    const companyId = $("#companyid").text().trim();
    if (!token || !companyId) {
      throw new Error(`ShareSansar /company/${sym}: missing token (${!!token}) or companyId (${companyId})`);
    }

    // Step 2: POST to the dividend endpoint with DataTables-style params.
    const body = new URLSearchParams();
    body.set("company", companyId);
    body.set("_token", token);
    body.set("draw", "1");
    body.set("start", "0");
    body.set("length", "100");

    const divRes = await request(`${this.baseUrl}/company-dividend`, {
      method: "POST",
      headers: {
        "User-Agent": this.userAgent,
        Accept: "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "X-CSRF-TOKEN": token,
        "X-Requested-With": "XMLHttpRequest",
        Referer: pageUrl,
        Origin: this.baseUrl,
        Cookie: cookieHeader,
      },
      body: body.toString(),
      dispatcher: this.agent,
      headersTimeout: this.timeoutMs,
      bodyTimeout: this.timeoutMs,
    });
    if (divRes.statusCode !== 200) {
      const text = await divRes.body.text();
      throw new Error(`ShareSansar POST /company-dividend → HTTP ${divRes.statusCode}: ${text.slice(0, 200)}`);
    }
    const json = (await divRes.body.json()) as ShareSansarDividendResponse;
    if (!json.data || !Array.isArray(json.data)) {
      logger.warn("ShareSansar dividend response missing data array", { symbol, recordsTotal: json.recordsTotal });
      return [];
    }
    return json.data.map((row) => ({
      bonusShare: (row.bonus_share ?? "").trim(),
      cashDividend: (row.cash_dividend ?? "").trim(),
      totalDividend: (row.total_dividend ?? "").trim(),
      announcementDate: (row.announcement_date ?? "").trim(),
      bookCloseDate: (row.bookclose_date ?? "").trim(),
      fiscalYear: (row.year ?? "").trim(),
    }));
  }
}

interface ShareSansarDividendResponse {
  draw: number;
  recordsTotal: number;
  recordsFiltered: number;
  data: ShareSansarDividendRowRaw[];
}

interface ShareSansarDividendRowRaw {
  bonus_share?: string;
  cash_dividend?: string;
  total_dividend?: string;
  announcement_date?: string;
  bookclose_date?: string;
  year?: string;
}

export function createShareSansarAdapter(opts: ShareSansarOptions = {}): ShareSansarAdapter {
  return new ShareSansarAdapter(opts);
}
