import { loadWasm } from "./wasm-runner.js";

export interface TokenProveResponse {
  serverTime: number;
  accessToken: string;
  refreshToken: string;
  salt1: number;
  salt2: number;
  salt3: number;
  salt4: number;
  salt5: number;
}

export interface ParsedTokens {
  accessToken: string;
  refreshToken: string;
  /** Server time in seconds (truncated from ms). */
  serverTimeSec: number;
  salts: [number, number, number, number, number];
}

/**
 * Replicates basic-bgnr/NepseUnofficialApi's TokenParser.parse_token_response.
 * The WASM yields five character indices; we slice them out of accessToken
 * (and a different five out of refreshToken) to produce the bearer tokens.
 */
export async function parseTokenResponse(r: TokenProveResponse): Promise<ParsedTokens> {
  const w = await loadWasm();
  const { salt1: s1, salt2: s2, salt3: s3, salt4: s4, salt5: s5 } = r;

  // Indices into accessToken (must be ascending).
  const n = w.cdx(s1, s2, s3, s4, s5);
  const l = w.rdx(s1, s2, s4, s3, s5);
  const o = w.bdx(s1, s2, s4, s3, s5);
  const p = w.ndx(s1, s2, s4, s3, s5);
  const q = w.mdx(s1, s2, s4, s3, s5);

  // Indices into refreshToken (different salt orderings).
  const a = w.cdx(s2, s1, s3, s5, s4);
  const b = w.rdx(s2, s1, s3, s4, s5);
  const c = w.bdx(s2, s1, s4, s3, s5);
  const d = w.ndx(s2, s1, s4, s3, s5);
  const e = w.mdx(s2, s1, s4, s3, s5);

  const at = r.accessToken;
  const accessToken =
    at.slice(0, n) +
    at.slice(n + 1, l) +
    at.slice(l + 1, o) +
    at.slice(o + 1, p) +
    at.slice(p + 1, q) +
    at.slice(q + 1);

  const rt = r.refreshToken;
  const refreshToken =
    rt.slice(0, a) +
    rt.slice(a + 1, b) +
    rt.slice(b + 1, c) +
    rt.slice(c + 1, d) +
    rt.slice(d + 1, e) +
    rt.slice(e + 1);

  return {
    accessToken,
    refreshToken,
    serverTimeSec: Math.floor(r.serverTime / 1000),
    salts: [s1, s2, s3, s4, s5],
  };
}
