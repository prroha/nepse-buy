import 'package:flutter_test/flutter_test.dart';
import 'package:nepse_buy/domain/engine/fee_engine.dart';
import 'package:nepse_buy/domain/engine/fifo.dart';

void main() {
  group('computeBrokerage (NEPSE 2024 defaults)', () {
    test('picks the first slab matching the transaction value', () {
      // 40,000 → first slab 0.36%
      expect(computeBrokerage(40000, defaultFeeSchedule), 144);
      // 250,000 → second slab 0.33%
      expect(computeBrokerage(250000, defaultFeeSchedule), 825);
    });

    test('open-ended last slab covers anything above the highest upTo', () {
      // 50,000,000 → last slab 0.24%
      expect(computeBrokerage(50000000, defaultFeeSchedule), 120000);
    });
  });

  group('computeBuyFees', () {
    test('inflates per-share net price by fees', () {
      // 100 shares @ Rs 500 = Rs 50,000 gross
      final f = computeBuyFees(100, 500, defaultFeeSchedule);
      // brokerage 0.36% of 50k = 180
      expect(f.brokerCommission, 180);
      // SEBON 0.015% of 50k = 7.5
      expect(f.sebonFee, 7.5);
      expect(f.dpFee, 25);
      expect(f.totalFees, 212.5);
      // Net per share = (50000 + 212.5) / 100 = 502.125
      expect(f.netPricePerShare, 502.125);
    });
  });

  group('computeSellFees', () {
    test('applies LT vs ST CGT correctly per match; ignores losses', () {
      final matches = [
        FifoMatch(
          buyTradeId: 'long',
          buyExecutedAt: DateTime.utc(2024, 1, 1),
          buyNetPricePerShare: 100,
          matchedShares: 50,
          realizedProfit: 1000,
          holdingDays: 400,
          isLongTerm: true,
        ),
        FifoMatch(
          buyTradeId: 'short',
          buyExecutedAt: DateTime.utc(2024, 12, 1),
          buyNetPricePerShare: 100,
          matchedShares: 50,
          realizedProfit: 500,
          holdingDays: 30,
          isLongTerm: false,
        ),
        FifoMatch(
          buyTradeId: 'loss',
          buyExecutedAt: DateTime.utc(2024, 12, 1),
          buyNetPricePerShare: 100,
          matchedShares: 10,
          realizedProfit: -50,
          holdingDays: 30,
          isLongTerm: false,
        ),
      ];
      final f = computeSellFees(110, 120, matches, defaultFeeSchedule);
      // LT match: 1000 * 5% = 50
      // ST match: 500 * 7.5% = 37.5
      // loss: ignored
      expect(f.cgtBreakdown.length, 2);
      expect(f.cgt, 87.5);
    });
  });
}
