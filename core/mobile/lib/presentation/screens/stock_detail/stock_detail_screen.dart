import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/corporate_action_repository.dart';
import '../../providers/corporate_action_provider.dart';
import '../../providers/signal_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/atoms/signal_action_chip.dart';
import '../../widgets/charts/price_history_chart.dart';

class StockDetailScreen extends ConsumerWidget {
  final String symbol;
  const StockDetailScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(stockDetailProvider(symbol));
    return Scaffold(
      appBar: AppBar(title: Text(symbol)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(e.toString()))),
        data: (s) {
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(s.name, style: theme.textTheme.titleMedium),
              Text(s.sector ?? '—',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey)),
              const SizedBox(height: AppSpacing.lg),
              _MetricGrid(detail: s),
              const SizedBox(height: AppSpacing.lg),
              PriceHistoryChart(detail: s),
              const SizedBox(height: AppSpacing.lg),
              _CorporateActions(symbol: s.symbol),
              const SizedBox(height: AppSpacing.lg),
              _SignalHistory(stockId: s.id),
            ],
          );
        },
      ),
    );
  }
}

class _CorporateActions extends ConsumerWidget {
  final String symbol;
  const _CorporateActions({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(corporateActionsForSymbolProvider(symbol));
    final theme = Theme.of(context);
    return actions.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Corporate actions', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final a in rows.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _colorFor(a.type),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(a.type.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _summary(a),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (a.recordDate != null)
                      Text(
                        a.recordDate!.substring(0, 10),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Color _colorFor(CorporateActionType t) => switch (t) {
        CorporateActionType.cashDividend => const Color(0xFF15803D),
        CorporateActionType.bonusShare => const Color(0xFF7E22CE),
        CorporateActionType.rightShare => const Color(0xFF1E3A8A),
        CorporateActionType.stockSplit => const Color(0xFF6B7280),
      };

  String _summary(CorporateAction a) {
    final fy = a.fiscalYear != null ? ' · FY ${a.fiscalYear}' : '';
    if (a.type == CorporateActionType.rightShare) {
      return 'Ratio ${a.rightRatio ?? "?"}$fy';
    }
    if (a.pct != null) return '${a.pct}%$fy';
    return fy.isEmpty ? '—' : fy.substring(3);
  }
}

class _MetricGrid extends StatelessWidget {
  final dynamic detail; // StockDetail
  const _MetricGrid({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget tile(String label, String? value) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value ?? '—', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.6,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        tile('Last close', detail.latestClose != null ? 'Rs ${detail.latestClose}' : null),
        tile('Date', detail.latestPriceDate),
        tile('P/E', detail.latestPe),
        tile('P/B', detail.latestPb),
      ],
    );
  }
}

class _SignalHistory extends ConsumerWidget {
  final String stockId;
  const _SignalHistory({required this.stockId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(signalHistoryProvider(stockId));
    final theme = Theme.of(context);
    return history.when(
      loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(e.toString(), style: const TextStyle(color: Colors.red)),
      data: (rows) {
        if (rows.isEmpty) return Text('No signal history yet', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signal history', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final s in rows.take(20))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SignalActionChip(action: s.action),
                    const SizedBox(width: 8),
                    Text(s.signalDate, style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.rationale, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
