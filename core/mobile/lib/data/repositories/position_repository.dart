import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../domain/engine/fee_engine.dart';
import '../../domain/engine/fifo.dart';
import '../local/user_data_repository.dart';
import '../static/static_data_client.dart';
import 'base_repository.dart';

enum TradeSide { buy, sell }

extension TradeSideExt on TradeSide {
  String get wire => switch (this) {
        TradeSide.buy => 'BUY',
        TradeSide.sell => 'SELL',
      };
  String get label => switch (this) {
        TradeSide.buy => 'Buy',
        TradeSide.sell => 'Sell',
      };
}

class Position {
  final String id;
  final String stockId;
  final String symbol;
  final String name;
  final int totalShares;
  /// Weighted-average net cost per share, including broker + SEBON + DP fees.
  /// Renamed from `avgCost` in v0.7 — backend now sends this key.
  final String avgNetCost;
  /// Cumulative realized P/L from SELL trades, after fees + CGT. NPR.
  final String realizedPnl;
  final bool isOpen;
  final String? latestClose;
  /// Paper P/L as decimal (e.g., "0.32"). Null if no recent close available.
  final String? paperPlPct;

  const Position({
    required this.id,
    required this.stockId,
    required this.symbol,
    required this.name,
    required this.totalShares,
    required this.avgNetCost,
    required this.realizedPnl,
    required this.isOpen,
    required this.latestClose,
    required this.paperPlPct,
  });

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        id: json['id'] as String,
        stockId: json['stockId'] as String,
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        totalShares: (json['totalShares'] ?? 0) as int,
        // v0.7 backend uses `avgNetCost`. Tolerate older `avgCost` for cached responses.
        avgNetCost: (json['avgNetCost'] ?? json['avgCost'] ?? '0').toString(),
        realizedPnl: (json['realizedPnl'] ?? '0').toString(),
        isOpen: json['isOpen'] as bool,
        latestClose: json['latestClose'] as String?,
        paperPlPct: json['paperPlPct'] as String?,
      );
}

class TradeInput {
  final String symbol;
  final TradeSide side;
  final int shares;
  final String grossPricePerShare;
  final DateTime? executedAt;
  final String? note;
  const TradeInput({
    required this.symbol,
    required this.side,
    required this.shares,
    required this.grossPricePerShare,
    this.executedAt,
    this.note,
  });
}

/// Back-compat type alias — v0.6 outbox-payload code still references `PurchaseInput`.
/// New code should use [TradeInput] directly.
typedef PurchaseInput = TradeInputCompat;
class TradeInputCompat extends TradeInput {
  const TradeInputCompat({
    required super.symbol,
    required super.shares,
    required String pricePerShare,
    DateTime? purchasedAt,
    super.note,
  }) : super(side: TradeSide.buy, grossPricePerShare: pricePerShare, executedAt: purchasedAt);

  String get pricePerShare => grossPricePerShare;
  DateTime? get purchasedAt => executedAt;
}

final positionRepositoryProvider = Provider<PositionRepository>((ref) {
  return PositionRepositoryImpl(ref: ref);
});

abstract class PositionRepository {
  Future<Either<Failure, List<Position>>> list();
  /// Records a BUY or SELL trade — fees + (for sells) CGT computed locally.
  Future<Either<Failure, String>> logTrade(TradeInput input);
  /// Back-compat wrapper. Same as logTrade with side=BUY.
  Future<Either<Failure, String>> addPurchase(PurchaseInput input);
  Future<Either<Failure, void>> remove(String id);
}

/// Positions are derived: trades live in `user_trades`, FIFO + fee engine
/// re-compute open lots + realized P/L on each call. Position.id is the
/// symbol — there is no separate position row.
class PositionRepositoryImpl with BaseRepository implements PositionRepository {
  PositionRepositoryImpl({required this.ref});
  final Ref ref;
  static const _uuid = Uuid();

  Future<UserDataRepository> get _userData =>
      ref.read(userDataRepositoryProvider.future);
  Future<StaticDataClient> get _staticClient =>
      ref.read(staticDataClientProvider.future);

