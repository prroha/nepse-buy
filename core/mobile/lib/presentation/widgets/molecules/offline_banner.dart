import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../data/local/outbox.dart';

/// Thin banner that surfaces (1) offline state and (2) how many writes are
/// still waiting to sync. Lives at the top of [MainShell]'s body. Renders
/// nothing when online with an empty outbox — zero footprint in the happy path.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final pending = ref.watch(outboxCountProvider).valueOrNull ?? 0;
    if (online && pending == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final (bg, text) = !online
        ? (const Color(0xFFF59E0B), 'Offline — showing cached data')
        : (const Color(0xFF6366F1), 'Syncing $pending pending change${pending == 1 ? '' : 's'}…');
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(!online ? Icons.cloud_off : Icons.cloud_sync, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
