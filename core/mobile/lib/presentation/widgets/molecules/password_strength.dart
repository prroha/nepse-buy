import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Password strength levels.
enum PasswordStrength {
  weak,
  fair,
  good,
  strong;

  /// Get the display label for this strength.
  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  /// Get the progress value (0.0 to 1.0) for this strength.
  double get progress {
    switch (this) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}

/// A password requirement with its validator.
class PasswordRequirement {
  final String label;
  final bool Function(String password, int minLength) validator;

  const PasswordRequirement({
    required this.label,
    required this.validator,
  });
}

/// Default password requirements.
List<PasswordRequirement> getDefaultRequirements(int minLength) => [
      PasswordRequirement(
        label: 'Minimum $minLength characters',
        validator: (password, min) => password.length >= min,
      ),
      PasswordRequirement(
        label: 'Contains uppercase letter',
        validator: (password, _) => RegExp(r'[A-Z]').hasMatch(password),
      ),
      PasswordRequirement(
        label: 'Contains lowercase letter',
        validator: (password, _) => RegExp(r'[a-z]').hasMatch(password),
      ),
      PasswordRequirement(
        label: 'Contains number',
        validator: (password, _) => RegExp(r'[0-9]').hasMatch(password),
      ),
      PasswordRequirement(
        label: 'Contains special character',
        validator: (password, _) =>
            RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]''').hasMatch(password),
      ),
    ];

/// A password strength meter with visual strength bar and requirements checklist.
///
/// This is a molecule-level widget that displays password strength feedback
/// with animated transitions.
///
/// Example:
/// ```dart
/// PasswordStrengthMeter(
///   password: passwordController.text,
///   onStrengthChange: (strength) {
///     print('Password strength: ${strength.label}');
///   },
/// )
/// ```
class PasswordStrengthMeter extends StatefulWidget {
  /// The password to evaluate.
  final String password;

  /// Minimum length requirement (default: 8).
  final int minLength;

  /// Whether to show the requirements checklist (default: true).
  final bool showRequirements;

  /// Callback when strength changes.
  final ValueChanged<PasswordStrength>? onStrengthChange;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.minLength = 8,
    this.showRequirements = true,
    this.onStrengthChange,
  });

  @override
  State<PasswordStrengthMeter> createState() => _PasswordStrengthMeterState();
}

class _PasswordStrengthMeterState extends State<PasswordStrengthMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  PasswordStrength _previousStrength = PasswordStrength.weak;
  late List<PasswordRequirement> _requirements;

  @override
  void initState() {
    super.initState();
    _requirements = getDefaultRequirements(widget.minLength);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _updateStrength();
  }

  @override
  void didUpdateWidget(PasswordStrengthMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password ||
        oldWidget.minLength != widget.minLength) {
      if (oldWidget.minLength != widget.minLength) {
        _requirements = getDefaultRequirements(widget.minLength);
      }
      _updateStrength();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  PasswordStrength _calculateStrength() {
    if (widget.password.isEmpty) return PasswordStrength.weak;

    final passedCount = _requirements
        .where((req) => req.validator(widget.password, widget.minLength))
        .length;

    final ratio = passedCount / _requirements.length;

    if (ratio <= 0.25) return PasswordStrength.weak;
    if (ratio <= 0.5) return PasswordStrength.fair;
    if (ratio <= 0.75) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  void _updateStrength() {
    final newStrength = _calculateStrength();

    if (newStrength != _previousStrength) {
      _progressAnimation = Tween<double>(
        begin: _previousStrength.progress,
        end: newStrength.progress,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _animationController.forward(from: 0);
      _previousStrength = newStrength;
      widget.onStrengthChange?.call(newStrength);
    }
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red.shade500;
      case PasswordStrength.fair:
        return Colors.orange.shade500;
      case PasswordStrength.good:
        return Colors.yellow.shade600;
      case PasswordStrength.strong:
        return Colors.green.shade500;
    }
  }

  Color _getStrengthBackgroundColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red.shade100;
      case PasswordStrength.fair:
        return Colors.orange.shade100;
      case PasswordStrength.good:
        return Colors.yellow.shade100;
      case PasswordStrength.strong:
        return Colors.green.shade100;
    }
  }

  Color _getStrengthTextColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red.shade600;
      case PasswordStrength.fair:
        return Colors.orange.shade600;
      case PasswordStrength.good:
        return Colors.yellow.shade700;
      case PasswordStrength.strong:
        return Colors.green.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strength = _calculateStrength();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password strength',
              style: TextStyle(
                color: colorScheme.outline,
                fontSize: 13,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.password.isNotEmpty
                  ? Text(
                      strength.label,
                      key: ValueKey(strength),
                      style: TextStyle(
                        color: _getStrengthTextColor(strength),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Strength bar
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: widget.password.isNotEmpty
                    ? _getStrengthBackgroundColor(strength)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor:
                    widget.password.isNotEmpty ? _progressAnimation.value : 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _getStrengthColor(strength),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          },
        ),

        // Requirements checklist
        if (widget.showRequirements) ...[
          const SizedBox(height: AppSpacing.md),
          ...List.generate(_requirements.length, (index) {
            final requirement = _requirements[index];
            final passed =
                requirement.validator(widget.password, widget.minLength);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      passed ? Icons.check : Icons.close,
                      key: ValueKey('$index-$passed'),
                      size: 16,
                      color: passed
                          ? Colors.green.shade600
                          : colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color:
                          passed ? Colors.green.shade600 : colorScheme.outline,
                      fontSize: 13,
                    ),
                    child: Text(requirement.label),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
