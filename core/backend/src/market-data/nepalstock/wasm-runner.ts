import { readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const WASM_PATH = resolve(__dirname, "./assets/css.wasm");

/**
 * Functions exported by nepalstock.com.np's css.wasm. Each takes five i32
 * salts and returns one i32 character index into the access/refresh token.
 * Inputs are unsigned integers; outputs are non-negative integers.
 */
export interface WasmExports {
  cdx: (s1: number, s2: number, s3: number, s4: number, s5: number) => number;
  rdx: (s1: number, s2: number, s3: number, s4: number, s5: number) => number;
  bdx: (s1: number, s2: number, s3: number, s4: number, s5: number) => number;
  ndx: (s1: number, s2: number, s3: number, s4: number, s5: number) => number;
  mdx: (s1: number, s2: number, s3: number, s4: number, s5: number) => number;
}

let cached: WasmExports | null = null;

export async function loadWasm(): Promise<WasmExports> {
  if (cached) return cached;
  const bytes = await readFile(WASM_PATH);
  const mod = await WebAssembly.compile(bytes);
  const instance = await WebAssembly.instantiate(mod, {});
  cached = instance.exports as unknown as WasmExports;
  return cached;
}
