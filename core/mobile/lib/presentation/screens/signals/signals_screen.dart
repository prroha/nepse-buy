import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/local/user_data_repository.dart';
import '../../../data/repositories/position_repository.dart';
import '../../../data/repositories/signal_repository.dart';
import '../../../domain/engine/fee_engine.dart';
import '../../providers/signal_provider.dart';
import '../../router/routes.dart';
import '../../widgets/atoms/signal_action_chip.dart';
import '../../widgets/molecules/data_freshness_banner.dart';
import '../portfolio/log_purchase_sheet.dart';

/// "Today" tab — daily DCA signals for the user's watchlist.
class SignalsScreen extends ConsumerWidget {
  const SignalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todaySignalsProvider);

    return Column(
      children: [
        const DataFreshnessBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(todaySignalsProvider.notifier).refresh(),
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(message: e.toString()),
              data: (signals) {
                if (signals.isEmpty) return const _EmptyState();
                final grouped = _groupByAction(signals);
                return ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  children: [
                    _Header(),
                    for (final entry in grouped.entries) ...[
                      _SectionLabel(
                          action: entry.key, count: entry.value.length),
                      for (final s in entry.value) _SignalCard(signal: s),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

Map<SignalAction, List<Signal>> _groupByAction(List<Signal> all) {
  final out = <SignalAction, List<Signal>>{};
  // Order: BUY (actionable) → HOLD_FUNDS (strong-season OD sweep) → WAIT → SKIP.
  for (final action in [SignalAction.buy, SignalAction.holdFunds, SignalAction.wait, SignalAction.skip]) {
    final rows = all.where((s) => s.action == action).toList();
    if (rows.isNotEmpty) out[action] = rows;
  }
  return out;
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's signals", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(date, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final SignalAction action;
  final int count;
  const _SectionLabel({required this.action, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          SignalActionChip(action: action),
          const SizedBox(width: 8),
          Text('$count', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Settings key for the user's per-buy DCA size. Strategy doc default is
/// Rs 25,000 (1 lakh ÷ 4 weekly buys); the user can override via Settings
/// once that screen surfaces this.
const String _kSettingsDcaWeeklyNpr = 'dca_weekly_npr';
const double _defaultDcaWeeklyNpr = 25000;

class _SignalCard extends ConsumerWidget {
  final Signal signal;
  const _SignalCard({required this.signal});

  /// "84 shares for Rs 25k + Rs 232 fees" — helps the user act on a BUY
  /// signal without doing math on a calculator.
  String? _sizingLine(double deployNpr) {
    if (signal.action != SignalAction.buy) return null;
    final limit = double.tryParse(signal.suggestedLimit ?? '');
    if (limit == null || limit <= 0) return null;
    final shares = (deployNpr / limit).floor();
    if (shares <= 0) return null;
    final fees = computeBuyFees(shares, limit, defaultFeeSchedule);
    final totalCost = shares * limit + fees.totalFees;
    return 'For Rs ${deployNpr.toInt()} → $shares shares, '
        'fees Rs ${fees.totalFees.toStringAsFixed(0)}, '
        'total Rs ${totalCost.toStringAsFixed(0)}.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deployNpr = ref.watch(_dcaWeeklyNprProvider).maybeWhen(
          data: (v) => v,
          orElse: () => _defaultDcaWeeklyNpr,
        );
    final theme = Theme.of(context);
    final actionable = signal.action == SignalAction.buy ||
        signal.action == SignalAction.harvest;
    final sizing = _sizingLine(deployNpr);
    return InkWell(
      onTap: () => context.push(Routes.stockDetail(signal.stockSymbol)),
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 4),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(signal.stockSymbol,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(signal.stockName,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (signal.suggestedLimit != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Limit',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey)),
                      Text('Rs ${signal.suggestedLimit}',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(signal.rationale, style: theme.textTheme.bodySmall),
            if (sizing != null) ...[
              const SizedBox(height: 6),
              Text(sizing,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.primary)),
            ],
            if (actionable) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  icon: Icon(
                      signal.action == SignalAction.buy
                          ? Icons.shopping_cart_checkout
                          : Icons.outbond_outlined,
                      size: 18),
                  label: Text(signal.action == SignalAction.buy
                      ? 'Log buy'
                      : 'Log sell'),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => LogPurchaseSheet(
                      prefill: TradePrefill(
                        symbol: signal.stockSymbol,
                        side: signal.action == SignalAction.harvest
                            ? TradeSide.sell
                            : TradeSide.buy,
                        grossPricePerShare: signal.suggestedLimit,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(child: Icon(Icons.inbox_outlined, size: 56, color: Colors.grey)),
        SizedBox(height: 12),
        Center(child: Text('No signals yet — your daily signals will appear here after the next scrape.')),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
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

final _dcaWeeklyNprProvider = FutureProvider<double>((ref) async {
  final repo = await ref.watch(userDataRepositoryProvider.future);
  final raw = (await repo.getAllSettings())[_kSettingsDcaWeeklyNpr];
  return double.tryParse(raw ?? "") ?? _defaultDcaWeeklyNpr;
});
