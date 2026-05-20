import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Variant for different visual styles
enum SettingsItemVariant {
  /// Default style
  normal,

  /// Danger/destructive style (red)
  danger,
}

/// A single settings item row with icon, label, and optional value/action.
/// Can be tappable or static.
class SettingsItem extends StatelessWidget {
  /// Icon to display on the left
  final IconData? icon;

  /// Main label text
  final String label;

  /// Secondary description text
  final String? description;

  /// Value text displayed on the right
  final String? value;

  /// Widget displayed on the right (alternative to value)
  final Widget? trailing;

  /// Callback when the item is tapped
  final VoidCallback? onTap;

  /// Whether the item is disabled
  final bool disabled;

  /// Whether to show a chevron arrow
  final bool showChevron;

  /// Visual variant style
  final SettingsItemVariant variant;

  const SettingsItem({
    super.key,
    this.icon,
    required this.label,
    this.description,
    this.value,
    this.trailing,
    this.onTap,
    this.disabled = false,
    this.showChevron = true,
    this.variant = SettingsItemVariant.normal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isInteractive = onTap != null && !disabled;
    final effectiveOpacity = disabled ? 0.5 : 1.0;

    // Colors based on variant
    Color iconBgColor;
    Color iconColor;
    Color labelColor;

    switch (variant) {
      case SettingsItemVariant.danger:
        iconBgColor = colorScheme.error.withAlpha(25);
        iconColor = colorScheme.error;
        labelColor = colorScheme.error;
        break;
      case SettingsItemVariant.normal:
      default:
        iconBgColor = colorScheme.surfaceContainerHighest;
        iconColor = colorScheme.onSurfaceVariant;
        labelColor = colorScheme.onSurface;
    }

    return Opacity(
      opacity: effectiveOpacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive ? onTap : null,
          child: Padding(
            // Tighter padding: 12h x 10v
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, // 12dp
              vertical: 10,
            ),
            child: Row(
              children: [
                // Icon - tighter size
                if (icon != null) ...[
                  Container(
                    width: 36, // Reduced from 40
                    height: 36, // Reduced from 40
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(8), // Tighter radius
                    ),
                    child: Icon(
                      icon,
                      size: 18, // Reduced from 20
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm), // Tighter gap
                ],

                // Label and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: labelColor,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Value or trailing widget
                if (value != null && trailing == null) ...[
                  const SizedBox(width: AppSpacing.xs), // Tighter gap
                  Text(
                    value!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.xs), // Tighter gap
                  trailing!,
                ],

                // Chevron
                if (showChevron && onTap != null && trailing == null) ...[
                  const SizedBox(width: AppSpacing.xs), // Tighter gap
                  Icon(
                    Icons.chevron_right,
                    size: 18, // Smaller chevron
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
