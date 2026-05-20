import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import 'app_button.dart';

/// Confirmation mode for the button.
enum ConfirmMode {
  /// First tap shows "Are you sure?", second tap within 3 seconds confirms.
  doubleTap,

  /// Opens a confirmation dialog before executing.
  dialog,
}

/// A button that requires confirmation before executing destructive actions.
///
/// Two confirmation patterns are available:
/// - [ConfirmMode.doubleTap]: First tap shows "Are you sure?", second tap within 3 seconds confirms
/// - [ConfirmMode.dialog]: Opens a confirmation dialog before executing
///
/// Example:
/// ```dart
/// // Double-tap pattern (default)
/// ConfirmButton(
///   label: 'Delete',
///   variant: AppButtonVariant.primary,
///   onConfirm: () => deleteItem(),
/// )
///
/// // Dialog pattern
/// ConfirmButton(
///   label: 'Delete',
///   confirmMode: ConfirmMode.dialog,
///   confirmTitle: 'Delete Item',
///   confirmMessage: 'Are you sure you want to delete this item?',
///   variant: AppButtonVariant.primary,
///   onConfirm: () => deleteItem(),
/// )
/// ```
class ConfirmButton extends StatefulWidget {
  /// The text label displayed on the button.
  final String label;

  /// Called when the action is confirmed.
  final VoidCallback onConfirm;

  /// Confirmation pattern to use.
  final ConfirmMode confirmMode;

  /// Title for dialog mode.
  final String confirmTitle;

  /// Message for dialog mode.
  final String confirmMessage;

  /// Label for confirm button.
  final String confirmLabel;

  /// Label for cancel button in dialog mode.
  final String cancelLabel;

  /// The visual variant of the button.
  final AppButtonVariant variant;

  /// The size of the button.
  final AppButtonSize size;

  /// Whether the button is disabled.
  final bool isDisabled;

  /// Whether the button should take the full width of its parent.
  final bool isFullWidth;

  /// An optional icon to display before the label.
  final IconData? icon;

  /// Whether to trigger haptic feedback on first tap.
  final bool enableHaptics;

  const ConfirmButton({
    super.key,
    required this.label,
    required this.onConfirm,
    this.confirmMode = ConfirmMode.doubleTap,
    this.confirmTitle = 'Confirm Action',
    this.confirmMessage = 'Are you sure you want to proceed?',
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isDisabled = false,
    this.isFullWidth = false,
    this.icon,
    this.enableHaptics = true,
  });

  @override
  State<ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<ConfirmButton> {
  static const _resetDuration = Duration(seconds: 3);

  bool _isWaitingConfirm = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _startResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = Timer(_resetDuration, () {
      if (mounted) {
        setState(() {
          _isWaitingConfirm = false;
        });
      }
    });
  }

  void _handleTap() {
    if (widget.isDisabled) return;

    if (widget.confirmMode == ConfirmMode.dialog) {
      _showConfirmDialog();
      return;
    }

    // Double-tap mode
    if (_isWaitingConfirm) {
      // Second tap - confirm action
      _resetTimer?.cancel();
      setState(() {
        _isWaitingConfirm = false;
      });
      widget.onConfirm();
    } else {
      // First tap - show confirmation state
      if (widget.enableHaptics) {
        HapticFeedback.mediumImpact();
      }
      setState(() {
        _isWaitingConfirm = true;
      });
      _startResetTimer();
    }
  }

  Future<void> _showConfirmDialog() async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.confirmTitle),
        content: Text(widget.confirmMessage),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(widget.confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    // When waiting for confirmation, show destructive style
    final effectiveVariant = _isWaitingConfirm
        ? AppButtonVariant.primary
        : widget.variant;

    final effectiveLabel = _isWaitingConfirm ? 'Are you sure?' : widget.label;

    final button = _buildButton(effectiveVariant, effectiveLabel);

    if (widget.isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _buildButton(AppButtonVariant variant, String label) {
    // For confirmation state, override with destructive colors
    if (_isWaitingConfirm) {
      return _buildDestructiveButton(label);
    }

    // Use normal AppButton styling
    return AppButton(
      label: label,
      onPressed: widget.isDisabled ? null : _handleTap,
      variant: variant,
      size: widget.size,
      icon: widget.icon,
    );
  }

  Widget _buildDestructiveButton(String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final padding = AppButtonSizing.getPadding(widget.size);
    final fontSize = AppButtonSizing.getFontSize(widget.size);
    final iconSize = AppButtonSizing.getIconSize(widget.size);

    return ElevatedButton(
      onPressed: widget.isDisabled ? null : _handleTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
        padding: padding,
        textStyle: TextStyle(fontSize: fontSize),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: iconSize),
            AppSpacing.gapHXs,
          ],
          Text(label),
        ],
      ),
    );
  }
}
