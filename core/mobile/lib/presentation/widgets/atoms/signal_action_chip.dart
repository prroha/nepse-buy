import 'package:flutter/material.dart';
import '../../../data/repositories/signal_repository.dart';

/// Small color-coded chip showing a signal action (BUY / WAIT / SKIP).
class SignalActionChip extends StatelessWidget {
  final SignalAction action;
  const SignalActionChip({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (action) {
      SignalAction.buy => (const Color(0xFF15803D), Colors.white),
      SignalAction.wait => (const Color(0xFFA16207), Colors.white),
      SignalAction.skip => (const Color(0xFF6B7280), Colors.white),
      SignalAction.holdFunds => (const Color(0xFF1E3A8A), Colors.white),
      SignalAction.harvest => (const Color(0xFF7E22CE), Colors.white),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        action.label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
