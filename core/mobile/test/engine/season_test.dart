import 'package:flutter_test/flutter_test.dart';
import 'package:nepse_buy/domain/engine/season.dart';
import 'package:nepse_buy/domain/engine/types.dart';

void main() {
  group('classifySeason (NPT, +5:45)', () {
    test('March → WEAK', () {
      // 2026-03-15 12:00 UTC → NPT same day
      expect(
        classifySeason(DateTime.utc(2026, 3, 15, 12)),
        Season.weak,
      );
    });
    test('June → WEAK', () {
      expect(classifySeason(DateTime.utc(2026, 6, 1)), Season.weak);
    });
    test('November → WEAK', () {
      expect(classifySeason(DateTime.utc(2026, 11, 30)), Season.weak);
    });
    test('January / July / August → STRONG', () {
      expect(classifySeason(DateTime.utc(2026, 1, 15)), Season.strong);
      expect(classifySeason(DateTime.utc(2026, 7, 15)), Season.strong);
      expect(classifySeason(DateTime.utc(2026, 8, 15)), Season.strong);
    });
    test('April → NORMAL', () {
      expect(classifySeason(DateTime.utc(2026, 4, 10)), Season.normal);
    });
    test('Late UTC night still classifies by NPT day', () {
      // 2026-11-30 23:00 UTC → 2026-12-01 04:45 NPT → December = NORMAL
      expect(
        classifySeason(DateTime.utc(2026, 11, 30, 23)),
        Season.normal,
      );
    });
  });
}
