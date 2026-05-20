import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/position_repository.dart';
import '../../../data/static/static_data_client.dart';

/// Pie chart of "current portfolio value by sector" — what the user asked
/// for: a quick read on whether they're over-concentrated and should think
/// about rotating. Computes value at the latest close from the static
/// bundle, groups by sector from `stocks.json`.
class SectorAllocationChart extends ConsumerWidget {
  const SectorAllocationChart({super.key, required this.positions});

  final List<Position> positions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (positions.isEmpty) return const SizedBox.shrink();
    final breakdown = ref.watch(_sectorBreakdownProvider(positions));
    return breakdown.when(
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 60,
        child: Center(child: Text('Sector breakdown unavailable: $e')),
      ),
      data: (slices) {
        if (slices.isEmpty) return const SizedBox.shrink();
        final total = slices.fold<double>(0, (a, s) => a + s.value);
        final theme = Theme.of(context);
        final palette = _palette(theme);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sector allocation',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: [
                          for (var i = 0; i < slices.length; i++)
                            PieChartSectionData(
                              value: slices[i].value,
                              color: palette[i % palette.length],
                              title: '${(slices[i].value / total * 100).round()}%',
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              radius: 56,
                            ),
                        ],
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (var i = 0; i < slices.length; i++)
                            _LegendRow(
                              color: palette[i % palette.length],
                              label: slices[i].sector,
                              value: 'Rs ${_compact(slices[i].value)}',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Color> _palette(ThemeData theme) => [
        theme.colorScheme.primary,
        theme.colorScheme.tertiary,
        theme.colorScheme.secondary,
        Colors.orange.shade400,
        Colors.teal.shade400,
        Colors.purple.shade400,
        Colors.pink.shade400,
        Colors.indigo.shade400,
      ];

  String _compact(double n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(2)}cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(2)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toStringAsFixed(0);
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

class _SectorSlice {
  _SectorSlice(this.sector, this.value);
  final String sector;
  double value;
}

final _sectorBreakdownProvider =
    FutureProvider.family<List<_SectorSlice>, List<Position>>((ref, positions) async {
  if (positions.isEmpty) return const [];
  final client = await ref.watch(staticDataClientProvider.future);
  final stocks = await client.getStocks();
  final sectorBySymbol = {
    for (final s in stocks) s.symbol.toUpperCase(): s.sector ?? 'Other'
  };
  final bySector = <String, _SectorSlice>{};
  for (final p in positions) {
    if (p.totalShares <= 0) continue;
    final close = double.tryParse(p.latestClose ?? '');
    if (close == null) continue;
    final value = close * p.totalShares;
    final sector = sectorBySymbol[p.symbol.toUpperCase()] ?? 'Other';
    bySector.putIfAbsent(sector, () => _SectorSlice(sector, 0)).value += value;
  }
  final list = bySector.values.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return list;
});
