import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/signal_repository.dart';
import '../../../data/repositories/watchlist_repository.dart';
import '../../providers/watchlist_provider.dart';
import '../../router/routes.dart';
import '../../widgets/atoms/signal_action_chip.dart';
import '../../widgets/molecules/app_snackbar.dart';
import 'add_stock_sheet.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(watchlistProvider);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => ref.read(watchlistProvider.notifier).refresh(),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Error(message: e.toString()),
            data: (items) {
              if (items.isEmpty) return const _Empty();
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                itemCount: items.length,
                itemBuilder: (_, i) => _WatchlistRow(item: items[i]),
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton.extended(
            heroTag: 'watchlist-add',
            onPressed: () async {
              final added = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AddStockSheet(),
              );
              if (added == true) {
                ref.invalidate(watchlistProvider);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add stock'),
          ),
        ),
      ],
    );
  }
}

class _WatchlistRow extends ConsumerWidget {
  final WatchlistItem item;
  const _WatchlistRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Remove ${item.stock.symbol}?'),
                content: const Text('You can add it back any time from the search.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Remove', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) async {
        final ok = await ref.read(watchlistProvider.notifier).remove(item.id);
        if (!context.mounted) return;
        if (ok) {
          AppSnackbar.info(context, 'Removed ${item.stock.symbol}');
        } else {
          AppSnackbar.error(context, 'Failed to remove ${item.stock.symbol}');
        }
      },
      child: InkWell(
        onTap: () => context.push(Routes.stockDetail(item.stock.symbol)),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.stock.symbol, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        if (item.latestSignal != null) SignalActionChip(action: signalActionFrom(item.latestSignal!.action)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.stock.name, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.stock.latestClose != null ? 'Rs ${item.stock.latestClose}' : '—',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  if (item.stock.latestPe != null)
                    Text('P/E ${item.stock.latestPe} · P/B ${item.stock.latestPb ?? "-"}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(child: Icon(Icons.bookmark_border, size: 56, color: Colors.grey)),
        SizedBox(height: 12),
        Center(child: Text('Your watchlist is empty — tap "Add stock" to start.')),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  const _Error({required this.message});
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        const Center(child: Icon(Icons.error_outline, size: 56, color: Colors.redAccent)),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Center(child: Text(message, textAlign: TextAlign.center))),
      ],
    );
  }
}
