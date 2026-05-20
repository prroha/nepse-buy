import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/static/static_data_client.dart';

/// Banner that surfaces how stale the cached JSON bundle is. Drops into
/// any screen via `const DataFreshnessBanner()` — silently renders nothing
/// while the manifest is loading or when the bundle is fresh (<= warnAfter).
///
/// The "Refresh" button calls `StaticDataClient.refreshAll()`. To regenerate
/// the bundle itself (re-scrape), the user still has to trigger the GHA
/// workflow — we surface that with a small hint in the snackbar.
class DataFreshnessBanner extends ConsumerStatefulWidget {
  const DataFreshnessBanner({
    super.key,
    this.warnAfter = const Duration(days: 7),
    this.criticalAfter = const Duration(days: 21),
  });

  final Duration warnAfter;
  final Duration criticalAfter;

  @override
  ConsumerState<DataFreshnessBanner> createState() =>
      _DataFreshnessBannerState();
}

class _DataFreshnessBannerState extends ConsumerState<DataFreshnessBanner> {
  bool _refreshing = false;
  DateTime? _exportedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = await ref.read(staticDataClientProvider.future);
      final manifest = await client.getManifest();
      if (!mounted) return;
      setState(() => _exportedAt = manifest.exportedAt);
    } catch (_) {
      // No manifest yet — nothing to show.
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final client = await ref.read(staticDataClientProvider.future);
      final manifest = await client.refreshAll();
      if (!mounted) return;
      setState(() => _exportedAt = manifest.exportedAt);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Refreshed from GitHub. To re-scrape upstream, run the '
            '"Refresh static data" workflow in GitHub Actions.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportedAt = _exportedAt;
    if (exportedAt == null) return const SizedBox.shrink();
    final age = DateTime.now().difference(exportedAt);
    if (age < widget.warnAfter) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final critical = age >= widget.criticalAfter;
    final bg = critical
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.tertiaryContainer;
    final fg = critical
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onTertiaryContainer;

    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(critical ? Icons.warning_amber : Icons.update,
                color: fg, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Static data is ${_humanAge(age)} old — values may be stale.',
                style: theme.textTheme.bodySmall?.copyWith(color: fg),
              ),
            ),
            TextButton(
              onPressed: _refreshing ? null : _refresh,
              style: TextButton.styleFrom(foregroundColor: fg),
              child: _refreshing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  String _humanAge(Duration d) {
    if (d.inDays > 1) return '${d.inDays} days';
    if (d.inDays == 1) return '1 day';
    if (d.inHours > 1) return '${d.inHours} hours';
    return 'less than an hour';
  }
}
