import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import 'password_strength.dart';

/// A password text field with show/hide toggle functionality.
///
/// This is a molecule-level widget that combines a text field with
/// password-specific UI elements like visibility toggle.
///
/// Example:
/// ```dart
/// PasswordField(
///   controller: passwordController,
///   label: 'Password',
///   hint: 'Enter your password',
///   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
/// )
/// ```
///
/// With strength meter:
/// ```dart
/// PasswordField(
///   controller: passwordController,
///   label: 'Password',
///   showStrength: true,
///   onStrengthChange: (strength) {
///     print('Password strength: ${strength.label}');
///   },
/// )
/// ```
class PasswordField extends StatefulWidget {
  /// Controller for the password field.
  final TextEditingController? controller;

  /// Optional label displayed above the field.
  final String? label;

  /// Placeholder text.
  final String? hint;

  /// Error text displayed below the field.
  final String? errorText;

  /// The action button on the keyboard.
  final TextInputAction textInputAction;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  /// Validator for form validation.
  final FormFieldValidator<String>? validator;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether to autofocus this field.
  final bool autofocus;

  /// Focus node for controlling focus.
  final FocusNode? focusNode;

  /// Optional prefix icon.
  final IconData? prefixIcon;

  /// Helper text displayed below the field.
  final String? helperText;

  /// Whether to show the password strength meter.
  final bool showStrength;

  /// Minimum length for password strength evaluation (default: 8).
  final int strengthMinLength;

  /// Whether to show the requirements checklist (default: true).
  final bool showStrengthRequirements;

  /// Callback when password strength changes.
  final ValueChanged<PasswordStrength>? onStrengthChange;

  const PasswordField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.prefixIcon = Icons.lock_outline,
    this.helperText,
    this.showStrength = false,
    this.strengthMinLength = 8,
    this.showStrengthRequirements = true,
    this.onStrengthChange,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;
  String _currentPassword = '';

  @override
  void initState() {
    super.initState();
    _currentPassword = widget.controller?.text ?? '';
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(PasswordField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
      _currentPassword = widget.controller?.text ?? '';
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        _currentPassword = widget.controller?.text ?? '';
      });
    }
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _handleChanged(String value) {
    setState(() {
      _currentPassword = value;
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 13, // Tighter label
            ),
          ),
          const SizedBox(height: 4), // Tighter label-to-field spacing
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: widget.textInputAction,
          onChanged: _handleChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 15, // Tighter text
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: colorScheme.outline,
              fontSize: 15,
            ),
            errorText: widget.errorText,
            helperText: widget.showStrength ? null : widget.helperText,
            helperStyle: TextStyle(
              color: colorScheme.outline,
              fontSize: 11,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20)
                : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: colorScheme.outline,
                size: 20,
              ),
              onPressed: _toggleVisibility,
            ),
            filled: true,
            fillColor: widget.enabled
                ? colorScheme.surface
                : colorScheme.outlineVariant.withAlpha(50),
            // Tighter content padding: 12h x 10v
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, // 12dp
              vertical: 10,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: colorScheme.error, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm,
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
        ),
        if (widget.showStrength) ...[
          const SizedBox(height: AppSpacing.md),
          PasswordStrengthMeter(
            password: _currentPassword,
            minLength: widget.strengthMinLength,
            showRequirements: widget.showStrengthRequirements,
            onStrengthChange: widget.onStrengthChange,
          ),
        ],
      ],
    );
  }
}
