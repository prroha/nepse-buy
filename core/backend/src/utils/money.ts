/**
 * Money helpers for converting Prisma Decimal values to numbers at the API
 * boundary. Storage is Decimal (precise); the API contract surfaces numbers
 * for backwards compatibility with existing clients.
 *
 * Fixes MED-14: monetary fields previously used `Float` storage which is not
 * safe for currency math. This switches storage to Decimal(12,2) and
 * normalizes back to JS numbers only where the data leaves Prisma.
 *
 * Note: in-app aggregation (e.g., summing across days) still uses JS numbers
 * after conversion; precision is preserved within ~15 significant digits,
 * which is more than enough for typical order amounts. Aggregations performed
 * inside Prisma (`_sum`, `_avg`) are computed in the database in Decimal
 * precision and only converted to number after the result returns.
 */

import { Prisma } from "@prisma/client";

type DecimalLike = Prisma.Decimal | number | null | undefined;

/**
 * Convert a single Decimal/number/nullable to number. Null and undefined
 * become 0 (callers can override by passing a default).
 */
export function toNumber(value: DecimalLike, defaultValue = 0): number {
  if (value === null || value === undefined) return defaultValue;
  return typeof value === "number" ? value : value.toNumber();
}

/**
 * Map money-typed fields on an object/Prisma row from Decimal to number.
 * Used at service-layer return boundaries so consumers see plain numbers.
 */
export function normalizeMoneyFields<T extends Record<string, unknown>>(
  obj: T,
  fields: readonly string[],
): T {
  const result = { ...obj } as Record<string, unknown>;
  for (const field of fields) {
    if (field in result) {
      result[field] = toNumber(result[field] as DecimalLike);
    }
  }
  return result as T;
}

export const ORDER_MONEY_FIELDS = ["subtotal", "discount", "total"] as const;
export const COUPON_MONEY_FIELDS = ["discountValue", "minPurchase"] as const;
