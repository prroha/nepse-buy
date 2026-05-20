import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/local/broker_inbox_repository.dart';
import '../../../data/repositories/position_repository.dart';
import '../../providers/position_provider.dart';
import '../../router/routes.dart';
import '../../widgets/charts/sector_allocation_chart.dart';
import '../../widgets/molecules/app_snackbar.dart';
import 'log_purchase_sheet.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(positionsProvider);
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => ref.read(positionsProvider.notifier).refresh(),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListView(children: [const SizedBox(height: 80), Center(child: Text(e.toString()))]),
            data: (positions) {
              if (positions.isEmpty) return const _Empty();
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _PortfolioHeader(positions: positions)),
                  const SliverToBoxAdapter(child: _BrokerInboxStrip()),
                  SliverToBoxAdapter(
                    child: SectorAllocationChart(positions: positions),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _PositionRow(position: positions[i]),
                      childCount: positions.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton.extended(
            heroTag: 'portfolio-log',
            onPressed: () async {
              final saved = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const LogPurchaseSheet(),
              );
              if (saved == true) ref.invalidate(positionsProvider);
            },
            icon: const Icon(Icons.add),
            label: const Text('Log purchase'),
          ),
        ),
      ],
    );
  }
}

class _PortfolioHeader extends StatelessWidget {
  final List<Position> positions;
  const _PortfolioHeader({required this.positions});

  @override
  Widget build(BuildContext context) {
    double invested = 0;
    double current = 0;
    double realized = 0;
    for (final p in positions) {
      realized += double.tryParse(p.realizedPnl) ?? 0;
      if (!p.isOpen) continue;
      final cost = double.tryParse(p.avgNetCost) ?? 0;
      final close = double.tryParse(p.latestClose ?? '') ?? cost;
      invested += cost * p.totalShares;
      current += close * p.totalShares;
    }
    final pl = current - invested;
    final plPct = invested > 0 ? (pl / invested) : 0;
    final theme = Theme.of(context);
    final plColor = pl >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    final realizedColor = realized >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Portfolio value', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 2),
          Text('Rs ${current.toStringAsFixed(2)}', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${pl >= 0 ? '+' : ''}Rs ${pl.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(color: plColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text('(${(plPct * 100).toStringAsFixed(2)}%)', style: theme.textTheme.bodyMedium?.copyWith(color: plColor)),
              const Spacer(),
              Text('Cost Rs ${invested.toStringAsFixed(2)}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
          if (realized != 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Realized', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                const SizedBox(width: 8),
                Text(
                  '${realized >= 0 ? '+' : ''}Rs ${realized.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: realizedColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PositionRow extends ConsumerWidget {
  final Position position;
  const _PositionRow({required this.position});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plPct = double.tryParse(position.paperPlPct ?? '');
    final plColor = plPct == null
        ? Colors.grey
        : (plPct >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C));
    final harvestEligible = plPct != null && plPct >= 0.30;

    return Dismissible(
      key: ValueKey(position.id),
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
                title: Text('Delete position "${position.symbol}"?'),
                content: const Text('This removes the position and all logged purchases.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: theme.colorScheme.error))),
                ],
              ),
            ) ?? false;
      },
      onDismissed: (_) async {
        final ok = await ref.read(positionsProvider.notifier).remove(position.id);
        if (!context.mounted) return;
        AppSnackbar.info(context, ok ? 'Deleted ${position.symbol}' : 'Delete failed');
      },
      child: InkWell(
        onTap: () => context.push(Routes.stockDetail(position.symbol)),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(position.symbol, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        if (harvestEligible)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF7E22CE), borderRadius: BorderRadius.circular(10)),
                            child: const Text('HARVEST', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    Text('${position.totalShares} sh @ net Rs ${position.avgNetCost}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(position.latestClose != null ? 'Rs ${position.latestClose}' : '—', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  if (plPct != null)
                    Text(
                      '${plPct >= 0 ? '+' : ''}${(plPct * 100).toStringAsFixed(2)}%',
                      style: theme.textTheme.bodySmall?.copyWith(color: plColor, fontWeight: FontWeight.w600),
                    ),
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
        Center(child: Icon(Icons.account_balance_wallet_outlined, size: 56, color: Colors.grey)),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Text(
              'No positions logged yet.\nTap "Log purchase" after you execute a buy on your broker TMS to enable harvest signals.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// Visible only when there are pending broker SMS messages parsed in the
/// inbox. Taps through to the approval queue.
class _BrokerInboxStrip extends ConsumerWidget {
  const _BrokerInboxStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_pendingBrokerCountProvider);
    return count.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (n) {
        if (n == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
          child: Material(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => context.push(Routes.brokerInbox),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_unread_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$n broker message${n == 1 ? '' : 's'} waiting to be reviewed',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final _pendingBrokerCountProvider = FutureProvider<int>((ref) async {
  final inbox = await ref.watch(brokerInboxRepositoryProvider.future);
  return inbox.pendingCount();
});
