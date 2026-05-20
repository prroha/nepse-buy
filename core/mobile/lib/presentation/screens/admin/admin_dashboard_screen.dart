import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../providers/admin_provider.dart';
import '../../router/routes.dart';
import '../../widgets/atoms/app_button.dart';
import '../../widgets/layout/error_state.dart';
import '../../widgets/layout/loading_overlay.dart';

/// Stats Card Widget - uses theme system colors
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Container(
      padding: AppSpacing.cardContentPadding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withAlpha(26),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: effectiveIconColor,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Signups Chart Widget - uses theme system colors
class SignupsChart extends StatelessWidget {
  final List<SignupByDay> data;

  const SignupsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxCount = data.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxCount > 0 ? maxCount : 1;

    return Container(
      padding: AppSpacing.cardContentPadding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Signups (Last 7 Days)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.gapMd,
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((day) {
                final height = (day.count / effectiveMax) * 120;
                final date = DateTime.parse(day.date);
                final dayLabel = _getDayLabel(date.weekday);

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${day.count}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.gapXs,
                      Container(
                        height: height > 4 ? height : 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      AppSpacing.gapXs,
                      Text(
                        dayLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}

/// Admin Dashboard Screen - uses theme system colors
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load stats when screen is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminDashboardProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminDashboardProvider.notifier).loadStats();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        child: state.error != null
            ? ErrorStateWidget(
                message: state.error!,
                onRetry: () {
                  ref.read(adminDashboardProvider.notifier).loadStats();
                },
              )
            : state.stats == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(adminDashboardProvider.notifier)
                          .loadStats();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppSpacing.screenPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            'Overview',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          AppSpacing.gapMd,

                          // Stats Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.3,
                            children: [
                              StatsCard(
                                title: 'Total Users',
                                value: '${state.stats!.totalUsers}',
                                icon: Icons.people,
                              ),
                              StatsCard(
                                title: 'Active Users',
                                value: '${state.stats!.activeUsers}',
                                icon: Icons.check_circle,
                                iconColor: Colors.green,
                              ),
                              StatsCard(
                                title: 'Inactive',
                                value: '${state.stats!.inactiveUsers}',
                                icon: Icons.cancel,
                                iconColor: colorScheme.error,
                              ),
                              StatsCard(
                                title: 'Recent Signups',
                                value: '${state.stats!.recentSignups}',
                                icon: Icons.person_add,
                                iconColor: colorScheme.tertiary,
                              ),
                            ],
                          ),

                          AppSpacing.gapLg,

                          // Chart
                          SignupsChart(data: state.stats!.signupsByDay),

                          AppSpacing.gapLg,

                          // Manage Users Button
                          AppButton(
                            label: 'Manage Users',
                            onPressed: () {
                              context.push(Routes.adminUsers);
                            },
                            variant: AppButtonVariant.primary,
                            isFullWidth: true,
                            icon: Icons.people,
                          ),

                          AppSpacing.gapMd,

                          // Audit Logs Button
                          AppButton(
                            label: 'Audit Logs',
                            onPressed: () {
                              context.push(Routes.adminAuditLogs);
                            },
                            variant: AppButtonVariant.secondary,
                            isFullWidth: true,
                            icon: Icons.history,
                          ),

                          AppSpacing.gapMd,

                          // Back Button
                          AppButton(
                            label: 'Back to Home',
                            onPressed: () {
                              context.go(Routes.home);
                            },
                            variant: AppButtonVariant.outline,
                            isFullWidth: true,
                            icon: Icons.home,
                          ),

                          AppSpacing.gapLg,
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
