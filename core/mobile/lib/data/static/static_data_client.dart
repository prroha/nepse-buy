import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../local/local_cache.dart';
import 'static_data_models.dart';

/// Fetches the JSON bundle published by the GitHub Actions workflow at
/// `STATIC_DATA_URL` (see `api_constants.dart`). Per-file responses are
/// cached in sqflite (`cached_responses` table) keyed by URL so repeat reads
/// are instant and the app keeps working offline.
///
/// The mobile signal engine reads from this client; it never talks to the
/// backend after the v0.9 pivot.
class StaticDataClient {
  StaticDataClient(this._dio, this._cache);

  final Dio _dio;
  final LocalCache _cache;

  String get baseUrl => ApiConstants.staticDataUrl;

  String _manifestKey() => 'static:manifest';
  String _stocksKey() => 'static:stocks';
  String _engineConfigKey() => 'static:signals-engine';
  String _pricesKey(String s) => 'static:prices:$s';
  String _fundKey(String s) => 'static:fundamentals:$s';
  String _divKey(String s) => 'static:dividends:$s';

  /// Pulls the manifest; on success, fetches all referenced files and caches
  /// them. Use sparingly — the user-facing "Refresh data" button is the
  /// natural trigger. Cache TTL is implicit: until next refresh.
  Future<StaticManifest> refreshAll() async {
    final manifest = await _fetchManifest(force: true);
    await Future.wait([
      _fetchStocks(force: true),
      _fetchEngineConfig(force: true),
    ]);
    final stocks = await getStocks();
    final inScope = stocks.where((s) => s.isCurated).map((s) => s.symbol);
    for (final symbol in inScope) {
      await getPrices(symbol, force: true);
      await getFundamentals(symbol, force: true);
      await getDividends(symbol, force: true);
    }
    return manifest;
  }

  Future<StaticManifest> getManifest({bool force = false}) =>
      _fetchManifest(force: force);

  Future<List<StaticStock>> getStocks({bool force = false}) async {
    final raw = await _fetchJson(_stocksKey(), '/stocks.json', force: force);
    final list = raw as List;
    return list
        .map((e) => StaticStock.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<List<StaticPrice>> getPrices(
    String symbol, {
    bool force = false,
  }) async {
    final raw = await _fetchJson(
      _pricesKey(symbol),
      '/prices/$symbol.json',
      force: force,
      allowMissing: true,
    );
    if (raw == null) return const [];
    return (raw as List)
        .map((e) => StaticPrice.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<StaticFundamentals?> getFundamentals(
    String symbol, {
    bool force = false,
  }) async {
    final raw = await _fetchJson(
      _fundKey(symbol),
      '/fundamentals/$symbol.json',
      force: force,
      allowMissing: true,
    );
    if (raw == null) return null;
    return StaticFundamentals.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<List<StaticDividend>> getDividends(
    String symbol, {
    bool force = false,
  }) async {
    final raw = await _fetchJson(
      _divKey(symbol),
      '/dividends/$symbol.json',
      force: force,
      allowMissing: true,
    );
    if (raw == null) return const [];
    return (raw as List)
        .map((e) => StaticDividend.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getEngineConfig({bool force = false}) async {
    final raw = await _fetchEngineConfig(force: force);
    return (raw as Map).cast<String, dynamic>();
  }

  Future<StaticManifest> _fetchManifest({required bool force}) async {
    final raw = await _fetchJson(_manifestKey(), '/manifest.json', force: force);
    return StaticManifest.fromJson((raw as Map).cast<String, dynamic>());
  }

  Future<dynamic> _fetchStocks({required bool force}) =>
      _fetchJson(_stocksKey(), '/stocks.json', force: force);

  Future<dynamic> _fetchEngineConfig({required bool force}) =>
      _fetchJson(_engineConfigKey(), '/signals-engine.json', force: force);

  /// Fetches `path` either from the cache (if `force == false`) or from the
  /// network. Network results are cached on success. When `allowMissing` is
  /// true a 404 returns null instead of throwing — used for per-symbol files
  /// that may not exist yet for new stocks. The null result is itself cached
  /// (as a tombstone) so we don't re-hit the network for every lookup until
  /// the next forced refresh.
  Future<dynamic> _fetchJson(
    String cacheKey,
    String path, {
    required bool force,
    bool allowMissing = false,
  }) async {
    if (!force) {
      final entry = await _cache.get(cacheKey);
      if (entry != null) return jsonDecode(entry.value);
    }
    try {
      final res = await _dio.get<String>(
        '$baseUrl$path',
        options: Options(
          responseType: ResponseType.plain,
          headers: const {'Accept': 'application/json'},
        ),
      );
      final body = res.data;
      if (body == null || body.isEmpty) {
        throw StateError('Empty response for $path');
      }
      final decoded = jsonDecode(body);
      await _cache.set(cacheKey, decoded);
      return decoded;
    } on DioException catch (e) {
      if (allowMissing && e.response?.statusCode == 404) {
        await _cache.set(cacheKey, null);
        return null;
      }
      // Fall back to whatever's in the cache if we have it.
      final cached = await _cache.getJson(cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
  }
}

final staticDataClientProvider = FutureProvider<StaticDataClient>((ref) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final cache = await ref.watch(localCacheProvider.future);
  return StaticDataClient(dio, cache);
});
