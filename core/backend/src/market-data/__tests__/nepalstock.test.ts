import { readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it, vi } from "vitest";
import { parseTokenResponse } from "../nepalstock/token-parser.js";
import { TokenManager } from "../nepalstock/token-manager.js";
import { NepalStockAdapter } from "../nepalstock/adapter.js";
import type { NepalStockHttpClient } from "../nepalstock/http-client.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const fixturesDir = resolve(__dirname, "./fixtures");

async function loadFixture<T>(name: string): Promise<T> {
  const raw = await readFile(resolve(fixturesDir, name), "utf-8");
  return JSON.parse(raw) as T;
}

describe("nepalstock token-parser", () => {
  it("produces tokens that are 5 chars shorter than the input", async () => {
    const proveResponse = await loadFixture<Parameters<typeof parseTokenResponse>[0]>("auth-prove.json");
    const parsed = await parseTokenResponse(proveResponse);
    expect(parsed.accessToken.length).toBe(proveResponse.accessToken.length - 5);
    expect(parsed.refreshToken.length).toBe(proveResponse.refreshToken.length - 5);
    expect(parsed.salts).toHaveLength(5);
    expect(parsed.serverTimeSec).toBe(Math.floor(proveResponse.serverTime / 1000));
  });

  it("is deterministic for identical input", async () => {
    const proveResponse = await loadFixture<Parameters<typeof parseTokenResponse>[0]>("auth-prove.json");
    const a = await parseTokenResponse(proveResponse);
    const b = await parseTokenResponse(proveResponse);
    expect(a.accessToken).toBe(b.accessToken);
    expect(a.refreshToken).toBe(b.refreshToken);
  });
});

describe("nepalstock TokenManager", () => {
  it("caches the token within the 40s window", async () => {
    const proveResponse = await loadFixture<Parameters<typeof parseTokenResponse>[0]>("auth-prove.json");
    let calls = 0;
    const fakeClient = {
      fetchJson: vi.fn(async () => {
        calls += 1;
        return proveResponse;
      }),
    };
    // Pin "now" to the response's serverTime + 10s
    const fixedNowSec = Math.floor(proveResponse.serverTime / 1000) + 10;
    const tm = new TokenManager(fakeClient as never, () => fixedNowSec);
    const t1 = await tm.getAccessToken();
    const t2 = await tm.getAccessToken();
    expect(t1).toBe(t2);
    expect(calls).toBe(1);
  });

  it("refreshes after age > 40s", async () => {
    const proveResponse = await loadFixture<Parameters<typeof parseTokenResponse>[0]>("auth-prove.json");
    let calls = 0;
    const fakeClient = {
      fetchJson: vi.fn(async () => {
        calls += 1;
        return proveResponse;
      }),
    };
    // Start "now" 5s after the response's serverTime so age = 5s (< 40s).
    let nowSec = Math.floor(proveResponse.serverTime / 1000) + 5;
    const tm = new TokenManager(fakeClient as never, () => nowSec);
    await tm.getAccessToken();
    nowSec += 60; // age now 65s — should trigger refresh
    await tm.getAccessToken();
    expect(calls).toBe(2);
  });
});

describe("NepalStockAdapter price parsing", () => {
  it("transforms price-volume rows into PriceQuotes (close-only)", async () => {
    const priceVolume = await loadFixture("price-volume.json");
    const securityList = await loadFixture("security-list.json");

    const fakeHttp = {
      fetchAuthed: vi.fn(async (path: string) => {
        if (path.includes("securityDailyTradeStat")) return priceVolume;
        if (path.includes("security")) return securityList;
        throw new Error(`unexpected path ${path}`);
      }),
    } as unknown as NepalStockHttpClient;

    // Pin "now" so tradeDate is deterministic
    const adapter = new NepalStockAdapter(fakeHttp, () => new Date("2026-05-19T00:00:00Z"));
    const listings = await adapter.fetchSecurityList();
    const quotes = await adapter.fetchTodayPrices();

    expect(listings).toHaveLength(3);
    expect(listings.map((l) => l.symbol)).toEqual(["NABIL", "NLIC", "CHDC"]);
    expect(listings[0].sourceSecurityId).toBe(131);
    expect(listings[0].sector).toBeNull(); // not provided by this endpoint

    expect(quotes).toHaveLength(3);
    const nabil = quotes.find((q) => q.symbol === "NABIL")!;
    expect(nabil.close).toBe("526");
    expect(nabil.open).toBe(nabil.close); // OHL filled with close
    expect(nabil.volume).toBe(41228n);
    expect(nabil.tradeDate.toISOString()).toBe("2026-05-19T00:00:00.000Z");

    const nlic = quotes.find((q) => q.symbol === "NLIC")!;
    expect(nlic.close).toBe("761.5"); // decimal preserved
  });

  it("paginates and parses price history", async () => {
    const history = await loadFixture("price-history.json");
    const fakeHttp = {
      fetchAuthed: vi.fn(async (path: string) => {
        if (path.includes("/market/history/security/131")) return history;
        throw new Error(`unexpected path ${path}`);
      }),
    } as unknown as NepalStockHttpClient;

    const adapter = new NepalStockAdapter(fakeHttp);
    const rows = await adapter.fetchPriceHistory({
      sourceSecurityId: 131,
      symbol: "NABIL",
      startDate: new Date("2026-05-13T00:00:00Z"),
      endDate: new Date("2026-05-19T00:00:00Z"),
    });

    expect(rows).toHaveLength(3);
    expect(rows[0].tradeDate.toISOString()).toBe("2026-05-18T00:00:00.000Z");
    expect(rows[0].close).toBe("526");
    expect(rows[0].high).toBe("532");
    expect(rows[0].low).toBe("525");
    expect(rows[0].open).toBe(rows[0].close); // open not in source — fill with close
    expect(rows[0].volume).toBe(44305n);
    // Should call once because last=true
    expect((fakeHttp.fetchAuthed as ReturnType<typeof vi.fn>).mock.calls).toHaveLength(1);
  });
});
