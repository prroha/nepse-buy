import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../atoms/skeleton.dart';
import '../molecules/skeleton_card.dart';
import '../molecules/skeleton_list_item.dart';

/// A skeleton for dashboard/home screens.
///
/// Includes app bar, stats cards, and content sections.
///
/// Example:
/// ```dart
/// SkeletonDashboardScreen()
/// ```
class SkeletonDashboardScreen extends StatelessWidget {
  /// Number of stat cards to show.
  final int statsCount;

  /// Whether to show the app bar.
  final bool showAppBar;

  /// Whether to show bottom navigation.
  final bool showBottomNav;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonDashboardScreen({
    super.key,
    this.statsCount = 4,
    this.showAppBar = true,
    this.showBottomNav = true,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.background,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: isDark ? AppColors.black : AppColors.surface,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(12),
                child: SkeletonCircle.sm(shimmer: shimmer),
              ),
              title: SkeletonBox(
                width: 120,
                height: 20,
                shimmer: shimmer,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SkeletonCircle.sm(shimmer: shimmer),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SkeletonCircle.sm(shimmer: shimmer),
                ),
              ],
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            SkeletonBox(height: 28, shimmer: shimmer),
            const SizedBox(height: AppSpacing.xs),
            FractionallySizedBox(
              widthFactor: 0.6,
              child: SkeletonBox(height: 14, shimmer: shimmer),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Stats grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.5,
              ),
              itemCount: statsCount,
              itemBuilder: (context, index) {
                return _SkeletonStatCard(shimmer: shimmer);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Chart section
            _SkeletonChartCard(shimmer: shimmer),
            const SizedBox(height: AppSpacing.lg),

            // Recent activity
            SkeletonBox(width: 120, height: 20, shimmer: shimmer),
            const SizedBox(height: AppSpacing.md),
            SkeletonList(
              itemCount: 3,
              itemVariant: SkeletonListItemVariant.standard,
              shimmer: shimmer,
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? Container(
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? AppColors.black : AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : AppColors.border,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(4, (index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SkeletonBox(
                        width: 24,
                        height: 24,
                        shimmer: shimmer,
                      ),
                      const SizedBox(height: 4),
                      SkeletonBox(
                        width: 40,
                        height: 10,
                        shimmer: shimmer,
                      ),
                    ],
                  );
                }),
              ),
            )
          : null,
    );
  }
}

class _SkeletonStatCard extends StatelessWidget {
  final bool shimmer;

