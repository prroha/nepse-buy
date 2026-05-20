import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';
import 'base_repository.dart';

/// Admin repository provider
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(dio: ref.watch(dioProvider));
});

/// Dashboard stats model
class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int adminUsers;
  final int recentSignups;
  final List<SignupByDay> signupsByDay;

  const DashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.adminUsers,
    required this.recentSignups,
    required this.signupsByDay,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return DashboardStats(
      totalUsers: data['totalUsers'] as int,
      activeUsers: data['activeUsers'] as int,
      inactiveUsers: data['inactiveUsers'] as int,
      adminUsers: data['adminUsers'] as int,
      recentSignups: data['recentSignups'] as int,
      signupsByDay: (data['signupsByDay'] as List<dynamic>)
          .map((e) => SignupByDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SignupByDay {
  final String date;
  final int count;

  const SignupByDay({required this.date, required this.count});

  factory SignupByDay.fromJson(Map<String, dynamic> json) {
    return SignupByDay(
      date: json['date'] as String,
      count: json['count'] as int,
    );
  }
}

/// Admin user model
class AdminUser {
  final String id;
  final String email;
  final String? name;
  final String role;
  final bool isActive;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminUser({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.isActive,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      emailVerified: json['emailVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Check if user has admin access (ADMIN or SUPER_ADMIN)
  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';

  /// Check if user is a super admin (platform owner)
  bool get isSuperAdmin => role == 'SUPER_ADMIN';
}

/// Audit action enum
enum AuditAction {
  create,
  read,
  update,
  delete,
  login,
  logout,
  loginFailed,
  passwordChange,
  passwordReset,
  emailVerify,
  adminAction;

  static AuditAction fromString(String value) {
    switch (value) {
      case 'CREATE':
        return AuditAction.create;
      case 'READ':
        return AuditAction.read;
      case 'UPDATE':
        return AuditAction.update;
      case 'DELETE':
        return AuditAction.delete;
      case 'LOGIN':
        return AuditAction.login;
      case 'LOGOUT':
        return AuditAction.logout;
      case 'LOGIN_FAILED':
        return AuditAction.loginFailed;
      case 'PASSWORD_CHANGE':
        return AuditAction.passwordChange;
      case 'PASSWORD_RESET':
        return AuditAction.passwordReset;
      case 'EMAIL_VERIFY':
        return AuditAction.emailVerify;
      case 'ADMIN_ACTION':
        return AuditAction.adminAction;
      default:
        return AuditAction.read;
    }
  }

  String get displayName {
    switch (this) {
      case AuditAction.create:
        return 'Create';
      case AuditAction.read:
        return 'Read';
      case AuditAction.update:
        return 'Update';
      case AuditAction.delete:
        return 'Delete';
      case AuditAction.login:
        return 'Login';
      case AuditAction.logout:
        return 'Logout';
      case AuditAction.loginFailed:
        return 'Login Failed';
      case AuditAction.passwordChange:
        return 'Password Change';
      case AuditAction.passwordReset:
        return 'Password Reset';
      case AuditAction.emailVerify:
        return 'Email Verify';
      case AuditAction.adminAction:
        return 'Admin Action';
    }
  }

  String get apiValue {
    switch (this) {
      case AuditAction.create:
        return 'CREATE';
      case AuditAction.read:
        return 'READ';
      case AuditAction.update:
        return 'UPDATE';
      case AuditAction.delete:
        return 'DELETE';
      case AuditAction.login:
        return 'LOGIN';
      case AuditAction.logout:
        return 'LOGOUT';
      case AuditAction.loginFailed:
        return 'LOGIN_FAILED';
      case AuditAction.passwordChange:
        return 'PASSWORD_CHANGE';
      case AuditAction.passwordReset:
        return 'PASSWORD_RESET';
      case AuditAction.emailVerify:
        return 'EMAIL_VERIFY';
      case AuditAction.adminAction:
        return 'ADMIN_ACTION';
    }
  }
}

/// Audit log user model (partial user info)
class AuditLogUser {
  final String id;
  final String email;
  final String? name;

  const AuditLogUser({
    required this.id,
    required this.email,
    this.name,
  });

  factory AuditLogUser.fromJson(Map<String, dynamic> json) {
    return AuditLogUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
    );
  }
}

/// Audit log model
class AuditLog {
  final String id;
  final String? userId;
  final AuditAction action;
  final String entity;
  final String? entityId;
  final Map<String, dynamic>? changes;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final AuditLogUser? user;

  const AuditLog({
    required this.id,
    this.userId,
    required this.action,
    required this.entity,
    this.entityId,
    this.changes,
    this.ipAddress,
    this.userAgent,
    this.metadata,
    required this.createdAt,
    this.user,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      action: AuditAction.fromString(json['action'] as String),
      entity: json['entity'] as String,
      entityId: json['entityId'] as String?,
      changes: json['changes'] as Map<String, dynamic>?,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: json['user'] != null
          ? AuditLogUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Paginated audit logs response
class PaginatedAuditLogs {
  final List<AuditLog> logs;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginatedAuditLogs({
    required this.logs,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginatedAuditLogs.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final pagination = data['pagination'] as Map<String, dynamic>;
    return PaginatedAuditLogs(
      logs: (data['items'] as List<dynamic>)
          .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
      hasNext: pagination['hasNext'] as bool,
      hasPrev: pagination['hasPrev'] as bool,
    );
  }
}

/// Paginated users response
class PaginatedUsers {
  final List<AdminUser> users;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginatedUsers({
    required this.users,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginatedUsers.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final pagination = data['pagination'] as Map<String, dynamic>;
    return PaginatedUsers(
      users: (data['items'] as List<dynamic>)
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
      hasNext: pagination['hasNext'] as bool,
      hasPrev: pagination['hasPrev'] as bool,
    );
  }
}

/// Admin repository interface
abstract class AdminRepository {
  /// Get dashboard stats
  Future<Either<Failure, DashboardStats>> getStats();

  /// Get paginated users
  Future<Either<Failure, PaginatedUsers>> getUsers({
    int page = 1,
    int limit = 10,
    String? search,
    String? role,
    bool? isActive,
  });

  /// Get user by ID
  Future<Either<Failure, AdminUser>> getUserById(String id);

  /// Update user
  Future<Either<Failure, AdminUser>> updateUser(
    String id, {
    String? role,
    bool? isActive,
    String? name,
  });

  /// Delete user (soft delete)
  Future<Either<Failure, void>> deleteUser(String id);

  /// Get paginated audit logs
  Future<Either<Failure, PaginatedAuditLogs>> getAuditLogs({
    int page = 1,
    int limit = 20,
    String? userId,
    AuditAction? action,
    String? entity,
    String? entityId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  });

  /// Get audit log by ID
  Future<Either<Failure, AuditLog>> getAuditLogById(String id);

  /// Get available entity types for filtering
  Future<Either<Failure, List<String>>> getAuditLogEntityTypes();

  /// Get available action types for filtering
  Future<Either<Failure, List<AuditAction>>> getAuditLogActionTypes();
}

/// Admin repository implementation
class AdminRepositoryImpl with BaseRepository implements AdminRepository {
  final Dio _dio;

  AdminRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Either<Failure, DashboardStats>> getStats() async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.adminStats);
      return DashboardStats.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, PaginatedUsers>> getUsers({
    int page = 1,
    int limit = 10,
    String? search,
    String? role,
    bool? isActive,
  }) async {
    return safeCall(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (role != null) {
        queryParams['role'] = role;
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive;
      }

      final response = await _dio.get(
        ApiConstants.adminUsers,
        queryParameters: queryParams,
      );
      return PaginatedUsers.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, AdminUser>> getUserById(String id) async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.adminUserById(id));
      final data = response.data['data'] ?? response.data;
      return AdminUser.fromJson(data['user'] as Map<String, dynamic>);
    });
  }

  @override
  Future<Either<Failure, AdminUser>> updateUser(
    String id, {
    String? role,
    bool? isActive,
    String? name,
  }) async {
    return safeCall(() async {
      final data = <String, dynamic>{};
      if (role != null) data['role'] = role;
      if (isActive != null) data['isActive'] = isActive;
      if (name != null) data['name'] = name;

      final response = await _dio.patch(
        ApiConstants.adminUserById(id),
        data: data,
      );
      final responseData = response.data['data'] ?? response.data;
      return AdminUser.fromJson(responseData['user'] as Map<String, dynamic>);
    });
  }

  @override
  Future<Either<Failure, void>> deleteUser(String id) async {
    return safeCall(() async {
      await _dio.delete(ApiConstants.adminUserById(id));
    });
  }

  @override
  Future<Either<Failure, PaginatedAuditLogs>> getAuditLogs({
    int page = 1,
    int limit = 20,
    String? userId,
    AuditAction? action,
    String? entity,
    String? entityId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    return safeCall(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }
      if (action != null) {
        queryParams['action'] = action.apiValue;
      }
      if (entity != null && entity.isNotEmpty) {
        queryParams['entity'] = entity;
      }
      if (entityId != null && entityId.isNotEmpty) {
        queryParams['entityId'] = entityId;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        ApiConstants.adminAuditLogs,
        queryParameters: queryParams,
      );
      return PaginatedAuditLogs.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, AuditLog>> getAuditLogById(String id) async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.adminAuditLogById(id));
      final data = response.data['data'] ?? response.data;
      return AuditLog.fromJson(data['log'] as Map<String, dynamic>);
    });
  }

  @override
  Future<Either<Failure, List<String>>> getAuditLogEntityTypes() async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.adminAuditLogEntityTypes);
      final data = response.data['data'] ?? response.data;
      return (data['entityTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList();
    });
  }

  @override
  Future<Either<Failure, List<AuditAction>>> getAuditLogActionTypes() async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.adminAuditLogActionTypes);
      final data = response.data['data'] ?? response.data;
      return (data['actionTypes'] as List<dynamic>)
          .map((e) => AuditAction.fromString(e as String))
          .toList();
    });
  }
}
