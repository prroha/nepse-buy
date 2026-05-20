import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/notification_provider.dart';
import '../../widgets/layout/empty_state.dart';
import '../../widgets/molecules/app_snackbar.dart';
import '../../widgets/notifications/notification_item.dart';

/// Notifications list screen.
///
/// Displays all user notifications with pull-to-refresh, pagination,
/// and actions like mark as read and delete.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load notifications on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(notificationProvider);
      if (!state.isLoadingMore && state.hasNext) {
        ref.read(notificationProvider.notifier).loadMore();
      }
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(notificationProvider.notifier).refresh();
  }

  void _showError(String message) {
    AppSnackbar.error(context, message);
  }

  Future<void> _handleMarkAsRead(String id) async {
    final success =
        await ref.read(notificationProvider.notifier).markAsRead(id);
    if (!success && mounted) {
      _showError('Failed to mark notification as read');
    }
  }

  Future<void> _handleMarkAllAsRead() async {
    final success =
        await ref.read(notificationProvider.notifier).markAllAsRead();
    if (mounted) {
      if (success) {
        AppSnackbar.success(context, 'All notifications marked as read');
      } else {
        _showError('Failed to mark all as read');
      }
    }
  }

  Future<void> _handleDelete(String id) async {
    final success =
        await ref.read(notificationProvider.notifier).deleteNotification(id);
    if (mounted) {
      if (success) {
        AppSnackbar.success(context, 'Notification deleted');
      } else {
        _showError('Failed to delete notification');
      }
    }
  }

  Future<void> _handleDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all notifications'),
        content: const Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(notificationProvider.notifier).deleteAllNotifications();
      if (mounted) {
        if (success) {
          AppSnackbar.success(context, 'All notifications deleted');
        } else {
          _showError('Failed to delete all notifications');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final unreadCount =
        state.notifications.where((n) => !n.read).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (state.notifications.isNotEmpty) ...[
            if (unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: _handleMarkAllAsRead,
                tooltip: 'Mark all as read',
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'deleteAll') {
                  _handleDeleteAll();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'deleteAll',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Delete all'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(state, colorScheme),
    );
  }

  Widget _buildBody(NotificationState state, ColorScheme colorScheme) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return EmptyState.error(
        message: state.error,
        onAction: () => ref.read(notificationProvider.notifier).loadNotifications(),
      );
    }

    if (state.notifications.isEmpty) {
      return const EmptyState.noNotifications();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: colorScheme.outlineVariant,
        ),
        itemBuilder: (context, index) {
          if (index == state.notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final notification = state.notifications[index];
          return NotificationItemWidget(
            notification: notification,
            onTap: () {
              // Handle notification action if data contains actionUrl
              final actionUrl = notification.data?['actionUrl'] as String?;
              if (actionUrl != null) {
                context.push(actionUrl);
              }
            },
            onMarkAsRead: notification.read
                ? null
                : () => _handleMarkAsRead(notification.id),
            onDelete: () => _handleDelete(notification.id),
          );
        },
      ),
    );
  }
}
