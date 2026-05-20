/// Best-effort parser for Nepali brokerage SMS confirmations. Targets the
/// Naasa-style "BNo.<n> Purchased/Sold on <date> <ref> (SYMBOL N kitta @
/// PRICE, …) - BAmt.<amount>" shape that Mero/Naasa brokers use; falls back
/// to looser regexes when the bracketed group is missing.
///
/// All parsing is pure on a single SMS body. The repository decides which
/// inbox messages to feed in.

import '../../data/repositories/position_repository.dart';

/// One parsed trade row extracted from an SMS. The SMS itself may contain
/// many of these (multi-leg SELL is common).
class BrokerTradeRow {
  BrokerTradeRow({
    required this.symbol,
    required this.shares,
    required this.grossPricePerShare,
  });
  final String symbol;
  final int shares;
  final double grossPricePerShare;
}

class BrokerSmsParseResult {
  BrokerSmsParseResult({
    required this.trades,
    this.side,
    this.executedAt,
    this.billAmount,
    this.confidence = 0,
  });

  /// One row per (symbol, shares, price) tuple. The SELL example with six
  /// tickers produces six entries here.
  final List<BrokerTradeRow> trades;

  /// Shared by every row in [trades] — a single SMS is BUY or SELL, never
  /// mixed.
  final TradeSide? side;

  final DateTime? executedAt;

  /// `BAmt` from the SMS — gross × shares + fees, summed across rows.
  /// Present on Naasa BUY confirmations; usually absent on multi-row SELLs.
  final double? billAmount;

  /// 0–100 confidence in the *overall* parse (side present, ≥ 1 trade row).
  /// Per-row certainty is implicit — if a row is here, all three fields
  /// (symbol, shares, price) were resolved.
  final int confidence;

  bool get hasMinimumFields => side != null && trades.isNotEmpty;
}

class BrokerSmsParser {
  /// Returns null when the body doesn't look like a trade confirmation at
  /// all — keeps the inbox clean of OTPs and "you've been credited" SMSes.
  BrokerSmsParseResult? tryParse(String body) {
    final normalised = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = normalised.toLowerCase();

    // Cheap rejection: must mention BUY or SELL semantics.
    final hasBuy = lower.contains('buy') ||
        lower.contains('bought') ||
        lower.contains('purchase'); // matches Purchased / purchased
    final hasSell = lower.contains('sell') ||
        lower.contains('sold');
    if (!hasBuy && !hasSell) return null;

    final side = (hasSell && !hasBuy)
        ? TradeSide.sell
        : (hasBuy && !hasSell ? TradeSide.buy : _disambiguate(lower));

    final trades = _extractBracketedTrades(normalised);
    if (trades.isEmpty) {
      // Fallback: try the looser single-stock heuristic for SMSes that
      // don't use the (...) form.
      final single = _extractLooseSingleTrade(normalised);
      if (single != null) trades.add(single);
    }

    final billAmount = _extractBillAmount(normalised);
    final executedAt = _extractDate(normalised);

    // Rough confidence rubric:
    //   25 — side resolved
    //   25 — at least one trade row
    //   25 — every trade row has shares + price (we only emit fully-parsed
    //         rows, so this is implied when trades is non-empty)
    //   15 — date resolved
    //   10 — bill amount resolved
    var conf = 0;
    if (side != null) conf += 25;
    if (trades.isNotEmpty) conf += 50;
    if (executedAt != null) conf += 15;
    if (billAmount != null) conf += 10;

    return BrokerSmsParseResult(
      trades: trades,
      side: side,
      executedAt: executedAt,
      billAmount: billAmount,
      confidence: conf,
    );
  }

  TradeSide? _disambiguate(String lower) {
    // Both appear: lean on which one shows up first.
    final iBuy = lower.indexOf(RegExp(r'\b(buy|bought|purchase[d]?)\b'));
    final iSell = lower.indexOf(RegExp(r'\b(sell|sold)\b'));
    if (iBuy < 0 && iSell < 0) return null;
    if (iBuy < 0) return TradeSide.sell;
    if (iSell < 0) return TradeSide.buy;
    return iBuy < iSell ? TradeSide.buy : TradeSide.sell;
  }

