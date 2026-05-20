import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

enum PendingMessageStatus { pending, applied, dismissed }

extension _PendingMessageStatusWire on PendingMessageStatus {
  String get wire => switch (this) {
        PendingMessageStatus.pending => 'PENDING',
        PendingMessageStatus.applied => 'APPLIED',
        PendingMessageStatus.dismissed => 'DISMISSED',
      };
}

class PendingBrokerMessage {
  PendingBrokerMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.receivedAt,
    required this.tradeIndex,
    required this.parsedSymbol,
    required this.parsedSide,
    required this.parsedShares,
    required this.parsedGrossPrice,
    required this.parsedExecutedAt,
    required this.billAmount,
    required this.status,
    required this.appliedTradeId,
    required this.notes,
  });

  final String id;
  final String sender;
  final String body;
  final DateTime receivedAt;

  /// 0-based index of this trade within its SMS — a single SELL with six
  /// tickers produces rows 0…5 sharing the same body.
  final int tradeIndex;

  final String? parsedSymbol;
  final String? parsedSide;
  final int? parsedShares;
  final double? parsedGrossPrice;
  final DateTime? parsedExecutedAt;

  /// `BAmt` from BUY confirmations — gross + all fees as the broker
  /// computed them. Lets the approval screen cross-check our fee-engine
  /// output.
  final double? billAmount;

  final PendingMessageStatus status;
  final String? appliedTradeId;
  final String? notes;

  factory PendingBrokerMessage.fromRow(Map<String, Object?> r) =>
      PendingBrokerMessage(
        id: r['id'] as String,
        sender: r['sender'] as String,
        body: r['body'] as String,
        receivedAt:
            DateTime.fromMillisecondsSinceEpoch(r['received_at'] as int),
        tradeIndex: (r['trade_index'] as int?) ?? 0,
        parsedSymbol: r['parsed_symbol'] as String?,
        parsedSide: r['parsed_side'] as String?,
        parsedShares: r['parsed_shares'] as int?,
        parsedGrossPrice: (r['parsed_gross_price'] as num?)?.toDouble(),
        parsedExecutedAt: r['parsed_executed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                r['parsed_executed_at'] as int),
        billAmount: (r['bill_amount'] as num?)?.toDouble(),
        status: switch (r['status'] as String) {
          'APPLIED' => PendingMessageStatus.applied,
          'DISMISSED' => PendingMessageStatus.dismissed,
          _ => PendingMessageStatus.pending,
        },
        appliedTradeId: r['applied_trade_id'] as String?,
        notes: r['notes'] as String?,
      );
}

/// Stores broker SMS messages so the user can approve/dismiss in a queue,
/// not on the lock screen. De-duplicates by (sender, body, receivedAt).
class BrokerInboxRepository {
  BrokerInboxRepository(this._db);
  final Database _db;
  static const _uuid = Uuid();

  Future<String?> upsertIncoming({
    required String sender,
    required String body,
    required DateTime receivedAt,
    int tradeIndex = 0,
    String? parsedSymbol,
    String? parsedSide,
    int? parsedShares,
    double? parsedGrossPrice,
    DateTime? parsedExecutedAt,
    double? billAmount,
    String? notes,
  }) async {
    // Dedupe per (sender, body, received_at, trade_index). Multi-trade
    // SMSes fan out — same body, different trade_index.
    final existing = await _db.query(
      'pending_broker_messages',
      where:
          'sender = ? AND body = ? AND received_at = ? AND trade_index = ?',
      whereArgs: [
        sender,
        body,
        receivedAt.millisecondsSinceEpoch,
        tradeIndex,
      ],
      limit: 1,
    );
    if (existing.isNotEmpty) return null;
    final id = _uuid.v4();
    await _db.insert('pending_broker_messages', {
      'id': id,
      'sender': sender,
      'body': body,
      'received_at': receivedAt.millisecondsSinceEpoch,
      'trade_index': tradeIndex,
      'parsed_symbol': parsedSymbol,
      'parsed_side': parsedSide,
      'parsed_shares': parsedShares,
      'parsed_gross_price': parsedGrossPrice,
      'parsed_executed_at': parsedExecutedAt?.millisecondsSinceEpoch,
      'bill_amount': billAmount,
      'status': 'PENDING',
      'applied_trade_id': null,
      'notes': notes,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return id;
  }

  Future<List<PendingBrokerMessage>> list(
      {PendingMessageStatus? status, int limit = 100}) async {
    final rows = await _db.query(
      'pending_broker_messages',
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : [status.wire],
      orderBy: 'received_at DESC',
      limit: limit,
    );
    return rows.map(PendingBrokerMessage.fromRow).toList(growable: false);
  }

  Future<int> pendingCount() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM pending_broker_messages WHERE status = ?',
      ['PENDING'],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> markApplied(String id, {required String tradeId}) async {
    await _db.update(
      'pending_broker_messages',
      {'status': 'APPLIED', 'applied_trade_id': tradeId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> dismiss(String id, {String? reason}) async {
    await _db.update(
      'pending_broker_messages',
      {'status': 'DISMISSED', 'notes': reason},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

final brokerInboxRepositoryProvider =
    FutureProvider<BrokerInboxRepository>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return BrokerInboxRepository(db.raw);
});
