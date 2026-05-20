import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// A section container for grouping related settings.
/// Provides consistent styling with title, optional description, and card container.
class SettingsSection extends StatelessWidget {
  /// Section title
  final String title;

  /// Optional description below the title
  final String? description;

  /// Section content (list of SettingsItem widgets)
  final List<Widget> children;

  /// Additional padding for the section
  final EdgeInsetsGeometry? padding;

  const SettingsSection({
    super.key,
    required this.title,
    this.description,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header - tighter padding
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md, // Tighter: 12dp
              right: AppSpacing.md,
              bottom: 6, // Tighter gap to content
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith( // Smaller title
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2), // Tighter gap
                  Text(
                    description!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Section content - tighter shadow
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppSpacing.borderRadiusSm, // Tighter radius
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withAlpha(10), // Subtle shadow
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusSm,
              child: Column(
                children: _buildChildrenWithDividers(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Widget> result = [];

    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          Divider(
            height: 1,
            thickness: 0.5, // Thinner divider
            indent: AppSpacing.md, // Tighter indent
            endIndent: AppSpacing.md,
            color: colorScheme.outlineVariant.withAlpha(80),
          ),
        );
      }
    }

    return result;
  }
}
