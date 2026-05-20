import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/local/signal_history_repository.dart';

/// Persistent log of engine evaluations the user has actually seen.
/// Shows action + date + symbol + whether the user marked it taken.
class SignalHistoryScreen extends ConsumerWidget {
  const SignalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(_recentSignalsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Signal history')),
      body: rows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No signal history yet. Open the Signals tab to record '
                  'today\'s evaluations.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _SignalRow(row: items[i]),
          );
        },
      ),
    );
  }
}

class _SignalRow extends ConsumerWidget {
  const _SignalRow({required this.row});
  final Map<String, Object?> row;

  Color _actionColor(String action, ThemeData theme) {
    switch (action) {
      case 'BUY':
        return Colors.green.shade600;
      case 'HARVEST':
        return Colors.orange.shade700;
      case 'HOLD_FUNDS':
        return Colors.blue.shade600;
      case 'WAIT':
        return theme.hintColor;
      default:
        return theme.hintColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final action = row['action'] as String;
    final symbol = row['symbol'] as String;
    final signalDate = row['signal_date'] as String;
    final season = row['season'] as String;
    final suggested = row['suggested_limit'] as num?;
    final closeAt = row['close_at_signal'] as num?;
    final taken = (row['taken'] as int? ?? 0) == 1;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _actionColor(action, theme).withValues(alpha: 0.15),
        child: Text(
          action.substring(0, 1),
          style: TextStyle(
              color: _actionColor(action, theme),
              fontWeight: FontWeight.bold),
        ),
      ),
      title: Row(
        children: [
          Text(symbol, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(action,
              style: TextStyle(color: _actionColor(action, theme), fontSize: 12)),
          const Spacer(),
          if (taken)
            const Icon(Icons.check_circle, size: 16, color: Colors.green),
        ],
      ),
      subtitle: Text([
        DateFormat.yMMMd().format(DateTime.parse(signalDate)),
        '$season season',
        if (closeAt != null) 'close Rs ${closeAt.toStringAsFixed(2)}',
        if (suggested != null) 'limit Rs ${suggested.toStringAsFixed(2)}',
      ].join(' · ')),
      onTap: taken
          ? null
          : () async {
              final repo =
                  await ref.read(signalHistoryRepositoryProvider.future);
              await repo.markTaken(symbol, signalDate);
              ref.invalidate(_recentSignalsProvider);
            },
    );
  }
}

final _recentSignalsProvider =
    FutureProvider<List<Map<String, Object?>>>((ref) async {
  final repo = await ref.watch(signalHistoryRepositoryProvider.future);
  return repo.recent();
});
