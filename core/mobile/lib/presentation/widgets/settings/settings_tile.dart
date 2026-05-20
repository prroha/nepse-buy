import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// A settings tile with a switch toggle.
class SettingsTile extends StatelessWidget {
  /// Icon to display on the left
  final IconData? icon;

  /// Main label text
  final String label;

  /// Secondary description text
  final String? description;

  /// Current toggle value
  final bool value;

  /// Callback when the toggle changes
  final ValueChanged<bool>? onChanged;

  /// Whether the tile is disabled
  final bool disabled;

  const SettingsTile({
    super.key,
    this.icon,
    required this.label,
    this.description,
    required this.value,
    this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveOpacity = disabled ? 0.5 : 1.0;

    return Opacity(
      opacity: effectiveOpacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : () => onChanged?.call(!value),
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
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8), // Tighter radius
                    ),
                    child: Icon(
                      icon,
                      size: 18, // Reduced from 20
                      color: colorScheme.onSurfaceVariant,
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 1), // Tighter gap
                        Text(
                          description!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Switch
                const SizedBox(width: AppSpacing.xs), // Tighter gap
                Switch(
                  value: value,
                  onChanged: disabled ? null : onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
