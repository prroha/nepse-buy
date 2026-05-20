import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/notification_repository.dart';

/// A single notification item widget.
///
/// Displays the notification with type icon, title, message, and time.
/// Supports actions like mark as read and delete.
///
/// Example:
/// ```dart
/// NotificationItemWidget(
///   notification: notification,
///   onTap: () => handleTap(notification),
///   onMarkAsRead: () => markAsRead(notification.id),
///   onDelete: () => deleteNotification(notification.id),
/// )
/// ```
class NotificationItemWidget extends StatelessWidget {
  /// The notification to display.
  final AppNotification notification;

  /// Called when the notification is tapped.
  final VoidCallback? onTap;

  /// Called when the notification should be marked as read.
  final VoidCallback? onMarkAsRead;

  /// Called when the notification should be deleted.
  final VoidCallback? onDelete;

  /// Whether to show a compact version (for lists).
  final bool compact;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: Key(notification.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.read && onMarkAsRead != null) {
            onMarkAsRead!();
          }
          onTap?.call();
        },
        child: Container(
          // Tighter padding
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: notification.read
                ? null
                : (theme.brightness == Brightness.dark
                    ? colorScheme.primary.withAlpha(20)
                    : colorScheme.primary.withAlpha(10)),
            border: Border(
              left: BorderSide(
                color: _getTypeColor(notification.type),
                width: 3, // Slightly thinner
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon - tighter
              Container(
                padding: const EdgeInsets.all(6), // Tighter
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  size: compact ? 16 : 18, // Smaller
                  color: _getTypeColor(notification.type),
                ),
              ),
              AppSpacing.gapSm, // Tighter gap

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.read
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              fontSize: compact ? 13 : 14, // Smaller
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.read) ...[
                          AppSpacing.gapXs, // Tighter gap
                          Container(
                            width: 6, // Smaller dot
                            height: 6,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2), // Tighter
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13, // Smaller
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2), // Tighter
                    Text(
                      _formatTimeAgo(notification.createdAt),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withAlpha(150),
                        fontSize: 11, // Smaller
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              if (onMarkAsRead != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18, // Smaller
                    color: colorScheme.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'read' && onMarkAsRead != null) {
                      onMarkAsRead!();
                    } else if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (context) => [
                    if (!notification.read && onMarkAsRead != null)
                      const PopupMenuItem(
                        value: 'read',
                        child: Row(
                          children: [
                            Icon(Icons.check, size: 20),
                            SizedBox(width: 8),
                            Text('Mark as read'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.system:
        return Icons.settings_outlined;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return AppColors.info;
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.error:
        return AppColors.error;
      case NotificationType.system:
        return AppColors.textMuted;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
