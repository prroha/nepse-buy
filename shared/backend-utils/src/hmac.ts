import crypto from "node:crypto";

/**
 * Sign an outgoing internal API request with HMAC-SHA256.
 * Used by studio backend when calling preview backend.
 */
export function signRequest(
  secret: string,
  method: string,
  path: string,
  body: string,
  timestamp: number
): string {
  const payload = `${method}:${path}:${body}:${timestamp}`;
  return crypto.createHmac("sha256", secret).update(payload).digest("hex");
}

/**
 * Create headers for an outgoing signed request.
 */
export function createSignedHeaders(
  secret: string,
  method: string,
  path: string,
  body: string
): Record<string, string> {
  const timestamp = Date.now();
  const signature = signRequest(secret, method, path, body, timestamp);
  return {
    "X-Internal-Signature": signature,
    "X-Internal-Timestamp": String(timestamp),
    "Content-Type": "application/json",
  };
}

/**
 * Verify an incoming signed request. Throws if invalid.
 * Used as a Fastify preHandler in preview backend internal routes.
 */
export function verifySignature(
  secret: string,
  signature: string,
  timestamp: number,
  method: string,
  path: string,
  body: string,
  maxAgeMs = 5 * 60 * 1000
): boolean {
  // Reject requests older than maxAge (replay protection)
  if (Math.abs(Date.now() - timestamp) > maxAgeMs) {
    return false;
  }

  const expected = signRequest(secret, method, path, body, timestamp);

  // Constant-time comparison
  if (signature.length !== expected.length) return false;
  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
}