  @override
  Future<Either<Failure, List<Position>>> list() {
    return safeCall(() async {
      final userData = await _userData;
      final staticClient = await _staticClient;
      final trades = await userData.listTrades();
      if (trades.isEmpty) return const <Position>[];

      // Group trades by symbol — already sorted by executed_at ASC.
      final bySymbol = <String, List<Map<String, Object?>>>{};
      for (final t in trades) {
        bySymbol.putIfAbsent(t['symbol'] as String, () => []).add(t);
      }

      final stocks = await staticClient.getStocks();
      final metaBySymbol = {for (final s in stocks) s.symbol: s};

      final out = <Position>[];
      for (final entry in bySymbol.entries) {
        final symbol = entry.key;
        final symbolTrades = entry.value;
        final derived = _replay(symbolTrades);
        final prices = await staticClient.getPrices(symbol);
        final latestClose = prices.isEmpty ? null : prices.first.close;
        final meta = metaBySymbol[symbol];
        final paperPlPct = latestClose != null && derived.avgNetCost > 0
            ? (latestClose - derived.avgNetCost) / derived.avgNetCost
            : null;
        out.add(Position(
          id: symbol,
          stockId: symbol,
          symbol: symbol,
          name: meta?.name ?? symbol,
          totalShares: derived.totalShares,
          avgNetCost: derived.avgNetCost.toStringAsFixed(4),
          realizedPnl: derived.realizedPnl.toStringAsFixed(2),
          isOpen: derived.totalShares > 0,
          latestClose: latestClose?.toStringAsFixed(2),
          paperPlPct: paperPlPct?.toStringAsFixed(4),
        ));
      }
      out.sort((a, b) => a.symbol.compareTo(b.symbol));
      return out;
    });
  }

  /// Walks the trade timeline for one symbol, applying buy fees and FIFO-
  /// matching sells. Returns the post-replay aggregate state.
  _DerivedPosition _replay(List<Map<String, Object?>> trades) {
    final lots = <BuyLot>[];
    var realizedPnl = 0.0;
    for (final t in trades) {
      final side = (t['side'] as String).toUpperCase();
      final shares = (t['shares'] as int);
      final gross = (t['gross_price_per_share'] as num).toDouble();
      final executedAt =
          DateTime.fromMillisecondsSinceEpoch(t['executed_at'] as int);
      if (side == 'BUY') {
        final fees = computeBuyFees(shares, gross, defaultFeeSchedule);
        lots.add(BuyLot(
          tradeId: t['id'] as String,
          executedAt: executedAt,
          netPricePerShare: fees.netPricePerShare,
          remainingShares: shares,
        ));
      } else {
        try {
          final matches = fifoMatch(
            lots: lots,
            sellShares: shares,
            sellGrossPricePerShare: gross,
            sellExecutedAt: executedAt,
            longTermDaysThreshold: defaultFeeSchedule.longTermDaysThreshold,
          );
          final sellFees = computeSellFees(shares, gross, matches, defaultFeeSchedule);
          // Realized P/L = gross proceeds − fees − cgt − cost basis matched.
          final grossProceeds = shares * gross;
          final costBasis = matches.fold<double>(
              0, (acc, m) => acc + m.matchedShares * m.buyNetPricePerShare);
          realizedPnl +=
              grossProceeds - sellFees.totalFees - sellFees.cgt - costBasis;
        } on InsufficientInventoryException {
          // User entered a SELL exceeding inventory — surface zero and stop
          // replay so we don't double-count. UI should warn separately.
          break;
        }
      }
    }
    final totalShares =
        lots.fold<int>(0, (acc, l) => acc + l.remainingShares);
    final totalCost = lots.fold<double>(
        0, (acc, l) => acc + l.remainingShares * l.netPricePerShare);
    final avgNetCost = totalShares > 0 ? totalCost / totalShares : 0.0;
    return _DerivedPosition(
      totalShares: totalShares,
      avgNetCost: avgNetCost,
      realizedPnl: realizedPnl,
    );
  }

  @override
  Future<Either<Failure, String>> logTrade(TradeInput input) {
    return safeCall(() async {
      final userData = await _userData;
      await userData.upsertTrade({
        'id': _uuid.v4(),
        'symbol': input.symbol.toUpperCase(),
        'side': input.side.wire,
        'shares': input.shares,
        'gross_price_per_share': double.parse(input.grossPricePerShare),
        'executed_at':
            (input.executedAt ?? DateTime.now()).millisecondsSinceEpoch,
        'notes': input.note,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      return input.symbol.toUpperCase();
    });
  }

  @override
  Future<Either<Failure, String>> addPurchase(PurchaseInput input) {
    return logTrade(input);
  }

  /// Closing a position = wipe every trade for the symbol. Caller is
  /// expected to confirm before calling.
  @override
  Future<Either<Failure, void>> remove(String id) {
    return safeCall(() async {
      final userData = await _userData;
      final trades = await userData.listTrades(symbol: id);
      for (final t in trades) {
        await userData.deleteTrade(t['id'] as String);
      }
    });
  }
}

class _DerivedPosition {
  _DerivedPosition({
    required this.totalShares,
    required this.avgNetCost,
    required this.realizedPnl,
  });
  final int totalShares;
  final double avgNetCost;
  final double realizedPnl;
}
