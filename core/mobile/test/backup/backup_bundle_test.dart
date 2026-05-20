import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nepse_buy/domain/backup/backup_bundle.dart';

void main() {
  group('BackupBundle round-trip', () {
    test('decode(encode()) preserves all sections', () {
      final original = BackupBundle(
        version: BackupBundle.currentVersion,
        exportedAt: DateTime.utc(2026, 5, 20, 12, 30),
        watchlist: [
          {'symbol': 'NABIL', 'added_at': 1, 'alerts_enabled': 1},
        ],
        trades: [
          {
            'id': 't1',
            'symbol': 'CBBL',
            'side': 'BUY',
            'shares': 50,
            'gross_price_per_share': 420.0,
            'executed_at': 1716000000000,
            'notes': 'monthly DCA',
            'created_at': 1716000000000,
          },
        ],
        debtAccounts: [
          {
            'id': 'd1',
            'name': 'OD',
            'outstanding_balance': 500000.0,
            'annual_rate_pct': 11.0,
            'monthly_surplus': 100000.0,
            'is_active': 1,
            'created_at': 1716000000000,
          },
        ],
        feeSchedule: {
          'brokerageSlabs': [
            {'upTo': 50000, 'ratePct': 0.36},
          ],
          'sebonRatePct': 0.015,
        },
        settings: {'theme': 'dark', 'dcaAmount': '25000'},
      );

      final encoded = original.encode();
      final decoded = BackupBundle.decode(encoded);
      expect(decoded.version, original.version);
      expect(decoded.exportedAt, original.exportedAt);
      expect(decoded.watchlist.length, 1);
      expect(decoded.watchlist.first['symbol'], 'NABIL');
      expect(decoded.trades.length, 1);
      expect(decoded.trades.first['symbol'], 'CBBL');
      expect(decoded.debtAccounts.length, 1);
      expect(decoded.feeSchedule, isNotNull);
      expect(decoded.feeSchedule!['sebonRatePct'], 0.015);
      expect(decoded.settings, {'theme': 'dark', 'dcaAmount': '25000'});
    });

    test('rejects non-nepse-buy JSON', () {
      expect(
        () => BackupBundle.decode('{"kind":"something-else","version":1}'),
        throwsA(isA<BackupParseException>()),
      );
    });

    test('rejects bundles newer than supported version', () {
      final futureBundle = jsonEncode({
        'kind': 'nepse-buy-user-data',
        'version': BackupBundle.currentVersion + 5,
      });
      expect(
        () => BackupBundle.decode(futureBundle),
        throwsA(isA<BackupParseException>()),
      );
    });

    test('rejects malformed JSON', () {
      expect(
        () => BackupBundle.decode('not json at all'),
        throwsA(isA<BackupParseException>()),
      );
    });

    test('missing sections decode to empty defaults', () {
      final minimal = jsonEncode({
        'kind': 'nepse-buy-user-data',
        'version': 1,
      });
      final decoded = BackupBundle.decode(minimal);
      expect(decoded.watchlist, isEmpty);
      expect(decoded.trades, isEmpty);
      expect(decoded.debtAccounts, isEmpty);
      expect(decoded.feeSchedule, isNull);
      expect(decoded.settings, isEmpty);
    });
  });
}
