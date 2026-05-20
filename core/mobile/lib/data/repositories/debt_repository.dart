import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../local/user_data_repository.dart';
import 'base_repository.dart';

class DebtAccount {
  final String id;
  final String name;
  final String balance;
  final String interestRate;
  final bool isActive;
  final String createdAt;

  const DebtAccount({
    required this.id,
    required this.name,
    required this.balance,
    required this.interestRate,
    required this.isActive,
    required this.createdAt,
  });

  factory DebtAccount.fromJson(Map<String, dynamic> json) => DebtAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        balance: json['balance'].toString(),
        interestRate: json['interestRate'].toString(),
        isActive: json['isActive'] as bool,
        createdAt: json['createdAt'] as String,
      );
}

class DebtAccountInput {
  final String name;
  final String balance;
  final String interestRate;
  const DebtAccountInput({required this.name, required this.balance, required this.interestRate});
}

class DebtAccountPatch {
  final String? name;
  final String? balance;
  final String? interestRate;
  final bool? isActive;
  const DebtAccountPatch({this.name, this.balance, this.interestRate, this.isActive});

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (balance != null) 'balance': balance,
        if (interestRate != null) 'interestRate': interestRate,
        if (isActive != null) 'isActive': isActive,
      };
}

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(ref: ref);
});

abstract class DebtRepository {
  Future<Either<Failure, List<DebtAccount>>> list();
  Future<Either<Failure, DebtAccount>> create(DebtAccountInput input);
  Future<Either<Failure, DebtAccount>> update(String id, DebtAccountPatch patch);
  Future<Either<Failure, void>> remove(String id);
}

/// Local-backed debt-accounts repo. Rows live in `user_debt_accounts`; the
/// repo translates between the screen-facing string DTOs and the sqflite
/// row shape.
class DebtRepositoryImpl with BaseRepository implements DebtRepository {
  DebtRepositoryImpl({required this.ref});
  final Ref ref;
  static const _uuid = Uuid();

  Future<UserDataRepository> get _userData =>
      ref.read(userDataRepositoryProvider.future);

  static DebtAccount _fromRow(Map<String, Object?> r) => DebtAccount(
        id: r['id'] as String,
        name: r['name'] as String,
        balance: (r['outstanding_balance'] as num).toString(),
        interestRate: (r['annual_rate_pct'] as num).toString(),
        isActive: (r['is_active'] as int? ?? 1) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
                r['created_at'] as int)
            .toIso8601String(),
      );

  @override
  Future<Either<Failure, List<DebtAccount>>> list() {
    return safeCall(() async {
      final userData = await _userData;
      final rows = await userData.listDebtAccounts();
      return rows.map(_fromRow).toList(growable: false);
    });
  }

  @override
  Future<Either<Failure, DebtAccount>> create(DebtAccountInput input) {
    return safeCall(() async {
      final userData = await _userData;
      final id = _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      final row = <String, Object?>{
        'id': id,
        'name': input.name,
        'outstanding_balance': double.parse(input.balance),
        'annual_rate_pct': double.parse(input.interestRate),
        'monthly_surplus': 100000.0,
        'is_active': 1,
        'created_at': now,
      };
      await userData.upsertDebtAccount(row);
      return _fromRow(row);
    });
  }

  @override
  Future<Either<Failure, DebtAccount>> update(
      String id, DebtAccountPatch patch) {
    return safeCall(() async {
      final userData = await _userData;
      final all = await userData.listDebtAccounts();
      final existing = all.firstWhere(
        (r) => r['id'] == id,
        orElse: () => throw StateError('Debt account $id not found'),
      );
      final merged = <String, Object?>{
        ...existing,
        if (patch.name != null) 'name': patch.name,
        if (patch.balance != null)
          'outstanding_balance': double.parse(patch.balance!),
        if (patch.interestRate != null)
          'annual_rate_pct': double.parse(patch.interestRate!),
        if (patch.isActive != null) 'is_active': patch.isActive! ? 1 : 0,
      };
      await userData.upsertDebtAccount(merged);
      return _fromRow(merged);
    });
  }

  @override
  Future<Either<Failure, void>> remove(String id) {
    return safeCall(() async {
      final userData = await _userData;
      await userData.deleteDebtAccount(id);
    });
  }
}
