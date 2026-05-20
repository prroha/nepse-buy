import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// A search bar with search icon and optional clear button.
///
/// This is a molecule-level widget that combines a text field with
/// search-specific UI elements.
///
/// Example:
/// ```dart
/// AppSearchBar(
///   controller: searchController,
///   onChanged: (value) => performSearch(value),
///   onSubmitted: (value) => submitSearch(value),
/// )
/// ```
class AppSearchBar extends StatefulWidget {
  /// Controller for the search text field.
  final TextEditingController? controller;

  /// Placeholder text.
  final String hint;

  /// Called when the search text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the search.
  final ValueChanged<String>? onSubmitted;

  /// Called when the clear button is pressed.
  final VoidCallback? onClear;

  /// Whether the search bar is enabled.
  final bool enabled;

  /// Whether to autofocus the search bar.
  final bool autofocus;

  /// Focus node for controlling focus.
  final FocusNode? focusNode;

  /// Whether to show the clear button when text is present.
  final bool showClearButton;

  /// Background color of the search bar.
  final Color? backgroundColor;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.showClearButton = true,
    this.backgroundColor,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 15, // Slightly tighter
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: colorScheme.outline,
          fontSize: 15,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: colorScheme.outline,
          size: 20, // Tighter icon
        ),
        suffixIcon: widget.showClearButton && _hasText
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: colorScheme.outline,
                  size: 18, // Smaller clear icon
                ),
                onPressed: _handleClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              )
            : null,
        filled: true,
        fillColor: widget.backgroundColor ?? colorScheme.surface,
        isDense: true,
        // Tighter content padding
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, // 12dp
          vertical: 8,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusFull,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusFull,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusFull,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusFull,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }
}
