/**
 * Pure moving-average computation.
 *
 * Input is an array of close prices ordered most-recent-first
 * (oldest-last). Returns the mean of the most recent `windowSize` entries
 * as a numeric string (4-decimal precision), or null if fewer than
 * `minSamples` entries are available.
 */
export function movingAverage(
  recentCloses: ReadonlyArray<string | number>,
  windowSize: number,
  minSamples: number,
): { value: string; samplesUsed: number } | { value: null; samplesUsed: number } {
  const window = recentCloses.slice(0, windowSize);
  if (window.length < minSamples) {
    return { value: null, samplesUsed: window.length };
  }
  let sum = 0;
  for (const c of window) sum += typeof c === "string" ? parseFloat(c) : c;
  const mean = sum / window.length;
  return { value: mean.toFixed(4), samplesUsed: window.length };
}
