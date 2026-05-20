import 'package:flutter_test/flutter_test.dart';
import 'package:nepse_buy/data/repositories/position_repository.dart';
import 'package:nepse_buy/domain/broker_sms/broker_sms_parser.dart';
import 'package:nepse_buy/domain/engine/fee_engine.dart';

void main() {
  final p = BrokerSmsParser();

  group('BrokerSmsParser — Naasa-style bracketed format', () {
    test('single-stock BUY with BAmt parses everything', () {
      const sms =
          'BNo.58 Purchased on 2026-02-05 2020082326 (GVL 500 kitta @ 494) - BAmt.247,877.15  Please provide payment by tomorrow.';
      final r = p.tryParse(sms);
      expect(r, isNotNull);
      expect(r!.side, TradeSide.buy);
      expect(r.trades.length, 1);
      expect(r.trades.first.symbol, 'GVL');
      expect(r.trades.first.shares, 500);
      expect(r.trades.first.grossPricePerShare, 494);
      expect(r.billAmount, 247877.15);
      expect(r.executedAt, DateTime(2026, 2, 5));
    });

    test('BAmt cross-check matches our fee engine to the rupee', () {
      // 500 × 494 = 247,000 ; broker 0.33% slab = 815.10 ; SEBON = 37.05 ;
      // DP = 25 ; total fees = 877.15 ; BAmt = 247,877.15 — must agree.
      final fees = computeBuyFees(500, 494, defaultFeeSchedule);
      expect(247000 + fees.totalFees, closeTo(247877.15, 0.01));
    });

    test('multi-stock SELL fans out six trades', () {
      const sms =
          'BNo.58 Sold on 2026-03-23 2020082326 (ILI 12 kitta @ 478,'
          'NBL 58 kitta @ 280,'
          'SJCL 2500 kitta @ 341,'
          'SNLI 1067 kitta @ 500,'
          'SRLI 11 kitta @ 430,'
          'TAMOR 10 kitta @ 446)'
          'Pls do EDIS by tomorrow, EDIS Process Video: a.merosms.com/EDIS '
          '& for Payment pls request from NaasaX after 26-3-2026';
      final r = p.tryParse(sms);
      expect(r, isNotNull);
      expect(r!.side, TradeSide.sell);
      expect(r.executedAt, DateTime(2026, 3, 23));
      expect(r.billAmount, isNull);
      expect(r.trades.length, 6);
      final byKey = {for (final t in r.trades) t.symbol: t};
      expect(byKey['ILI']!.shares, 12);
      expect(byKey['ILI']!.grossPricePerShare, 478);
      expect(byKey['NBL']!.shares, 58);
      expect(byKey['NBL']!.grossPricePerShare, 280);
      expect(byKey['SJCL']!.shares, 2500);
      expect(byKey['SJCL']!.grossPricePerShare, 341);
      expect(byKey['SNLI']!.shares, 1067);
      expect(byKey['SNLI']!.grossPricePerShare, 500);
      expect(byKey['SRLI']!.shares, 11);
      expect(byKey['TAMOR']!.shares, 10);
    });
  });

  group('BrokerSmsParser — looser legacy patterns', () {
    test('"sold 50 shares of CBBL" still parses via fallback', () {
      final r = p.tryParse(
          'You have sold 50 shares of CBBL at Rs 420 per share on 19/05/2026.');
      expect(r, isNotNull);
      expect(r!.side, TradeSide.sell);
      expect(r.trades.length, 1);
      expect(r.trades.first.symbol, 'CBBL');
      expect(r.trades.first.shares, 50);
      expect(r.trades.first.grossPricePerShare, 420);
    });
  });

  group('BrokerSmsParser — rejections', () {
    test('OTP messages return null', () {
      expect(p.tryParse('Your OTP is 123456. Do not share.'), isNull);
    });

    test('promotional SMS returns null', () {
      expect(p.tryParse('Get 10% off on demat fees this month!'), isNull);
    });

    test('"buy" without quantities surfaces with empty trades', () {
      final r = p.tryParse('Reminder: settlement for your buy is pending.');
      expect(r, isNotNull);
      expect(r!.trades, isEmpty);
      expect(r.hasMinimumFields, isFalse);
    });
  });

  group('BrokerSmsParser — confidence', () {
    test('full BUY with BAmt scores high', () {
      final r = p.tryParse(
          'BNo.58 Purchased on 2026-02-05 (GVL 500 kitta @ 494) - BAmt.247,877.15');
      expect(r!.confidence, greaterThanOrEqualTo(90));
    });

    test('multi-stock SELL without BAmt still scores well', () {
      final r = p.tryParse(
          'Sold on 2026-03-23 (ILI 12 kitta @ 478, NBL 58 kitta @ 280)');
      expect(r!.confidence, greaterThanOrEqualTo(80));
    });
  });
}
