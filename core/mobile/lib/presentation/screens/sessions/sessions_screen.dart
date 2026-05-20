import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/session_repository.dart';
import '../../providers/session_provider.dart';
import '../../router/routes.dart';
import '../../widgets/molecules/app_snackbar.dart';

/// Sessions screen displaying active user sessions
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  @override
  void initState() {
    super.initState();
    // Load sessions when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionsProvider.notifier).loadSessions();
    });
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dateTime.month - 1];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month ${dateTime.day}, ${dateTime.year} at $hour:$minute';
  }

  IconData _getDeviceIcon(Session session) {
    final deviceName = session.deviceName?.toLowerCase() ?? '';
    final os = session.os?.toLowerCase() ?? '';

    if (deviceName.contains('iphone') || deviceName.contains('android phone')) {
      return Icons.phone_android;
    }
    if (deviceName.contains('ipad') || deviceName.contains('tablet')) {
      return Icons.tablet;
    }
    if (deviceName.contains('desktop') ||
        os.contains('windows') ||
        os.contains('macos') ||
        os.contains('linux')) {
      return Icons.computer;
    }
    return Icons.language;
  }

  Future<void> _handleRevokeSession(Session session) async {
    final success = await ref.read(sessionsProvider.notifier).revokeSession(session.id);

    if (mounted) {
      if (success) {
        AppSnackbar.success(
          context,
          'Session revoked',
          description: 'The session has been signed out.',
        );
      } else {
        final error = ref.read(sessionsProvider).error;
        AppSnackbar.error(
          context,
          'Failed to revoke session',
          description: error ?? 'An unexpected error occurred.',
        );
      }
    }
  }

  Future<void> _handleRevokeAllOther() async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out other devices?'),
        content: Text(
          'This will sign out ${ref.read(sessionsProvider).otherSessionsCount} '
          'other session${ref.read(sessionsProvider).otherSessionsCount == 1 ? '' : 's'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sign Out All',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final count = await ref.read(sessionsProvider.notifier).revokeAllOtherSessions();

      if (mounted) {
        if (count > 0) {
          AppSnackbar.success(
            context,
            'Sessions revoked',
            description: '$count session${count == 1 ? '' : 's'} signed out.',
          );
        } else {
          final error = ref.read(sessionsProvider).error;
          if (error != null) {
            AppSnackbar.error(
              context,
              'Failed to revoke sessions',
              description: error,
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Active Sessions'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.settings),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.sessions.isEmpty
              ? _buildErrorState(state, colorScheme)
              : RefreshIndicator(
                  onRefresh: () => ref.read(sessionsProvider.notifier).refresh(),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Sign out all other devices card
                      if (state.otherSessionsCount > 0) ...[
                        _buildRevokeAllCard(state, colorScheme),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Sessions header
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.xs,
                          bottom: AppSpacing.sm,
                        ),
                        child: Text(
                          'YOUR SESSIONS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withAlpha(150),
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Sessions list
                      if (state.sessions.isEmpty)
                        _buildEmptyState(colorScheme)
                      else
                        ...state.sessions.map(
                          (session) => _buildSessionCard(session, state, colorScheme),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState(SessionsState state, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load sessions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              state.error ?? 'An unexpected error occurred.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => ref.read(sessionsProvider.notifier).loadSessions(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.devices_other,
            size: 48,
            color: colorScheme.onSurface.withAlpha(100),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No active sessions found',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevokeAllCard(SessionsState state, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign out other devices',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${state.otherSessionsCount} other active session${state.otherSessionsCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: state.isRevokingAll ? null : _handleRevokeAllOther,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: state.isRevokingAll
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onError,
                    ),
                  )
                : const Text('Sign Out All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    Session session,
    SessionsState state,
    ColorScheme colorScheme,
  ) {
    final isRevoking = state.revokingSessionId == session.id;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: session.isCurrent
            ? colorScheme.primary.withAlpha(20)
            : colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: session.isCurrent
              ? colorScheme.primary.withAlpha(100)
              : colorScheme.outline.withAlpha(50),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: session.isCurrent
                  ? colorScheme.primary.withAlpha(30)
                  : colorScheme.onSurface.withAlpha(20),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              _getDeviceIcon(session),
              size: 24,
              color: session.isCurrent
                  ? colorScheme.primary
                  : colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Session info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (session.isCurrent) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                if (session.ipAddress != null)
                  Text(
                    'IP: ${session.ipAddress}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                Text(
                  'Last active: ${_formatRelativeTime(session.lastActiveAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                Text(
                  'Created: ${_formatDate(session.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),

          // Revoke button (for non-current sessions)
          if (!session.isCurrent) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: isRevoking ? null : () => _handleRevokeSession(session),
              child: isRevoking
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onSurface.withAlpha(150),
                      ),
                    )
                  : const Text('Revoke'),
            ),
          ],
        ],
      ),
    );
  }
}
