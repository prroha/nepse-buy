import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';
import 'base_repository.dart';

enum CorporateActionType { cashDividend, bonusShare, rightShare, stockSplit }

extension CorporateActionTypeExt on CorporateActionType {
  String get wire => switch (this) {
        CorporateActionType.cashDividend => 'CASH_DIVIDEND',
        CorporateActionType.bonusShare => 'BONUS_SHARE',
        CorporateActionType.rightShare => 'RIGHT_SHARE',
        CorporateActionType.stockSplit => 'STOCK_SPLIT',
      };
  String get label => switch (this) {
        CorporateActionType.cashDividend => 'Cash dividend',
        CorporateActionType.bonusShare => 'Bonus share',
        CorporateActionType.rightShare => 'Right share',
        CorporateActionType.stockSplit => 'Stock split',
      };
}

CorporateActionType corporateActionTypeFrom(String s) => switch (s.toUpperCase()) {
      'CASH_DIVIDEND' => CorporateActionType.cashDividend,
      'BONUS_SHARE' => CorporateActionType.bonusShare,
      'RIGHT_SHARE' => CorporateActionType.rightShare,
      'STOCK_SPLIT' => CorporateActionType.stockSplit,
      _ => CorporateActionType.cashDividend,
    };

class CorporateAction {
  final String id;
  final String stockId;
  final String symbol;
  final CorporateActionType type;
  final String? pct;
  final String? rightRatio;
  final String? fiscalYear;
  final String? recordDate;
  final String announcedAt;
  final String source;

  const CorporateAction({
    required this.id,
    required this.stockId,
    required this.symbol,
    required this.type,
    required this.pct,
    required this.rightRatio,
    required this.fiscalYear,
    required this.recordDate,
    required this.announcedAt,
    required this.source,
  });

  factory CorporateAction.fromJson(Map<String, dynamic> json) => CorporateAction(
        id: json['id'] as String,
        stockId: json['stockId'] as String,
        symbol: json['symbol'] as String,
        type: corporateActionTypeFrom(json['type'] as String),
        pct: json['pct'] as String?,
        rightRatio: json['rightRatio'] as String?,
        fiscalYear: json['fiscalYear'] as String?,
        recordDate: json['recordDate'] as String?,
        announcedAt: json['announcedAt'] as String,
        source: json['source'] as String,
      );
}

class CorporateActionInput {
  final String symbol;
  final CorporateActionType type;
  final double? pct;
  final String? rightRatio;
  final String? fiscalYear;
  final DateTime? recordDate;
  const CorporateActionInput({
    required this.symbol,
    required this.type,
    this.pct,
    this.rightRatio,
    this.fiscalYear,
    this.recordDate,
  });
}

final corporateActionRepositoryProvider = Provider<CorporateActionRepository>((ref) {
  return CorporateActionRepositoryImpl(dio: ref.watch(dioProvider));
});

abstract class CorporateActionRepository {
  Future<Either<Failure, List<CorporateAction>>> listForSymbol(String symbol);
  Future<Either<Failure, CorporateAction>> create(CorporateActionInput input);
  Future<Either<Failure, void>> remove(String id);
}

class CorporateActionRepositoryImpl with BaseRepository implements CorporateActionRepository {
  final Dio dio;
  CorporateActionRepositoryImpl({required this.dio});

  @override
  Future<Either<Failure, List<CorporateAction>>> listForSymbol(String symbol) {
    return safeCall(() async {
      final res = await dio.get(
        ApiConstants.corporateActions,
        queryParameters: {'symbol': symbol.toUpperCase()},
      );
      return (res.data['data'] as List)
          .map((e) => CorporateAction.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  @override
  Future<Either<Failure, CorporateAction>> create(CorporateActionInput input) {
    return safeCall(() async {
      final res = await dio.post(ApiConstants.corporateActions, data: {
        'symbol': input.symbol.toUpperCase(),
        'type': input.type.wire,
        if (input.pct != null) 'pct': input.pct,
        if (input.rightRatio != null) 'rightRatio': input.rightRatio,
        if (input.fiscalYear != null) 'fiscalYear': input.fiscalYear,
        if (input.recordDate != null) 'recordDate': input.recordDate!.toUtc().toIso8601String(),
      });
      return CorporateAction.fromJson(res.data['data'] as Map<String, dynamic>);
    });
  }

  @override
  Future<Either<Failure, void>> remove(String id) {
    return safeCall(() async {
      await dio.delete(ApiConstants.corporateActionById(id));
    });
  }
}
