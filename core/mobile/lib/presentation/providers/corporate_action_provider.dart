import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/corporate_action_repository.dart';

/// Read-only — list of recent corporate actions for a symbol.
final corporateActionsForSymbolProvider =
    FutureProvider.family<List<CorporateAction>, String>((ref, symbol) async {
  final repo = ref.read(corporateActionRepositoryProvider);
  final result = await repo.listForSymbol(symbol);
  return result.fold((f) => throw Exception(f.message), (ok) => ok);
});
