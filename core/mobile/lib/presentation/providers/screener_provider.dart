import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/screener_repository.dart';

final screenerProvider = FutureProvider.family<List<ScreenerRow>, ScreenerType>((ref, type) async {
  final repo = ref.read(screenerRepositoryProvider);
  final result = await repo.rank(type);
  return result.fold((f) => throw Exception(f.message), (ok) => ok);
});
