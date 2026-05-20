import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';
import 'base_repository.dart';

/// Notification repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(dio: ref.watch(dioProvider));
});

/// Notification type enum
enum NotificationType {
  info,
  success,
  warning,
  error,
  system,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.info:
        return 'INFO';
      case NotificationType.success:
        return 'SUCCESS';
      case NotificationType.warning:
        return 'WARNING';
      case NotificationType.error:
        return 'ERROR';
      case NotificationType.system:
        return 'SYSTEM';
    }
  }

  static NotificationType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INFO':
        return NotificationType.info;
      case 'SUCCESS':
        return NotificationType.success;
      case 'WARNING':
        return NotificationType.warning;
      case 'ERROR':
        return NotificationType.error;
      case 'SYSTEM':
        return NotificationType.system;
      default:
        return NotificationType.info;
    }
  }
}

/// Notification model
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationTypeExtension.fromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      read: json['read'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Paginated notifications response
class PaginatedNotifications {
  final List<AppNotification> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginatedNotifications({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginatedNotifications.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final items = (data['items'] as List<dynamic>)
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
    final pagination = data['pagination'] as Map<String, dynamic>;

    return PaginatedNotifications(
      items: items,
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
      hasNext: pagination['hasNext'] as bool,
      hasPrev: pagination['hasPrev'] as bool,
    );
  }
}

/// Get notifications request parameters
class GetNotificationsParams {
  final int? page;
  final int? limit;
  final bool? read;
  final NotificationType? type;

  const GetNotificationsParams({
    this.page,
    this.limit,
    this.read,
    this.type,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      if (page != null) 'page': page.toString(),
      if (limit != null) 'limit': limit.toString(),
      if (read != null) 'read': read.toString(),
      if (type != null) 'type': type!.value,
    };
  }
}

/// Notification repository interface
abstract class NotificationRepository {
  /// Get notifications with pagination
  Future<Either<Failure, PaginatedNotifications>> getNotifications([
    GetNotificationsParams? params,
  ]);

  /// Get single notification by ID
  Future<Either<Failure, AppNotification>> getNotificationById(String id);

  /// Get unread notification count
  Future<Either<Failure, int>> getUnreadCount();

  /// Mark a notification as read
  Future<Either<Failure, AppNotification>> markAsRead(String id);

  /// Mark all notifications as read
  Future<Either<Failure, int>> markAllAsRead();

  /// Delete a notification
  Future<Either<Failure, void>> deleteNotification(String id);

  /// Delete all notifications
  Future<Either<Failure, int>> deleteAllNotifications();
}

/// Notification repository implementation
class NotificationRepositoryImpl
    with BaseRepository
    implements NotificationRepository {
  final Dio _dio;

  NotificationRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Either<Failure, PaginatedNotifications>> getNotifications([
    GetNotificationsParams? params,
  ]) async {
    return safeCall(() async {
      final response = await _dio.get(
        ApiConstants.notifications,
        queryParameters: params?.toQueryParams(),
      );
      return PaginatedNotifications.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, AppNotification>> getNotificationById(String id) async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.notificationById(id));
      final data = response.data['data'] ?? response.data;
      return AppNotification.fromJson(data['notification'] as Map<String, dynamic>);
    });
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.notificationsUnreadCount);
      final data = response.data['data'] ?? response.data;
      return data['count'] as int;
    });
  }

  @override
  Future<Either<Failure, AppNotification>> markAsRead(String id) async {
    return safeCall(() async {
      final response = await _dio.patch(ApiConstants.notificationMarkRead(id));
      final data = response.data['data'] ?? response.data;
      return AppNotification.fromJson(data['notification'] as Map<String, dynamic>);
    });
  }

  @override
  Future<Either<Failure, int>> markAllAsRead() async {
    return safeCall(() async {
      final response = await _dio.patch(ApiConstants.notificationsReadAll);
      final data = response.data['data'] ?? response.data;
      return data['count'] as int;
    });
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String id) async {
    return safeCall(() async {
      await _dio.delete(ApiConstants.notificationById(id));
    });
  }

  @override
  Future<Either<Failure, int>> deleteAllNotifications() async {
    return safeCall(() async {
      final response = await _dio.delete(ApiConstants.notifications);
      final data = response.data['data'] ?? response.data;
      return data['count'] as int;
    });
  }
}
