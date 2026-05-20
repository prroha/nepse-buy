import 'package:flutter_test/flutter_test.dart';
import 'package:nepse_buy/domain/engine/decision.dart';
import 'package:nepse_buy/domain/engine/types.dart';

DecisionInput _base({
  double close = 500,
  double? ma20 = 510,
  Season season = Season.normal,
  double? pe,
  double? pb,
  double? peMed,
  double? pbMed,
  PositionContext? position,
  DebtContext? debt,
}) =>
    DecisionInput(
      close: close,
      ma20: ma20,
      ma20Window: 20,
      season: season,
      pe: pe,
      pb: pb,
      peMedian5y: peMed,
      pbMedian5y: pbMed,
      position: position,
      debt: debt,
    );

void main() {
  group('decide', () {
    test('SKIP when close is invalid', () {
      final d = decide(_base(close: 0), defaultEngineConfig);
      expect(d.action, SignalAction.skip);
    });

    test('WAIT when MA is null (insufficient history)', () {
      final d = decide(_base(ma20: null), defaultEngineConfig);
      expect(d.action, SignalAction.wait);
      expect(d.rationale, contains('need ≥20'));
    });

    test('STRONG season → HOLD_FUNDS regardless of MA', () {
      final d = decide(_base(season: Season.strong), defaultEngineConfig);
      expect(d.action, SignalAction.holdFunds);
      expect(d.rationale, contains('Strong-season'));
    });

    test('STRONG with debt context surfaces interest savings', () {
      final d = decide(
        _base(
          season: Season.strong,
          debt: DebtContext(
            totalBalance: 500000,
            weightedAvgRate: 11,
            primaryName: 'Bank OD',
            monthlySurplus: 100000,
          ),
        ),
        defaultEngineConfig,
      );
      expect(d.action, SignalAction.holdFunds);
      // 100000 * 11 / 100 / 365 * 30 ≈ 904.1
      expect(d.rationale, contains('Bank OD'));
      expect(d.rationale, contains('1,00,000')); // Indian-locale surplus
      expect(d.rationale, contains('5,00,000')); // Indian-locale balance
    });

    test('WEAK + close ≤ MA20 → BUY (dip qualified)', () {
      final d = decide(
        _base(season: Season.weak, close: 100, ma20: 105),
        defaultEngineConfig,
      );
      expect(d.action, SignalAction.buy);
      expect(d.rationale, contains('dip qualified'));
      expect(d.suggestedLimit, 99); // 100 * 0.99
    });

    test('WEAK + close > MA20 + valuation rich → WAIT', () {
      final d = decide(
        _base(
          season: Season.weak,
          close: 200,
          ma20: 180,
          pe: 30,
          peMed: 20,
          pb: 4,
          pbMed: 3,
        ),
        defaultEngineConfig,
      );
      expect(d.action, SignalAction.wait);
    });

    test('WEAK + above MA20 but valuation attractive → BUY via gate', () {
      final d = decide(
        _base(
          season: Season.weak,
          close: 200,
          ma20: 180,
          pe: 15,
          peMed: 20,
          pb: 2,
          pbMed: 3,
        ),
        defaultEngineConfig,
      );
      expect(d.action, SignalAction.buy);
      expect(d.rationale, contains('valuation gate qualifies'));
    });

    test('NORMAL → BUY at 1% off close', () {
      final d = decide(_base(close: 300, ma20: 310), defaultEngineConfig);
      expect(d.action, SignalAction.buy);
      expect(d.suggestedLimit, 297); // 300 * 0.99
    });

    test('HARVEST fires when paper P/L ≥ threshold', () {
      final d = decide(
        _base(
          close: 130,
          position: PositionContext(totalShares: 100, avgCost: 100),
        ),
        defaultEngineConfig,
      );
      expect(d.action, SignalAction.harvest);
      expect(d.rationale, contains('25 shares')); // 25% of 100
    });

    test('HARVEST takes precedence over STRONG-season HOLD_FUNDS', () {
      final d = decide(
        _base(
          season: Season.strong,
          close: 200,
          position: PositionContext(totalShares: 50, avgCost: 100),
        ),
        defaultEngineConfig,
      );
      expect(d.action, SignalAction.harvest);
      expect(d.rationale, contains('Strong-season month'));
    });
  });
}
