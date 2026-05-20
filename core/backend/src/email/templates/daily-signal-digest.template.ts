import { baseTemplate, emailHeading, emailParagraph, emailMutedText, htmlToPlainText, type EmailOutput } from "./base.template.js";

export interface DigestSignalRow {
  symbol: string;
  name: string;
  action: "BUY" | "WAIT" | "SKIP" | "HOLD_FUNDS" | "HARVEST";
  closeNpr: string;
  suggestedLimitNpr: string | null;
  rationale: string;
}

export interface DailySignalDigestData {
  recipientName: string | null;
  /** ISO-ish date string (YYYY-MM-DD). */
  signalDate: string;
  rows: DigestSignalRow[];
}

const ACTION_COLOR: Record<DigestSignalRow["action"], string> = {
  BUY: "#15803d", // green
  WAIT: "#a16207", // amber
  SKIP: "#6b7280", // grey
  HOLD_FUNDS: "#1e3a8a", // navy — "money sitting on the sideline"
  HARVEST: "#7e22ce", // purple — realised-gain trigger
};

/**
 * Renders the daily DCA signal digest. Plain-text fallback is auto-derived.
 *
 * Sections in order:
 *  - BUY     — actionable today; show suggested limit price
 *  - WAIT    — close above 20-day MA or other gates; check again tomorrow
 *  - SKIP    — no usable data
 *
 * Subject reflects how many BUY signals are in the digest so the inbox preview
 * tells the user whether they need to act today.
 */
export function dailySignalDigestEmail(data: DailySignalDigestData): EmailOutput & { subject: string } {
  const harvests = data.rows.filter((r) => r.action === "HARVEST");
  const buys = data.rows.filter((r) => r.action === "BUY");
  const waits = data.rows.filter((r) => r.action === "WAIT");
  const skips = data.rows.filter((r) => r.action === "SKIP");
  const holds = data.rows.filter((r) => r.action === "HOLD_FUNDS");

  let subject: string;
  if (harvests.length > 0) {
    subject = `NEPSE signals for ${data.signalDate} — ${harvests.length} harvest candidate${harvests.length === 1 ? "" : "s"} (≥30% gain)`;
  } else if (holds.length > 0 && buys.length === 0) {
    subject = `NEPSE signals for ${data.signalDate} — strong season, sweep to OD loan (${holds.length} stock${holds.length === 1 ? "" : "s"} on hold)`;
  } else if (buys.length === 0) {
    subject = `NEPSE signals for ${data.signalDate} — no buys today (${waits.length} wait, ${skips.length} skip)`;
  } else {
    subject = `NEPSE signals for ${data.signalDate} — ${buys.length} buy${buys.length === 1 ? "" : "s"} suggested`;
  }

  const greeting = data.recipientName ? `Hello ${escapeHtml(data.recipientName)},` : "Hello,";

  const sections: string[] = [
    emailHeading("Today's NEPSE signals"),
    emailParagraph(greeting),
    emailParagraph(`Date: <strong>${escapeHtml(data.signalDate)}</strong>`),
    renderSection("Harvest", harvests, false),
    renderSection("Buy", buys, true),
    renderSection("Hold funds", holds, false),
    renderSection("Wait", waits, false),
    renderSection("Skip", skips, false),
    emailMutedText(
      "Signals are advisory. Engine v0.2 uses 20-day MA + seasonality (Jan/Jul/Aug strong → OD sweep). " +
      "P/E gate disabled pending historical median data."
    ),
  ];

  const html = baseTemplate({
    content: sections.join("\n"),
    previewText: subject,
  });
  return {
    html,
    text: htmlToPlainText(html),
    subject,
  };
}

function renderSection(label: string, rows: DigestSignalRow[], showLimit: boolean): string {
  if (rows.length === 0) return "";
  const color = ACTION_COLOR[rows[0].action];
  const tag = `<span style="background:${color};color:white;padding:2px 8px;border-radius:4px;font-weight:600;">${label.toUpperCase()}</span>`;
  const items = rows
    .map((r) => {
      const limit = showLimit && r.suggestedLimitNpr ? ` · suggested limit <strong>Rs ${escapeHtml(r.suggestedLimitNpr)}</strong>` : "";
      return `<li style="margin:8px 0;">
        <strong>${escapeHtml(r.symbol)}</strong> — Rs ${escapeHtml(r.closeNpr)}${limit}
        <div style="color:#475569;font-size:14px;margin-top:2px;">${escapeHtml(r.rationale)}</div>
      </li>`;
    })
    .join("\n");
  return `<div style="margin:24px 0;">
    <div style="margin-bottom:8px;">${tag} <span style="color:#64748b;font-size:14px;">(${rows.length})</span></div>
    <ul style="padding-left:20px;margin:0;">${items}</ul>
  </div>`;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
