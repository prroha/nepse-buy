/// Dart port of `core/backend/src/signals/moving-average.ts`.
///
/// Input is most-recent-first (oldest-last). Returns the mean of the most
/// recent `windowSize` entries, or null if fewer than `minSamples` are
/// available. Matches the TS rounding (4 decimal places via doubles).
class MovingAverage {
  MovingAverage({required this.value, required this.samplesUsed});

  final double? value;
  final int samplesUsed;
}

MovingAverage movingAverage(
  List<double> recentCloses, {
  int windowSize = 20,
  required int minSamples,
}) {
  final window = recentCloses.length > windowSize
      ? recentCloses.sublist(0, windowSize)
      : recentCloses;
  if (window.length < minSamples) {
    return MovingAverage(value: null, samplesUsed: window.length);
  }
  var sum = 0.0;
  for (final c in window) {
    sum += c;
  }
  final mean = sum / window.length;
  // Round to 4 decimals to match the TS export.
  final rounded = (mean * 10000).round() / 10000;
  return MovingAverage(value: rounded, samplesUsed: window.length);
}