  const _SkeletonStatCard({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 60, height: 12, shimmer: shimmer),
              SkeletonBox(width: 24, height: 24, shimmer: shimmer),
            ],
          ),
          SkeletonBox(width: 80, height: 28, shimmer: shimmer),
          Row(
            children: [
              SkeletonBox(width: 40, height: 12, shimmer: shimmer),
              const SizedBox(width: AppSpacing.xs),
              SkeletonBox(width: 60, height: 10, shimmer: shimmer),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonChartCard extends StatelessWidget {
  final bool shimmer;

  const _SkeletonChartCard({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 100, height: 18, shimmer: shimmer),
              Row(
                children: [
                  SkeletonBox(width: 60, height: 28, shimmer: shimmer),
                  const SizedBox(width: AppSpacing.sm),
                  SkeletonBox(width: 60, height: 28, shimmer: shimmer),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SkeletonImage(
            height: 180,
            shimmer: shimmer,
          ),
        ],
      ),
    );
  }
}

/// A skeleton for profile screens.
///
/// Example:
/// ```dart
/// SkeletonProfileScreen()
/// ```
class SkeletonProfileScreen extends StatelessWidget {
  /// Whether to show cover photo.
  final bool showCover;

  /// Number of info sections.
  final int sectionCount;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonProfileScreen({
    super.key,
    this.showCover = true,
    this.sectionCount = 2,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: showCover ? 200 : 0,
            pinned: true,
            backgroundColor: isDark ? AppColors.black : AppColors.surface,
            flexibleSpace: showCover
                ? FlexibleSpaceBar(
                    background: SkeletonImage(
                      aspectRatio: SkeletonImageAspectRatio.wide,
                      borderRadius: BorderRadius.zero,
                      shimmer: shimmer,
                    ),
                  )
                : null,
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: SkeletonCircle.sm(shimmer: shimmer),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar and name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          top: showCover ? 0 : AppSpacing.md,
                        ),
                        child: showCover
                            ? Transform.translate(
                                offset: const Offset(0, -40),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.black
                                        : AppColors.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: SkeletonCircle(
                                    size: 100,
                                    shimmer: shimmer,
                                  ),
                                ),
                              )
                            : SkeletonCircle(size: 80, shimmer: shimmer),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(height: 24, shimmer: shimmer),
                            const SizedBox(height: AppSpacing.sm),
                            FractionallySizedBox(
                              widthFactor: 0.6,
                              child: SkeletonBox(height: 14, shimmer: shimmer),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (showCover)
                    const SizedBox(height: 0)
                  else
                    const SizedBox(height: AppSpacing.md),

                  // Bio
                  SkeletonText.paragraph(shimmer: shimmer),
                  const SizedBox(height: AppSpacing.md),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SkeletonButton(
                          fullWidth: true,
                          shimmer: shimmer,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: SkeletonButton(
                          fullWidth: true,
                          shimmer: shimmer,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SkeletonBox(width: 48, height: 40, shimmer: shimmer),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(3, (index) {
                      return Column(
                        children: [
                          SkeletonBox(width: 40, height: 24, shimmer: shimmer),
                          const SizedBox(height: AppSpacing.xs),
                          SkeletonBox(width: 60, height: 12, shimmer: shimmer),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Sections
                  ...List.generate(sectionCount, (index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 100, height: 18, shimmer: shimmer),
                        const SizedBox(height: AppSpacing.md),
                        _SkeletonInfoSection(shimmer: shimmer),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonInfoSection extends StatelessWidget {
  final bool shimmer;

  const _SkeletonInfoSection({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : AppColors.border,
        ),
      ),
      child: Column(
        children: List.generate(4, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < 3 ? AppSpacing.md : 0,
            ),
            child: Row(
              children: [
                SkeletonBox(width: 20, height: 20, shimmer: shimmer),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SkeletonBox(height: 14, shimmer: shimmer),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// A skeleton for form screens.
///
/// Example:
/// ```dart
/// SkeletonFormScreen()
/// ```
class SkeletonFormScreen extends StatelessWidget {
  /// Number of form sections.
  final int sectionCount;

  /// Fields per section.
  final int fieldsPerSection;

  /// Whether to show section headers.
  final bool showSectionHeaders;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonFormScreen({
    super.key,
    this.sectionCount = 2,
    this.fieldsPerSection = 3,
    this.showSectionHeaders = true,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.black : AppColors.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: SkeletonBox(width: 24, height: 24, shimmer: shimmer),
        ),
        title: SkeletonBox(width: 100, height: 20, shimmer: shimmer),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SkeletonButton(size: SkeletonButtonSize.sm, shimmer: shimmer),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(sectionCount, (sectionIndex) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSectionHeaders) ...[
                    SkeletonBox(width: 120, height: 18, shimmer: shimmer),
                    const SizedBox(height: AppSpacing.xs),
                    FractionallySizedBox(
                      widthFactor: 0.7,
                      child: SkeletonBox(height: 12, shimmer: shimmer),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  ...List.generate(fieldsPerSection, (fieldIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _SkeletonFormField(shimmer: shimmer),
                    );
                  }),
                  if (sectionIndex < sectionCount - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
              );
            }),

            // Textarea
            _SkeletonFormField(isTextarea: true, shimmer: shimmer),
            const SizedBox(height: AppSpacing.lg),

            // Submit button
            SkeletonButton(fullWidth: true, shimmer: shimmer),
          ],
        ),
      ),
    );
  }
}

class _SkeletonFormField extends StatelessWidget {
  final bool isTextarea;
  final bool shimmer;

  const _SkeletonFormField({
    this.isTextarea = false,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 80, height: 14, shimmer: shimmer),
        const SizedBox(height: AppSpacing.sm),
        SkeletonBox(
          height: isTextarea ? 100 : 48,
          shimmer: shimmer,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ],
    );
  }
}

/// A skeleton for list/feed screens.
///
/// Example:
/// ```dart
/// SkeletonListScreen()
/// ```
class SkeletonListScreen extends StatelessWidget {
  /// Number of items to show.
  final int itemCount;

  /// List item variant.
  final SkeletonListItemVariant itemVariant;

  /// Whether to show search bar.
  final bool showSearchBar;

  /// Whether to show filter chips.
  final bool showFilters;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonListScreen({
    super.key,
    this.itemCount = 5,
    this.itemVariant = SkeletonListItemVariant.standard,
    this.showSearchBar = true,
    this.showFilters = false,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.black : AppColors.surface,
        elevation: 0,
        title: SkeletonBox(width: 120, height: 20, shimmer: shimmer),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SkeletonBox(width: 24, height: 24, shimmer: shimmer),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showSearchBar)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SkeletonBox(
                height: 48,
                borderRadius: AppSpacing.borderRadiusMd,
                shimmer: shimmer,
              ),
            ),
          if (showFilters)
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return SkeletonBox(
                    width: 80,
                    height: 32,
                    borderRadius: AppSpacing.borderRadiusFull,
                    shimmer: shimmer,
                  );
                },
              ),
            ),
          if (showFilters) const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SkeletonList(
              itemCount: itemCount,
              itemVariant: itemVariant,
              shimmer: shimmer,
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton for grid screens (e.g., gallery, products).
///
/// Example:
/// ```dart
/// SkeletonGridScreen()
/// ```
class SkeletonGridScreen extends StatelessWidget {
  /// Number of items to show.
  final int itemCount;

  /// Number of columns.
  final int crossAxisCount;

  /// Aspect ratio of items.
  final double childAspectRatio;

  /// Whether to show search bar.
  final bool showSearchBar;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonGridScreen({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
    this.showSearchBar = false,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.black : AppColors.surface,
        elevation: 0,
        title: SkeletonBox(width: 120, height: 20, shimmer: shimmer),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SkeletonBox(width: 24, height: 24, shimmer: shimmer),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showSearchBar)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SkeletonBox(
                height: 48,
                borderRadius: AppSpacing.borderRadiusMd,
                shimmer: shimmer,
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                return SkeletonProductCard(shimmer: shimmer);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton for settings screens.
///
/// Example:
/// ```dart
/// SkeletonSettingsScreen()
/// ```
class SkeletonSettingsScreen extends StatelessWidget {
  /// Number of setting groups.
  final int groupCount;

  /// Whether to enable shimmer animation.
  final bool shimmer;

  const SkeletonSettingsScreen({
    super.key,
    this.groupCount = 3,
    this.shimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.black : AppColors.surface,
        elevation: 0,
        title: SkeletonBox(width: 100, height: 20, shimmer: shimmer),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2A2A) : AppColors.border,
                ),
              ),
              child: SkeletonAvatar(
                size: SkeletonAvatarSize.lg,
                showText: true,
                shimmer: shimmer,
              ),
            ),

            // Setting groups
            ...List.generate(groupCount, (groupIndex) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: SkeletonBox(width: 80, height: 12, shimmer: shimmer),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : AppColors.surface,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: List.generate(4, (itemIndex) {
                        return Column(
                          children: [
                            SkeletonListItem(
                              variant: SkeletonListItemVariant.simple,
                              showLeading: true,
                              leadingType: SkeletonLeadingType.icon,
                              showTrailing: true,
                              trailingType: itemIndex % 2 == 0
                                  ? SkeletonTrailingType.icon
                                  : SkeletonTrailingType.toggle,
                              shimmer: shimmer,
                            ),
                            if (itemIndex < 3)
                              Divider(
                                height: 1,
                                indent: 56,
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : AppColors.border,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
