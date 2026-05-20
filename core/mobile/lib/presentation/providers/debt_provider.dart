import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../data/repositories/debt_repository.dart';

final debtAccountsProvider = AsyncNotifierProvider<DebtAccountsNotifier, List<DebtAccount>>(
  DebtAccountsNotifier.new,
);

class DebtAccountsNotifier extends AsyncNotifier<List<DebtAccount>> {
  @override
  Future<List<DebtAccount>> build() async {
    final repo = ref.read(debtRepositoryProvider);
    final result = await repo.list();
    return result.fold<List<DebtAccount>>(
      (Failure f) => throw Exception(f.message),
      (List<DebtAccount> ok) => ok,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(debtRepositoryProvider);
      final result = await repo.list();
      return result.fold<List<DebtAccount>>(
        (Failure f) => throw Exception(f.message),
        (List<DebtAccount> ok) => ok,
      );
    });
  }

  Future<bool> create(DebtAccountInput input) async {
    final repo = ref.read(debtRepositoryProvider);
    final result = await repo.create(input);
    return result.fold((_) => false, (_) async {
      await refresh();
      return true;
    });
  }

  Future<bool> edit(String id, DebtAccountPatch patch) async {
    final repo = ref.read(debtRepositoryProvider);
    final result = await repo.update(id, patch);
    return result.fold((_) => false, (_) async {
      await refresh();
      return true;
    });
  }

  Future<bool> remove(String id) async {
    final repo = ref.read(debtRepositoryProvider);
    final result = await repo.remove(id);
    return result.fold((_) => false, (_) async {
      await refresh();
      return true;
    });
  }
}
