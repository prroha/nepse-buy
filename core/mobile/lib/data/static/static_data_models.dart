/// Mirrors of the JSON shapes produced by
/// `core/backend/scripts/export-static-data.ts`. Plain `fromJson` constructors
/// — no codegen yet to keep the data layer cheap to iterate on while the
/// engine port (phase 3) is in flight.
library;

class StaticManifest {
  StaticManifest({
    required this.exportedAt,
    required this.schemaVersion,
    required this.engineVersion,
    required this.counts,
  });

  final DateTime exportedAt;
  final String schemaVersion;
  final String engineVersion;
  final ManifestCounts counts;

  factory StaticManifest.fromJson(Map<String, dynamic> json) => StaticManifest(
        exportedAt: DateTime.parse(json['exportedAt'] as String),
        schemaVersion: json['schemaVersion'] as String,
        engineVersion: json['engineVersion'] as String,
        counts: ManifestCounts.fromJson(
          (json['counts'] as Map).cast<String, dynamic>(),
        ),
      );
}

class ManifestCounts {
  ManifestCounts({
    required this.stocks,
    required this.stocksInScope,
    required this.priceFiles,
    required this.fundamentalsFiles,
    required this.dividendFiles,
  });

  final int stocks;
  final int stocksInScope;
  final int priceFiles;
  final int fundamentalsFiles;
  final int dividendFiles;

  factory ManifestCounts.fromJson(Map<String, dynamic> json) => ManifestCounts(
        stocks: json['stocks'] as int,
        stocksInScope: json['stocksInScope'] as int,
        priceFiles: json['priceFiles'] as int,
        fundamentalsFiles: json['fundamentalsFiles'] as int,
        dividendFiles: json['dividendFiles'] as int,
      );
}

class StaticStock {
  StaticStock({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.status,
    required this.tier,
    required this.isCurated,
  });

  final String symbol;
  final String name;
  final String? sector;
  final String status;
  final String tier;
  final bool isCurated;

  factory StaticStock.fromJson(Map<String, dynamic> json) => StaticStock(
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        sector: json['sector'] as String?,
        status: json['status'] as String,
        tier: json['tier'] as String,
        isCurated: json['isCurated'] as bool,
      );
}

class StaticPrice {
  StaticPrice({
    required this.tradeDate,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime tradeDate;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  factory StaticPrice.fromJson(Map<String, dynamic> json) => StaticPrice(
        tradeDate: DateTime.parse(json['tradeDate'] as String),
        open: double.parse(json['open'] as String),
        high: double.parse(json['high'] as String),
        low: double.parse(json['low'] as String),
        close: double.parse(json['close'] as String),
        volume: double.parse(json['volume'] as String),
      );
}

class StaticFundamentals {
  StaticFundamentals({
    required this.observedAt,
    required this.pe,
    required this.pb,
    required this.eps,
    required this.bookValue,
    required this.marketCap,
    required this.peMedian5y,
    required this.pbMedian5y,
    required this.dividendYieldPct,
    required this.roeTtm,
    required this.roaTtm,
    required this.netMarginTtm,
    required this.epsTtmYoyPct,
    required this.source,
  });

  final DateTime observedAt;
  final double? pe;
  final double? pb;
  final double? eps;
  final double? bookValue;
  final double? marketCap;
  final double? peMedian5y;
  final double? pbMedian5y;
  final double? dividendYieldPct;
  final double? roeTtm;
  final double? roaTtm;
  final double? netMarginTtm;
  final double? epsTtmYoyPct;
  final String source;

  static double? _numOrNull(Object? v) =>
      v == null ? null : double.parse(v as String);

  factory StaticFundamentals.fromJson(Map<String, dynamic> json) =>
      StaticFundamentals(
        observedAt: DateTime.parse(json['observedAt'] as String),
        pe: _numOrNull(json['pe']),
        pb: _numOrNull(json['pb']),
        eps: _numOrNull(json['eps']),
        bookValue: _numOrNull(json['bookValue']),
        marketCap: _numOrNull(json['marketCap']),
        peMedian5y: _numOrNull(json['peMedian5y']),
        pbMedian5y: _numOrNull(json['pbMedian5y']),
        dividendYieldPct: _numOrNull(json['dividendYieldPct']),
        roeTtm: _numOrNull(json['roeTtm']),
        roaTtm: _numOrNull(json['roaTtm']),
        netMarginTtm: _numOrNull(json['netMarginTtm']),
        epsTtmYoyPct: _numOrNull(json['epsTtmYoyPct']),
        source: json['source'] as String,
      );
}

class StaticDividend {
  StaticDividend({
    required this.type,
    required this.pct,
    required this.rightRatio,
    required this.fiscalYear,
    required this.recordDate,
    required this.announcedAt,
  });

  final String type;
  final double? pct;
  final String? rightRatio;
  final String? fiscalYear;
  final DateTime? recordDate;
  final DateTime announcedAt;

  factory StaticDividend.fromJson(Map<String, dynamic> json) => StaticDividend(
        type: json['type'] as String,
        pct: json['pct'] == null ? null : double.parse(json['pct'] as String),
        rightRatio: json['rightRatio'] as String?,
        fiscalYear: json['fiscalYear'] as String?,
        recordDate: json['recordDate'] == null
            ? null
            : DateTime.parse(json['recordDate'] as String),
        announcedAt: DateTime.parse(json['announcedAt'] as String),
      );
}
