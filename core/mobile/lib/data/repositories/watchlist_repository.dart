import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../local/user_data_repository.dart';
import '../static/static_data_client.dart';
import 'base_repository.dart';

class WatchlistStock {
  final String id;
  final String symbol;
  final String name;
  final String? sector;
  final String? latestClose;
  final String? latestPriceDate;
  final String? latestPe;
  final String? latestPb;
  const WatchlistStock({
    required this.id,
    required this.symbol,
    required this.name,
    required this.sector,
    required this.latestClose,
    required this.latestPriceDate,
    required this.latestPe,
    required this.latestPb,
  });
  factory WatchlistStock.fromJson(Map<String, dynamic> json) => WatchlistStock(
        id: json['id'] as String,
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        sector: json['sector'] as String?,
        latestClose: json['latestClose'] as String?,
        latestPriceDate: json['latestPriceDate'] as String?,
        latestPe: json['latestPe'] as String?,
        latestPb: json['latestPb'] as String?,
      );
}

class WatchlistLatestSignal {
  final String action;
  final String season;
  final String signalDate;
  final String? suggestedLimit;
  const WatchlistLatestSignal({
    required this.action,
    required this.season,
    required this.signalDate,
    required this.suggestedLimit,
  });
  factory WatchlistLatestSignal.fromJson(Map<String, dynamic> json) => WatchlistLatestSignal(
        action: json['action'] as String,
        season: json['season'] as String,
        signalDate: json['signalDate'] as String,
        suggestedLimit: json['suggestedLimit'] as String?,
      );
}

class WatchlistItem {
  final String id;
  final int rank;
  final bool alertsEnabled;
  final WatchlistStock stock;
  final WatchlistLatestSignal? latestSignal;
  const WatchlistItem({
    required this.id,
    required this.rank,
    required this.alertsEnabled,
    required this.stock,
    required this.latestSignal,
  });
  factory WatchlistItem.fromJson(Map<String, dynamic> json) => WatchlistItem(
        id: json['id'] as String,
        rank: (json['rank'] ?? 0) as int,
        alertsEnabled: (json['alertsEnabled'] ?? true) as bool,
        stock: WatchlistStock.fromJson(json['stock'] as Map<String, dynamic>),
        latestSignal: json['latestSignal'] != null
            ? WatchlistLatestSignal.fromJson(json['latestSignal'] as Map<String, dynamic>)
            : null,
      );
}

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return WatchlistRepositoryImpl(ref: ref);
});

abstract class WatchlistRepository {
  Future<Either<Failure, List<WatchlistItem>>> list();
  Future<Either<Failure, String>> add(String symbol);
  Future<Either<Failure, void>> remove(String id);
}

/// Local-only watchlist after the static-data pivot:
///   • Membership lives in sqflite (`user_watchlist`) — symbol is the id.
///   • Stock metadata + latest price + current PE/PB come from the static
///     JSON bundle via [StaticDataClient].
///   • `latestSignal` is left null at the list level — the dedicated signals
///     screen runs the engine per-stock.
class WatchlistRepositoryImpl with BaseRepository implements WatchlistRepository {
  WatchlistRepositoryImpl({required this.ref});
  final Ref ref;

  Future<UserDataRepository> get _userData =>
      ref.read(userDataRepositoryProvider.future);
  Future<StaticDataClient> get _staticClient =>
      ref.read(staticDataClientProvider.future);

  @override
  Future<Either<Failure, List<WatchlistItem>>> list() {
    return safeCall(() async {
      final userData = await _userData;
      final staticClient = await _staticClient;
      final rows = await userData.listWatchlist();
      if (rows.isEmpty) return const <WatchlistItem>[];
      final stocks = await staticClient.getStocks();
      final byKey = {for (final s in stocks) s.symbol.toUpperCase(): s};
      final items = <WatchlistItem>[];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final symbol = (row['symbol'] as String).toUpperCase();
        final meta = byKey[symbol];
        final prices = await staticClient.getPrices(symbol);
        final latestPrice = prices.isEmpty ? null : prices.first;
        final fund = await staticClient.getFundamentals(symbol);
        items.add(WatchlistItem(
          id: symbol,
          rank: i,
          alertsEnabled: (row['alerts_enabled'] as int? ?? 1) == 1,
          stock: WatchlistStock(
            id: symbol,
            symbol: symbol,
            name: meta?.name ?? symbol,
            sector: meta?.sector,
            latestClose: latestPrice?.close.toStringAsFixed(2),
            latestPriceDate: latestPrice?.tradeDate.toIso8601String(),
            latestPe: fund?.pe?.toStringAsFixed(2),
            latestPb: fund?.pb?.toStringAsFixed(2),
          ),
          latestSignal: null,
        ));
      }
      return items;
    });
  }

  @override
  Future<Either<Failure, String>> add(String symbol) {
    return safeCall(() async {
      final userData = await _userData;
      await userData.addWatchlist(symbol);
      return symbol.toUpperCase();
    });
  }

  @override
  Future<Either<Failure, void>> remove(String id) {
    return safeCall(() async {
      final userData = await _userData;
      await userData.removeWatchlist(id);
    });
  }
}
