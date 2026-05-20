import { describe, expect, it, vi } from "vitest";
import { RateLimitError, jitteredSleep, withBackoff, withStalenessGate } from "../scraper-hygiene.js";

/** Minimal in-memory stand-in for the Prisma client used by withStalenessGate. */
function makeFakePrisma(initial: { lastSuccess?: Date; lastAttempt?: Date } | null = null) {
  const store = new Map<string, { lastAttempt: Date; lastSuccess?: Date | null; recordCount: number; lastError?: string | null }>();
  const key = (s: string, sym: string, scope: string) => `${s}|${sym}|${scope}`;
  if (initial) {
    store.set(key("SHARESANSAR", "NABIL", "dividend-history"), {
      lastAttempt: initial.lastAttempt ?? new Date(),
      lastSuccess: initial.lastSuccess ?? null,
      recordCount: 0,
    });
  }
  return {
    scrapeLog: {
      findUnique: async (q: { where: { source_symbol_scope: { source: string; symbol: string; scope: string } } }) => {
        const k = key(q.where.source_symbol_scope.source, q.where.source_symbol_scope.symbol, q.where.source_symbol_scope.scope);
        const v = store.get(k);
        return v ? { ...v } : null;
      },
      upsert: async (q: {
        where: { source_symbol_scope: { source: string; symbol: string; scope: string } };
        create: Record<string, unknown>;
        update: Record<string, unknown>;
      }) => {
        const k = key(q.where.source_symbol_scope.source, q.where.source_symbol_scope.symbol, q.where.source_symbol_scope.scope);
        const existing = store.get(k);
        const merged = (existing ? { ...existing, ...q.update } : q.create) as unknown as {
          lastAttempt: Date;
          lastSuccess?: Date | null;
          recordCount: number;
          lastError?: string | null;
        };
        store.set(k, merged);
        return merged;
      },
    },
  } as unknown as Parameters<typeof withStalenessGate>[3];
}

describe("withStalenessGate", () => {
  it("runs fn when no prior log exists", async () => {
    const prisma = makeFakePrisma(null);
    const fn = vi.fn(async () => ({ value: { foo: "bar" }, recordCount: 3 }));
    const r = await withStalenessGate("NABIL", { source: "SHARESANSAR", scope: "dividend-history" }, fn, prisma);
    expect(fn).toHaveBeenCalledOnce();
    expect(r.skipped).toBe(false);
    expect(r.result).toEqual({ foo: "bar" });
  });

  it("skips fn when prior success is within threshold", async () => {
    const recent = new Date(Date.now() - 5 * 86_400_000); // 5 days ago
    const prisma = makeFakePrisma({ lastSuccess: recent, lastAttempt: recent });
    const fn = vi.fn(async () => ({ value: "should-not-run", recordCount: 0 }));
    const r = await withStalenessGate(
      "NABIL",
      { source: "SHARESANSAR", scope: "dividend-history" }, // default 90d
      fn,
      prisma,
    );
    expect(fn).not.toHaveBeenCalled();
    expect(r.skipped).toBe(true);
    expect(r.reason).toMatch(/5\.\d+d old/);
  });

  it("runs fn when prior success is older than threshold", async () => {
    const stale = new Date(Date.now() - 120 * 86_400_000); // 120 days ago
    const prisma = makeFakePrisma({ lastSuccess: stale, lastAttempt: stale });
    const fn = vi.fn(async () => ({ value: "ran", recordCount: 1 }));
    const r = await withStalenessGate("NABIL", { source: "SHARESANSAR", scope: "dividend-history" }, fn, prisma);
    expect(fn).toHaveBeenCalledOnce();
    expect(r.skipped).toBe(false);
    expect(r.result).toBe("ran");
  });

  it("force: true bypasses the gate even with fresh prior", async () => {
    const recent = new Date(Date.now() - 1 * 86_400_000);
    const prisma = makeFakePrisma({ lastSuccess: recent, lastAttempt: recent });
    const fn = vi.fn(async () => ({ value: "forced", recordCount: 0 }));
    const r = await withStalenessGate(
      "NABIL",
      { source: "SHARESANSAR", scope: "dividend-history", force: true },
      fn,
      prisma,
    );
    expect(fn).toHaveBeenCalledOnce();
    expect(r.skipped).toBe(false);
  });

  it("maxStaleDays override beats the per-scope default", async () => {
    const recent = new Date(Date.now() - 2 * 86_400_000); // 2 days ago
    const prisma = makeFakePrisma({ lastSuccess: recent, lastAttempt: recent });
    const fn = vi.fn(async () => ({ value: "ran", recordCount: 0 }));
    // dividend-history default is 90d, but we override to 1d → 2d old is stale.
    const r = await withStalenessGate(
      "NABIL",
      { source: "SHARESANSAR", scope: "dividend-history", maxStaleDays: 1 },
      fn,
      prisma,
    );
    expect(fn).toHaveBeenCalledOnce();
    expect(r.skipped).toBe(false);
  });
});

describe("withBackoff", () => {
  it("returns immediately on first success", async () => {
    const fn = vi.fn(async () => 42);
    const r = await withBackoff(fn, 2, 1);
    expect(r).toBe(42);
    expect(fn).toHaveBeenCalledOnce();
  });

  it("retries on transient errors", async () => {
    let calls = 0;
    const fn = async () => {
      calls += 1;
      if (calls < 3) throw new Error("transient network");
      return "ok";
    };
    const r = await withBackoff(fn, 3, 1);
    expect(r).toBe("ok");
    expect(calls).toBe(3);
  });

  it("aborts immediately on HTTP 429", async () => {
    const fn = vi.fn(async () => {
      throw new Error("Mero Lagani HTTP 429 for NABIL: rate limited");
    });
    await expect(withBackoff(fn, 3, 1)).rejects.toBeInstanceOf(RateLimitError);
    expect(fn).toHaveBeenCalledOnce();
  });

  it("aborts immediately on HTTP 403", async () => {
    const fn = vi.fn(async () => {
      throw new Error("HTTP 403: forbidden");
    });
    await expect(withBackoff(fn, 3, 1)).rejects.toBeInstanceOf(RateLimitError);
    expect(fn).toHaveBeenCalledOnce();
  });
});

describe("jitteredSleep", () => {
  it("waits at least the minimum", async () => {
    const start = Date.now();
    await jitteredSleep(50, 100);
    const elapsed = Date.now() - start;
    expect(elapsed).toBeGreaterThanOrEqual(45);
    expect(elapsed).toBeLessThan(200);
  });
});
