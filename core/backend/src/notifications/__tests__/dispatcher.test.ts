import { describe, expect, it } from "vitest";
import { dailySignalDigestEmail } from "../../email/templates/daily-signal-digest.template.js";

describe("dailySignalDigestEmail", () => {
  it("encodes BUY count in subject when there are buys", () => {
    const out = dailySignalDigestEmail({
      recipientName: "Pro",
      signalDate: "2026-05-19",
      rows: [
        { symbol: "NABIL", name: "Nabil Bank", action: "BUY", closeNpr: "526.00", suggestedLimitNpr: "520.74", rationale: "NORMAL DCA" },
        { symbol: "NLIC", name: "Nepal Life", action: "BUY", closeNpr: "761.50", suggestedLimitNpr: "753.89", rationale: "NORMAL DCA" },
      ],
    });
    expect(out.subject).toMatch(/2 buys suggested/);
    expect(out.html).toContain("NABIL");
    expect(out.html).toContain("520.74");
    expect(out.text).toContain("NABIL");
  });

  it("encodes no-buys state when only wait/skip present", () => {
    const out = dailySignalDigestEmail({
      recipientName: null,
      signalDate: "2026-05-19",
      rows: [
        { symbol: "FOO", name: "Foo Ltd", action: "WAIT", closeNpr: "100.00", suggestedLimitNpr: null, rationale: "Weak month, above MA20" },
      ],
    });
    expect(out.subject).toMatch(/no buys today/);
    expect(out.subject).toMatch(/1 wait/);
  });

  it("html-escapes user-controlled fields", () => {
    const out = dailySignalDigestEmail({
      recipientName: "<script>",
      signalDate: "2026-05-19",
      rows: [
        { symbol: "<x>", name: "Test", action: "BUY", closeNpr: "1", suggestedLimitNpr: "1", rationale: "ok" },
      ],
    });
    expect(out.html).not.toContain("<script>");
    expect(out.html).toContain("&lt;script&gt;");
    expect(out.html).toContain("&lt;x&gt;");
  });
});
