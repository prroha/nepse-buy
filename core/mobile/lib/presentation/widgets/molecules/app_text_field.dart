import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Validation mode for the text field.
///
/// - [onSubmit]: Validation only occurs when the form is submitted (default Flutter behavior)
/// - [onBlur]: Validation occurs when the field loses focus, providing immediate feedback
/// - [onChange]: Validation occurs on every change (can be noisy for the user)
enum FieldValidationMode {
  onSubmit,
  onBlur,
  onChange,
}

/// A styled text input field with label, hint, and error support.
///
/// This is a molecule-level widget that combines a label, text input,
/// and error message into a cohesive form field component.
///
/// The [validationMode] parameter controls when validation occurs:
/// - [FieldValidationMode.onBlur] (default): Validates when the field loses focus,
///   providing immediate feedback while the context is fresh in the user's mind.
/// - [FieldValidationMode.onSubmit]: Only validates on form submission.
/// - [FieldValidationMode.onChange]: Validates on every keystroke.
///
/// Example:
/// ```dart
/// AppTextField(
///   controller: emailController,
///   label: 'Email',
///   hint: 'Enter your email',
///   keyboardType: TextInputType.emailAddress,
///   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
///   validationMode: FieldValidationMode.onBlur, // Validates on blur (default)
/// )
/// ```
class AppTextField extends StatefulWidget {
  /// Controller for the text field.
  final TextEditingController? controller;

  /// Optional label displayed above the field.
  final String? label;

  /// Placeholder text displayed when the field is empty.
  final String? hint;

  /// Error text displayed below the field.
  final String? errorText;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// The type of keyboard to display.
  final TextInputType keyboardType;

  /// The action button on the keyboard.
  final TextInputAction textInputAction;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  /// Validator for form validation.
  final FormFieldValidator<String>? validator;

  /// Widget displayed at the start of the field.
  final Widget? prefixIcon;

  /// Widget displayed at the end of the field.
  final Widget? suffixIcon;

  /// Whether the field is enabled.
  final bool enabled;

  /// Maximum number of lines for the field.
  final int maxLines;

  /// Whether to autofocus this field.
  final bool autofocus;

  /// Focus node for controlling focus.
  final FocusNode? focusNode;

  /// Initial value for the field.
  final String? initialValue;

  /// Maximum length of the input.
  final int? maxLength;

  /// Helper text displayed below the field.
  final String? helperText;

  /// Whether to show the character counter below the field.
  final bool showCharacterCount;

  /// When to trigger validation.
  /// Default is [FieldValidationMode.onBlur] for better UX - users get immediate
  /// feedback when they leave a field, while the context of what they entered
  /// is still fresh in their mind.
  final FieldValidationMode validationMode;

  /// Whether to clear validation error when the user starts typing.
  /// Only applies when [validationMode] is [FieldValidationMode.onBlur].
  /// Default is true for better UX - errors clear as user fixes them.
  final bool clearErrorOnChange;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.autofocus = false,
    this.focusNode,
    this.initialValue,
    this.maxLength,
    this.helperText,
    this.showCharacterCount = false,
    this.validationMode = FieldValidationMode.onBlur,
    this.clearErrorOnChange = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  int _charCount = 0;
  late FocusNode _focusNode;
  String? _validationError;
  bool _hasBeenTouched = false;

  @override
  void initState() {
    super.initState();
    // Initialize character count from controller or initial value
    _charCount = widget.controller?.text.length ?? widget.initialValue?.length ?? 0;
    widget.controller?.addListener(_onControllerChanged);

    // Set up focus node for onBlur validation
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
      _charCount = widget.controller?.text.length ?? 0;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (widget.focusNode == null) {
        _focusNode = FocusNode();
      } else {
        _focusNode = widget.focusNode!;
      }
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChange);
    // Only dispose if we created the focus node
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    // Validate on blur when the field loses focus
    if (!_focusNode.hasFocus &&
        widget.validationMode == FieldValidationMode.onBlur &&
        widget.validator != null) {
      _hasBeenTouched = true;
      _runValidation();
    }
  }

  void _runValidation() {
    if (widget.validator == null) return;

    final value = widget.controller?.text ?? widget.initialValue ?? '';
    final error = widget.validator!(value);

    if (error != _validationError) {
      setState(() {
        _validationError = error;
      });
    }
  }

  void _onControllerChanged() {
    final newCount = widget.controller?.text.length ?? 0;
    if (newCount != _charCount) {
      setState(() {
        _charCount = newCount;
      });
    }
  }

  void _handleOnChanged(String value) {
    setState(() {
      _charCount = value.length;
    });
    widget.onChanged?.call(value);

    // Handle validation based on mode
    if (widget.validationMode == FieldValidationMode.onChange) {
      _hasBeenTouched = true;
      _runValidation();
    } else if (widget.validationMode == FieldValidationMode.onBlur &&
        widget.clearErrorOnChange &&
        _hasBeenTouched &&
        _validationError != null) {
      // Clear error as user types (revalidate to see if fixed)
      _runValidation();
    }
  }

  /// Calculate the counter color based on percentage of maxLength used.
  Color _getCounterColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.maxLength == null || widget.maxLength == 0) {
      return colorScheme.outline;
    }
    final percentage = (_charCount / widget.maxLength!) * 100;
    if (percentage >= 100) {
      return colorScheme.error;
    } else if (percentage >= 80) {
      return isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
    }
    return colorScheme.outline;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showCounter = widget.showCharacterCount && widget.maxLength != null;
    // Use external errorText if provided, otherwise use validation error for onBlur/onChange modes
    final displayError = widget.errorText ??
        (widget.validationMode != FieldValidationMode.onSubmit && _hasBeenTouched
            ? _validationError
            : null);

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
          initialValue: widget.initialValue,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: _handleOnChanged,
          onFieldSubmitted: widget.onSubmitted,
          // Keep validator for Form.validate() to work on submit
          validator: widget.validator,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          autofocus: widget.autofocus,
          // Use managed focus node for onBlur validation
          focusNode: _focusNode,
          // Hide the built-in counter since we show our own
          buildCounter: showCounter
              ? (context, {required currentLength, required isFocused, maxLength}) => null
              : null,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 15, // Slightly tighter text
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: colorScheme.outline,
              fontSize: 15,
            ),
            errorText: displayError,
            helperText: widget.helperText,
            helperStyle: TextStyle(
              color: colorScheme.outline,
              fontSize: 11,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: widget.enabled
                ? colorScheme.surface
                : colorScheme.outlineVariant.withAlpha(50),
            // Tighter content padding: 12h x 10v for compact inputs
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, // 12dp
              vertical: 10,
            ),
            isDense: true, // Enable dense mode for tighter layout
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusSm, // Tighter radius
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
        if (showCounter) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: _getCounterColor(context),
                fontSize: 11,
                fontWeight: _charCount >= (widget.maxLength ?? 0) * 0.8
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              child: Text('$_charCount/${widget.maxLength}'),
            ),
          ),
        ],
      ],
    );
  }
}
