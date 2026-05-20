import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../data/repositories/notification_repository.dart';

/// Notification state class
class NotificationState {
  final bool isLoading;
  final String? error;
  final List<AppNotification> notifications;
  final int page;
  final int totalPages;
  final bool hasNext;
  final int unreadCount;
  final bool isRefreshing;
  final bool isLoadingMore;

  const NotificationState({
    this.isLoading = false,
    this.error,
    this.notifications = const [],
    this.page = 1,
    this.totalPages = 1,
    this.hasNext = false,
    this.unreadCount = 0,
    this.isRefreshing = false,
    this.isLoadingMore = false,
  });

  NotificationState copyWith({
    bool? isLoading,
    String? error,
    List<AppNotification>? notifications,
    int? page,
    int? totalPages,
    bool? hasNext,
    int? unreadCount,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool clearError = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      notifications: notifications ?? this.notifications,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      unreadCount: unreadCount ?? this.unreadCount,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Notification state notifier for managing notifications
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  Timer? _pollTimer;

  NotificationNotifier(this._repository) : super(const NotificationState());

  /// Load initial notifications
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    final result = await _repository.getNotifications(
      const GetNotificationsParams(page: 1, limit: PaginationConfig.notificationsPageSize),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: failure.message,
        );
      },
      (paginated) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          notifications: paginated.items,
          page: paginated.page,
          totalPages: paginated.totalPages,
          hasNext: paginated.hasNext,
        );
      },
    );

    // Also fetch unread count
    await _fetchUnreadCount();
  }

  /// Load more notifications (pagination)
  Future<void> loadMore() async {
    if (!state.hasNext || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    final result = await _repository.getNotifications(
      GetNotificationsParams(page: state.page + 1, limit: PaginationConfig.notificationsPageSize),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoadingMore: false,
          error: failure.message,
        );
      },
      (paginated) {
        state = state.copyWith(
          isLoadingMore: false,
          notifications: [...state.notifications, ...paginated.items],
          page: paginated.page,
          totalPages: paginated.totalPages,
          hasNext: paginated.hasNext,
        );
      },
    );
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadNotifications(refresh: true);
  }

  /// Fetch unread count
  Future<void> _fetchUnreadCount() async {
    final result = await _repository.getUnreadCount();

    result.fold(
      (failure) {
        // Silently fail for unread count
      },
      (count) {
        state = state.copyWith(unreadCount: count);
      },
    );
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String id) async {
    final result = await _repository.markAsRead(id);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (notification) {
        // Update the notification in the list
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == id) {
            return n.copyWith(read: true);
          }
          return n;
        }).toList();

        // Decrement unread count
        final newUnreadCount =
            state.unreadCount > 0 ? state.unreadCount - 1 : 0;

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        );
        return true;
      },
    );
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    final result = await _repository.markAllAsRead();

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (count) {
        // Update all notifications to read
        final updatedNotifications = state.notifications.map((n) {
          return n.copyWith(read: true);
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        );
        return true;
      },
    );
  }

  /// Delete a notification
  Future<bool> deleteNotification(String id) async {
    final result = await _repository.deleteNotification(id);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        // Find the notification to check if it was unread
        final notification = state.notifications.firstWhere(
          (n) => n.id == id,
          orElse: () => throw StateError('Notification not found'),
        );

        // Remove from list
        final updatedNotifications =
            state.notifications.where((n) => n.id != id).toList();

        // Update unread count if the deleted notification was unread
        final newUnreadCount =
            !notification.read && state.unreadCount > 0
                ? state.unreadCount - 1
                : state.unreadCount;

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        );
        return true;
      },
    );
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    final result = await _repository.deleteAllNotifications();

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (count) {
        state = state.copyWith(
          notifications: [],
          unreadCount: 0,
          hasNext: false,
          page: 1,
          totalPages: 1,
        );
        return true;
      },
    );
  }

  /// Start polling for unread count
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    stopPolling();
    _pollTimer = Timer.periodic(interval, (_) {
      _fetchUnreadCount();
    });
  }

  /// Stop polling
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

/// Notification provider
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository);
});

/// Unread count provider (for badge display)
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
