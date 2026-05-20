import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';
import 'base_repository.dart';

/// Session repository provider
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(dio: ref.watch(dioProvider));
});

/// Session model
class Session {
  final String id;
  final String? deviceName;
  final String? browser;
  final String? os;
  final String? ipAddress;
  final DateTime lastActiveAt;
  final DateTime createdAt;
  final bool isCurrent;

  const Session({
    required this.id,
    this.deviceName,
    this.browser,
    this.os,
    this.ipAddress,
    required this.lastActiveAt,
    required this.createdAt,
    required this.isCurrent,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      deviceName: json['deviceName'] as String?,
      browser: json['browser'] as String?,
      os: json['os'] as String?,
      ipAddress: json['ipAddress'] as String?,
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  /// Get a display name for the device
  String get displayName {
    if (deviceName != null && deviceName!.isNotEmpty) {
      return deviceName!;
    }
    if (browser != null && os != null) {
      return '$browser on $os';
    }
    if (browser != null) {
      return browser!;
    }
    if (os != null) {
      return os!;
    }
    return 'Unknown Device';
  }
}

/// Revoke all sessions response
class RevokeAllSessionsResponse {
  final int revokedCount;

  const RevokeAllSessionsResponse({required this.revokedCount});

  factory RevokeAllSessionsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return RevokeAllSessionsResponse(
      revokedCount: data['revokedCount'] as int? ?? 0,
    );
  }
}

/// Session repository interface
abstract class SessionRepository {
  /// Get all active sessions for the current user
  Future<Either<Failure, List<Session>>> getSessions();

  /// Revoke a specific session
  Future<Either<Failure, void>> revokeSession(String sessionId);

  /// Revoke all other sessions except current
  Future<Either<Failure, RevokeAllSessionsResponse>> revokeAllOtherSessions();
}

/// Session repository implementation
class SessionRepositoryImpl with BaseRepository implements SessionRepository {
  final Dio _dio;

  SessionRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Either<Failure, List<Session>>> getSessions() async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.sessions);
      final data = response.data['data'] ?? response.data;
      final sessionsJson = data['sessions'] as List<dynamic>;
      return sessionsJson
          .map((json) => Session.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<Either<Failure, void>> revokeSession(String sessionId) async {
    return safeCall(() async {
      await _dio.delete(ApiConstants.sessionById(sessionId));
    });
  }

  @override
  Future<Either<Failure, RevokeAllSessionsResponse>> revokeAllOtherSessions() async {
    return safeCall(() async {
      final response = await _dio.delete(ApiConstants.sessions);
      return RevokeAllSessionsResponse.fromJson(response.data);
    });
  }
}
