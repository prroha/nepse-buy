import 'package:flutter_test/flutter_test.dart';
import 'package:nepse_buy/domain/engine/fifo.dart';

void main() {
  group('fifoMatch', () {
    test('consumes oldest lots first and computes per-match profit', () {
      final lots = [
        BuyLot(
          tradeId: 'l1',
          executedAt: DateTime.utc(2024, 1, 1),
          netPricePerShare: 100,
          remainingShares: 10,
        ),
        BuyLot(
          tradeId: 'l2',
          executedAt: DateTime.utc(2024, 6, 1),
          netPricePerShare: 110,
          remainingShares: 10,
        ),
      ];
      final matches = fifoMatch(
        lots: lots,
        sellShares: 15,
        sellGrossPricePerShare: 120,
        sellExecutedAt: DateTime.utc(2025, 1, 5),
        longTermDaysThreshold: 365,
      );
      expect(matches.length, 2);
      expect(matches[0].buyTradeId, 'l1');
      expect(matches[0].matchedShares, 10);
      expect(matches[0].realizedProfit, 200); // 10 * (120-100)
      expect(matches[0].isLongTerm, isTrue); // 370 days
      expect(matches[1].buyTradeId, 'l2');
      expect(matches[1].matchedShares, 5);
      expect(matches[1].realizedProfit, 50); // 5 * (120-110)
      expect(matches[1].isLongTerm, isFalse); // 218 days
      expect(lots[0].remainingShares, 0);
      expect(lots[1].remainingShares, 5);
    });

    test('throws when inventory is short', () {
      final lots = [
        BuyLot(
          tradeId: 'l1',
          executedAt: DateTime.utc(2024, 1, 1),
          netPricePerShare: 100,
          remainingShares: 3,
        ),
      ];
      expect(
        () => fifoMatch(
          lots: lots,
          sellShares: 5,
          sellGrossPricePerShare: 120,
          sellExecutedAt: DateTime.utc(2024, 6, 1),
          longTermDaysThreshold: 365,
        ),
        throwsA(isA<InsufficientInventoryException>()),
      );
    });
  });
}
