import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../static/static_data_client.dart';
import '../static/static_data_models.dart';
import 'base_repository.dart';

/// One row in the stock list. Money fields are strings to preserve precision.
class Stock {
  final String id;
  final String symbol;
  final String name;
  final String? sector;
  final String status;
  final bool isCurated;
  final String? latestClose;
  final String? latestPriceDate;
  final String? latestPe;
  final String? latestPb;

  const Stock({
    required this.id,
    required this.symbol,
    required this.name,
    required this.sector,
    required this.status,
    required this.isCurated,
    required this.latestClose,
    required this.latestPriceDate,
    required this.latestPe,
    required this.latestPb,
  });

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
        id: json['id'] as String,
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        sector: json['sector'] as String?,
        status: json['status'] as String,
        isCurated: json['isCurated'] as bool,
        latestClose: json['latestClose'] as String?,
        latestPriceDate: json['latestPriceDate'] as String?,
        latestPe: json['latestPe'] as String?,
        latestPb: json['latestPb'] as String?,
      );
}

class StockPriceObservation {
  final String tradeDate;
  final String close;
  final String volume;
  final String source;
  const StockPriceObservation({
    required this.tradeDate,
    required this.close,
    required this.volume,
    required this.source,
  });
  factory StockPriceObservation.fromJson(Map<String, dynamic> json) => StockPriceObservation(
        tradeDate: json['tradeDate'] as String,
        close: json['close'] as String,
        volume: json['volume'].toString(),
        source: json['source'] as String,
      );
}

class StockDetail extends Stock {
  final String? latestObservedAt;
  final List<StockPriceObservation> recentPrices;

  const StockDetail({
    required super.id,
    required super.symbol,
    required super.name,
    required super.sector,
    required super.status,
    required super.isCurated,
    required super.latestClose,
    required super.latestPriceDate,
    required super.latestPe,
    required super.latestPb,
    required this.latestObservedAt,
    required this.recentPrices,
  });

  factory StockDetail.fromJson(Map<String, dynamic> json) => StockDetail(
        id: json['id'] as String,
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        sector: json['sector'] as String?,
        status: json['status'] as String,
        isCurated: json['isCurated'] as bool,
        latestClose: json['latestClose'] as String?,
        latestPriceDate: json['latestPriceDate'] as String?,
        latestPe: json['latestPe'] as String?,
        latestPb: json['latestPb'] as String?,
        latestObservedAt: json['latestObservedAt'] as String?,
        recentPrices: ((json['recentPrices'] ?? []) as List)
            .map((e) => StockPriceObservation.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class StockSearchPage {
  final List<Stock> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  const StockSearchPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepositoryImpl(ref: ref);
});

abstract class StockRepository {
  Future<Either<Failure, StockSearchPage>> list({
    String? query,
    bool curatedOnly = false,
    int page = 1,
    int limit = 20,
  });
  Future<Either<Failure, StockDetail>> getBySymbol(String symbol);
}

/// Reads from the static JSON bundle. Pagination is implemented client-side
/// over the in-memory stock list since the universe is small (≈10–500
/// active stocks).
class StockRepositoryImpl with BaseRepository implements StockRepository {
  StockRepositoryImpl({required this.ref});
  final Ref ref;

  Future<StaticDataClient> get _client =>
      ref.read(staticDataClientProvider.future);

  Stock _toStock(StaticStock s, {StaticPrice? p, StaticFundamentals? f}) {
    return Stock(
      id: s.symbol, // symbol doubles as id in the static world
      symbol: s.symbol,
      name: s.name,
      sector: s.sector,
      status: s.status,
      isCurated: s.isCurated,
      latestClose: p?.close.toStringAsFixed(2),
      latestPriceDate: p?.tradeDate.toIso8601String(),
      latestPe: f?.pe?.toStringAsFixed(2),
      latestPb: f?.pb?.toStringAsFixed(2),
    );
  }

  @override
  Future<Either<Failure, StockSearchPage>> list({
    String? query,
    bool curatedOnly = false,
    int page = 1,
    int limit = 20,
  }) {
    return safeCall(() async {
      final client = await _client;
      var stocks = await client.getStocks();
      if (curatedOnly) stocks = stocks.where((s) => s.isCurated).toList();
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        stocks = stocks
            .where((s) =>
                s.symbol.toLowerCase().contains(q) ||
                s.name.toLowerCase().contains(q))
            .toList();
      }
      final total = stocks.length;
      final start = ((page - 1) * limit).clamp(0, total);
      final end = (start + limit).clamp(0, total);
      final pageItems = stocks.sublist(start, end);

      // List view returns metadata only — price/fundamentals enrichment is
      // deferred to `getBySymbol()` for the detail screen. Eagerly enriching
      // here triggered N+1 network calls (2 per symbol) on every keystroke.
      final items = pageItems.map(_toStock).toList(growable: false);
      final totalPages = (total / limit).ceil();
      return StockSearchPage(
        items: items,
        page: page,
        limit: limit,
        total: total,
        totalPages: totalPages == 0 ? 1 : totalPages,
      );
    });
  }

  @override
  Future<Either<Failure, StockDetail>> getBySymbol(String symbol) {
    return safeCall(() async {
      final client = await _client;
      final stocks = await client.getStocks();
      final meta = stocks.firstWhere(
        (s) => s.symbol.toUpperCase() == symbol.toUpperCase(),
        orElse: () => StaticStock(
          symbol: symbol.toUpperCase(),
          name: symbol.toUpperCase(),
          sector: null,
          status: 'ACTIVE',
          tier: 'STANDARD',
          isCurated: false,
        ),
      );
      final prices = await client.getPrices(symbol);
      final fund = await client.getFundamentals(symbol);
      return StockDetail(
        id: meta.symbol,
        symbol: meta.symbol,
        name: meta.name,
        sector: meta.sector,
        status: meta.status,
        isCurated: meta.isCurated,
        latestClose: prices.isEmpty ? null : prices.first.close.toStringAsFixed(2),
        latestPriceDate:
            prices.isEmpty ? null : prices.first.tradeDate.toIso8601String(),
        latestPe: fund?.pe?.toStringAsFixed(2),
        latestPb: fund?.pb?.toStringAsFixed(2),
        latestObservedAt: fund?.observedAt.toIso8601String(),
        recentPrices: prices
            .map((p) => StockPriceObservation(
                  tradeDate: p.tradeDate.toIso8601String().substring(0, 10),
                  close: p.close.toStringAsFixed(2),
                  volume: p.volume.toStringAsFixed(0),
                  source: 'STATIC',
                ))
            .toList(growable: false),
      );
    });
  }
}
