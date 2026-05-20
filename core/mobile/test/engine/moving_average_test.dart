import 'package:flutter_test/flutter_test.dart';
import 'package:nepse_buy/domain/engine/moving_average.dart';

void main() {
  group('movingAverage', () {
    test('returns null when fewer than minSamples', () {
      final r = movingAverage([100, 101, 102], windowSize: 20, minSamples: 20);
      expect(r.value, isNull);
      expect(r.samplesUsed, 3);
    });

    test('computes mean of the most recent windowSize entries', () {
      final closes = List<double>.generate(20, (i) => (100 + i).toDouble());
      final r = movingAverage(closes, windowSize: 20, minSamples: 20);
      // mean(100..119) = 109.5
      expect(r.value, 109.5);
      expect(r.samplesUsed, 20);
    });

    test('truncates to windowSize when more samples present', () {
      final closes = [
        for (var i = 0; i < 30; i++) (200 + i).toDouble(),
      ];
      final r = movingAverage(closes, windowSize: 20, minSamples: 20);
      // First 20 (most-recent-first) = 200..219 → mean 209.5
      expect(r.value, 209.5);
    });

    test('rounds to 4 decimals', () {
      final r = movingAverage([1.11111, 2.22222, 3.33333],
          windowSize: 3, minSamples: 3);
      // mean = 2.22222 — already 4 decimals.
      expect(r.value, 2.2222);
    });
  });
}