  /// Pulls every `SYMBOL N kitta @ PRICE` tuple out of the first `(...)`
  /// group. Comma-separated tuples are split first.
  List<BrokerTradeRow> _extractBracketedTrades(String body) {
    final group = RegExp(r'\(([^)]+)\)').firstMatch(body);
    if (group == null) return <BrokerTradeRow>[];
    final inner = group.group(1)!;
    final tuplePattern = RegExp(
      // SYMBOL: 3–8 chars of letters/digits, starting with a letter
      r'([A-Z][A-Z0-9]{2,7})\s+'
      // SHARES: integer
      r'(\d{1,7})\s*'
      // Quantifier word — kitta | shares | units — case-insensitive
      r'(?:kitta|shares?|units?|nos?\.?)\s*'
      // Price separator: @, at, =
      r'(?:@|at|=)\s*'
      // PRICE: integer or decimal, optional Rs/NPR prefix tolerated upstream
      r'(\d+(?:\.\d+)?)',
      caseSensitive: false,
    );

    final out = <BrokerTradeRow>[];
    for (final m in tuplePattern.allMatches(inner)) {
      final symbol = m.group(1)!.toUpperCase();
      final shares = int.tryParse(m.group(2)!);
      final price = double.tryParse(m.group(3)!);
      if (shares == null || price == null) continue;
      if (shares <= 0 || price <= 0) continue;
      out.add(BrokerTradeRow(
        symbol: symbol,
        shares: shares,
        grossPricePerShare: price,
      ));
    }
    return out;
  }

  /// Older fallback for SMSes without a `(...)` group — covers the test
  /// fixtures from the original parser revision.
  BrokerTradeRow? _extractLooseSingleTrade(String body) {
    final symbol = _extractSymbol(body);
    final shares = _extractShares(body);
    final price = _extractPrice(body);
    if (symbol == null || shares == null || price == null) return null;
    return BrokerTradeRow(
      symbol: symbol,
      shares: shares,
      grossPricePerShare: price,
    );
  }

  /// "BAmt.247,877.15", "B.Amt: 247877.15", "Bill Amount Rs. 247877".
  double? _extractBillAmount(String body) {
    final m = RegExp(
      r'(?:bill\s*amount|b\.?\s*amt|bamt)\.?\s*[:=]?\s*(?:rs\.?|npr)?\s*'
      r'((?:\d{1,3}(?:,\d{2,3})+|\d+)(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(body);
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', ''));
  }

  static const _symbolBlacklist = {
    'BUY', 'SELL', 'BOUGHT', 'SOLD', 'QTY', 'QUANTITY',
    'NPR', 'RS', 'PER', 'PRICE', 'AT', 'OF', 'FOR', 'YOUR', 'YOU',
    'ORDER', 'TRADE', 'NEPSE', 'TMS', 'BROKER', 'CDS',
    'DEMAT', 'MERO', 'ACCOUNT', 'CONFIRMED', 'SUCCESS',
    'TOTAL', 'NET', 'COMMISSION', 'EDIS', 'BNO', 'BAMT',
    'PLS', 'PLEASE',
  };

  String? _extractSymbol(String body) {
    final candidates = RegExp(r'\b([A-Z][A-Z0-9]{2,7})\b').allMatches(body);
    for (final m in candidates) {
      final t = m.group(1)!;
      if (!_symbolBlacklist.contains(t)) return t;
    }
    return null;
  }

  int? _extractShares(String body) {
    final patterns = [
      RegExp(r'(?:qty|quantity)\s*[:=]?\s*(\d{1,7})', caseSensitive: false),
      RegExp(r'(\d{1,7})\s*(?:shares?|units?|kitta)', caseSensitive: false),
      RegExp(r'(\d{1,7})\s*(?:pieces?|nos?\.?)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  double? _extractPrice(String body) {
    final patterns = [
      RegExp(r'(?:@|at|price[:\s]*|rs\.?[\s:]*|npr[\s:]*)\s*(\d+(?:\.\d+)?)',
          caseSensitive: false),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:per\s*share|/-|\bpps\b)',
          caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null) {
        final v = double.tryParse(m.group(1)!);
        if (v != null && v >= 5 && v <= 100000) return v;
      }
    }
    return null;
  }

  DateTime? _extractDate(String body) {
    final iso = RegExp(r'\b(20\d{2})-(\d{1,2})-(\d{1,2})\b').firstMatch(body);
    if (iso != null) {
      final yy = int.parse(iso.group(1)!);
      final mm = int.parse(iso.group(2)!);
      final dd = int.parse(iso.group(3)!);
      if (mm >= 1 && mm <= 12 && dd >= 1 && dd <= 31) {
        return DateTime(yy, mm, dd);
      }
    }
    final dmy = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](20\d{2})\b').firstMatch(body);
    if (dmy != null) {
      return DateTime(int.parse(dmy.group(3)!), int.parse(dmy.group(2)!),
          int.parse(dmy.group(1)!));
    }
    return null;
  }
}
