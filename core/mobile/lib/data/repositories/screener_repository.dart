import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../static/static_data_client.dart';
import '../static/static_data_models.dart';
import 'base_repository.dart';

enum ScreenerType { dividend, growth, safety }

extension ScreenerTypeExt on ScreenerType {
  String get wire => switch (this) {
        ScreenerType.dividend => 'dividend',
        ScreenerType.growth => 'growth',
        ScreenerType.safety => 'safety',
      };
  String get label => switch (this) {
        ScreenerType.dividend => 'Top dividend',
        ScreenerType.growth => 'Top growth',
        ScreenerType.safety => 'Top safety',
      };
}

class ScreenerMetrics {
  final String? dividendYieldPct;
  final String? roeTtm;
  final String? epsTtmYoyPct;
  final String? marketCap;
  final String? pe;
  final String? pb;
  const ScreenerMetrics({
    this.dividendYieldPct,
    this.roeTtm,
    this.epsTtmYoyPct,
    this.marketCap,
    this.pe,
    this.pb,
  });
  factory ScreenerMetrics.fromJson(Map<String, dynamic> json) => ScreenerMetrics(
        dividendYieldPct: json['dividendYieldPct'] as String?,
        roeTtm: json['roeTtm'] as String?,
        epsTtmYoyPct: json['epsTtmYoyPct'] as String?,
        marketCap: json['marketCap'] as String?,
        pe: json['pe'] as String?,
        pb: json['pb'] as String?,
      );
}

class ScreenerRow {
  final String symbol;
  final String name;
  final String? sector;
  final String? latestClose;
  final String score;
  final ScreenerMetrics metrics;
  const ScreenerRow({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.latestClose,
    required this.score,
    required this.metrics,
  });
  factory ScreenerRow.fromJson(Map<String, dynamic> json) => ScreenerRow(
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        sector: json['sector'] as String?,
        latestClose: json['latestClose'] as String?,
        score: json['score'].toString(),
        metrics: ScreenerMetrics.fromJson(json['metrics'] as Map<String, dynamic>? ?? const {}),
      );
}

final screenerRepositoryProvider = Provider<ScreenerRepository>((ref) {
  return ScreenerRepositoryImpl(ref: ref);
});

abstract class ScreenerRepository {
  Future<Either<Failure, List<ScreenerRow>>> rank(ScreenerType type, {int limit = 10});
}

/// Mirrors the TS `screener.service.ts` ranking math on-device:
///   • dividend — 3-year total of cash + bonus declarations, falling back
///     to current 1-year yield × 3 when history is missing.
///   • growth   — 0.6 × epsTtmYoyPct + 0.4 × roeTtm.
///   • safety   — log10(marketCap) × 2 + roe × 0.3 + 10/PE.
class ScreenerRepositoryImpl with BaseRepository implements ScreenerRepository {
  ScreenerRepositoryImpl({required this.ref});
  final Ref ref;

  Future<StaticDataClient> get _client =>
      ref.read(staticDataClientProvider.future);

  @override
  Future<Either<Failure, List<ScreenerRow>>> rank(ScreenerType type,
      {int limit = 10}) {
    return safeCall(() async {
      final client = await _client;
      final stocks = await client.getStocks();
      // Gather per-symbol facts. Skip stocks without fundamentals at all.
      final candidates = <_Candidate>[];
      for (final s in stocks.where((s) => s.status == 'ACTIVE')) {
        final f = await client.getFundamentals(s.symbol);
        if (f == null) continue;
        final divs = await client.getDividends(s.symbol);
        final prices = await client.getPrices(s.symbol);
        candidates.add(_Candidate(
          meta: s,
          fundamentals: f,
          dividends: divs,
          latestPrice: prices.isEmpty ? null : prices.first,
        ));
      }
      switch (type) {
        case ScreenerType.dividend:
          return _rankDividend(candidates, limit);
        case ScreenerType.growth:
          return _rankGrowth(candidates, limit);
        case ScreenerType.safety:
          return _rankSafety(candidates, limit);
      }
    });
  }

  List<ScreenerRow> _rankDividend(List<_Candidate> all, int limit) {
    final cutoff = DateTime.now().subtract(const Duration(days: 3 * 365));
    final scored = all.map((c) {
      final total3y = c.dividends
          .where((d) =>
              (d.type == 'CASH_DIVIDEND' || d.type == 'BONUS_SHARE') &&
              (d.announcedAt.isAfter(cutoff)))
          .fold<double>(0, (acc, d) => acc + (d.pct ?? 0));
      final fallback = (c.fundamentals.dividendYieldPct ?? 0) * 3;
      final score = total3y > 0 ? total3y : fallback;
      return MapEntry(c, score);
    }).where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => _toRow(e.key, e.value)).toList();
  }

  List<ScreenerRow> _rankGrowth(List<_Candidate> all, int limit) {
    final scored = all
        .where((c) =>
            c.fundamentals.epsTtmYoyPct != null &&
            c.fundamentals.roeTtm != null)
        .map((c) {
          final yoy = c.fundamentals.epsTtmYoyPct!;
          final roe = c.fundamentals.roeTtm!;
          return MapEntry(c, 0.6 * yoy + 0.4 * roe);
        })
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => _toRow(e.key, e.value)).toList();
  }

  List<ScreenerRow> _rankSafety(List<_Candidate> all, int limit) {
    final scored = all
        .where((c) => c.fundamentals.marketCap != null)
        .map((c) {
          final mcap = c.fundamentals.marketCap!;
          final roe = c.fundamentals.roeTtm ?? 0;
          final pe = c.fundamentals.pe ?? 30;
          final logCap = mcap > 0 ? log(mcap) / ln10 : 0;
          final peDiscount = pe > 0 ? 10 / pe : 0;
          return MapEntry(c, logCap * 2 + roe * 0.3 + peDiscount);
        })
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => _toRow(e.key, e.value)).toList();
  }

  ScreenerRow _toRow(_Candidate c, double score) => ScreenerRow(
        symbol: c.meta.symbol,
        name: c.meta.name,
        sector: c.meta.sector,
        latestClose: c.latestPrice?.close.toStringAsFixed(2),
        score: score.toStringAsFixed(2),
        metrics: ScreenerMetrics(
          dividendYieldPct: c.fundamentals.dividendYieldPct?.toStringAsFixed(2),
          roeTtm: c.fundamentals.roeTtm?.toStringAsFixed(2),
          epsTtmYoyPct: c.fundamentals.epsTtmYoyPct?.toStringAsFixed(2),
          marketCap: c.fundamentals.marketCap?.toStringAsFixed(0),
          pe: c.fundamentals.pe?.toStringAsFixed(2),
          pb: c.fundamentals.pb?.toStringAsFixed(2),
        ),
      );
}

class _Candidate {
  _Candidate({
    required this.meta,
    required this.fundamentals,
    required this.dividends,
    required this.latestPrice,
  });
  final StaticStock meta;
  final StaticFundamentals fundamentals;
  final List<StaticDividend> dividends;
  final StaticPrice? latestPrice;
}
