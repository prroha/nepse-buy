import { readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { MeroLaganiAdapter } from "../merolagani/adapter.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const fixturesDir = resolve(__dirname, "./fixtures");

async function loadHtml(name: string): Promise<string> {
  return readFile(resolve(fixturesDir, name), "utf-8");
}

describe("MeroLaganiAdapter parsing", () => {
  it("extracts snapshot fundamentals from a real company page", async () => {
    const html = await loadHtml("merolagani-nabil.html");
    const adapter = new MeroLaganiAdapter({ userAgent: "test" });
    const quote = adapter.parse("NABIL", html);

    expect(quote).not.toBeNull();
    expect(quote!.symbol).toBe("NABIL");
    expect(quote!.pe).toBe("15.78");
    expect(quote!.pb).toBe("2.16");
    expect(quote!.eps).toBe("33.34");
    expect(quote!.bookValue).toBe("243.30");
    expect(quote!.marketCap).toBe("142319804220.00");
    // Annotation "(FY:082-083, Q:3)" stripped from EPS value, captured separately
    expect(quote!.epsFiscalContext).toMatch(/FY:082-083/);
    expect(quote!.parseConfidence).toBe("1.00");
  });

  it("returns null for HTML that has no info rows", async () => {
    const adapter = new MeroLaganiAdapter({ userAgent: "test" });
    const quote = adapter.parse("NABIL", "<html><body>Just text, no tables.</body></html>");
    expect(quote).toBeNull();
  });

  it("handles missing fields gracefully via parseConfidence", async () => {
    const adapter = new MeroLaganiAdapter({ userAgent: "test" });
    // Synthetic page: only P/E label present
    const partial = `<table><tr><th>P/E Ratio</th><td>12.50</td></tr></table>`;
    const quote = adapter.parse("FOO", partial);
    expect(quote).not.toBeNull();
    expect(quote!.pe).toBe("12.50");
    expect(quote!.pb).toBeNull();
    expect(quote!.eps).toBeNull();
    expect(quote!.parseConfidence).toBe("0.20"); // 1 of 5
  });
});
