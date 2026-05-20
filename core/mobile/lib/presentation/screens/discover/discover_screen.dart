import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/screener_repository.dart';
import '../../providers/screener_provider.dart';
import '../../router/routes.dart';

/// Discover top stocks ranked by dividend, growth, or safety.
/// Public — anonymous users see this immediately on first launch.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  static const _types = [ScreenerType.dividend, ScreenerType.growth, ScreenerType.safety];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _types.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabs,
            tabs: [for (final t in _types) Tab(text: t.label)],
            isScrollable: false,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [for (final t in _types) _ScreenerList(type: t)],
          ),
        ),
      ],
    );
  }
}

class _ScreenerList extends ConsumerWidget {
  final ScreenerType type;
  const _ScreenerList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(screenerProvider(type));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(screenerProvider(type)),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [const SizedBox(height: 80), Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(e.toString())))],
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text(
                  'No ranked stocks yet — data fills in after the first full scrape.',
                  textAlign: TextAlign.center,
                ))),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: rows.length,
            itemBuilder: (_, i) => _ScreenerCard(type: type, rank: i + 1, row: rows[i]),
          );
        },
      ),
    );
  }
}

class _ScreenerCard extends StatelessWidget {
  final ScreenerType type;
  final int rank;
  final ScreenerRow row;
  const _ScreenerCard({required this.type, required this.rank, required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push(Routes.stockDetail(row.symbol)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text('#$rank', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.symbol, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(row.name, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (row.sector != null && row.sector!.isNotEmpty)
                    Text(row.sector!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  _MetricsRow(type: type, metrics: row.metrics, score: row.score),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(row.latestClose != null ? 'Rs ${row.latestClose}' : '—', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final ScreenerType type;
  final ScreenerMetrics metrics;
  final String score;
  const _MetricsRow({required this.type, required this.metrics, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];
    void add(String label) {
      chips.add(Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
      ));
    }

    switch (type) {
      case ScreenerType.dividend:
        if (metrics.dividendYieldPct != null) add('Yield ${metrics.dividendYieldPct}%');
        if (metrics.pe != null) add('P/E ${metrics.pe}');
        break;
      case ScreenerType.growth:
        if (metrics.epsTtmYoyPct != null) add('EPS YoY ${metrics.epsTtmYoyPct}%');
        if (metrics.roeTtm != null) add('ROE ${metrics.roeTtm}%');
        break;
      case ScreenerType.safety:
        if (metrics.marketCap != null) add('MCap ${_compactCap(metrics.marketCap!)}');
        if (metrics.roeTtm != null) add('ROE ${metrics.roeTtm}%');
        if (metrics.pe != null) add('P/E ${metrics.pe}');
        break;
    }
    return Wrap(children: chips);
  }

  String _compactCap(String raw) {
    final v = double.tryParse(raw) ?? 0;
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(1)}Cr';
    if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(1)}L';
    return v.toStringAsFixed(0);
  }
}
