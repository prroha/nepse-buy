import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../router/routes.dart';

/// Notification bell widget for app bars.
///
/// Displays a bell icon with a badge showing the unread notification count.
/// Tapping navigates to the notifications screen.
///
/// Example:
/// ```dart
/// AppBar(
///   actions: [
///     NotificationBell(),
///   ],
/// )
/// ```
class NotificationBell extends ConsumerStatefulWidget {
  /// Icon color. Defaults to the app bar's icon color.
  final Color? iconColor;

  /// Badge color. Defaults to error color.
  final Color? badgeColor;

  /// Whether to start polling for unread count.
  final bool enablePolling;

  /// Polling interval in seconds.
  final int pollIntervalSeconds;

  const NotificationBell({
    super.key,
    this.iconColor,
    this.badgeColor,
    this.enablePolling = true,
    this.pollIntervalSeconds = 30,
  });

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  @override
  void initState() {
    super.initState();
    // Start polling for unread count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.enablePolling) {
        ref.read(notificationProvider.notifier).startPolling(
              interval: Duration(seconds: widget.pollIntervalSeconds),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            color: widget.iconColor,
          ),
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: widget.badgeColor ?? AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () => context.push(Routes.notifications),
      tooltip: 'Notifications${unreadCount > 0 ? ' ($unreadCount new)' : ''}',
    );
  }
}

/// A simpler notification indicator (just a dot).
class NotificationIndicator extends ConsumerWidget {
  /// Dot size.
  final double size;

  /// Dot color. Defaults to error color.
  final Color? color;

  /// Whether to show only when there are unread notifications.
  final bool showOnlyWhenUnread;

  const NotificationIndicator({
    super.key,
    this.size = 8,
    this.color,
    this.showOnlyWhenUnread = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    if (showOnlyWhenUnread && unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppColors.error,
        shape: BoxShape.circle,
      ),
    );
  }
}
