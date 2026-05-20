import { Season } from "@prisma/client";

/**
 * Classify a date's month into one of the strategy's three buckets, using
 * the supplied IANA time zone (typically Asia/Kathmandu).
 *
 * Engine v0.2:
 *   - WEAK   : March, June, November — statistically softer; deploy on MA20 dips.
 *   - STRONG : January, July, August — seasonal liquidity / Shrawan-Bhadra retail FOMO.
 *              v0.2 changed action from BUY to HOLD_FUNDS (sweep to OD loan).
 *   - NORMAL : everything else — standard weekly DCA.
 */
const WEAK_MONTHS = new Set([3, 6, 11]);
const STRONG_MONTHS = new Set([1, 7, 8]);

export function classifySeason(date: Date, timezone: string): Season {
  // Render the month in the supplied tz so e.g. an early-morning UTC date in
  // November still classifies as NOVEMBER in NPT.
  const monthStr = new Intl.DateTimeFormat("en-US", {
    timeZone: timezone,
    month: "numeric",
  }).format(date);
  const month = parseInt(monthStr, 10);
  if (WEAK_MONTHS.has(month)) return "WEAK";
  if (STRONG_MONTHS.has(month)) return "STRONG";
  return "NORMAL";
}
