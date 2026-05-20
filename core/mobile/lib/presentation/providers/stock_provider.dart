import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../data/repositories/stock_repository.dart';

class StockSearchQuery {
  final String? query;
  final bool curatedOnly;
  const StockSearchQuery({this.query, this.curatedOnly = false});
}

/// Stock search results (used by the "Add to watchlist" screen).
final stockSearchProvider = FutureProvider.family<StockSearchPage, StockSearchQuery>(
  (ref, q) async {
    final repo = ref.read(stockRepositoryProvider);
    final result = await repo.list(query: q.query, curatedOnly: q.curatedOnly, page: 1, limit: 30);
    return result.fold((f) => throw Exception(f.message), (ok) => ok);
  },
);

/// Detail for a single symbol — used by the stock detail screen.
final stockDetailProvider = FutureProvider.family<StockDetail, String>((ref, symbol) async {
  final repo = ref.read(stockRepositoryProvider);
  final result = await repo.getBySymbol(symbol);
  return result.fold((Failure f) => throw Exception(f.message), (StockDetail ok) => ok);
});
