import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/stock_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/molecules/app_snackbar.dart';

class AddStockSheet extends ConsumerStatefulWidget {
  const AddStockSheet({super.key});

  @override
  ConsumerState<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends ConsumerState<AddStockSheet> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;
  bool _adding = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _query = v.trim());
    });
  }

  Future<void> _add(String symbol) async {
    setState(() => _adding = true);
    final ok = await ref.read(watchlistProvider.notifier).add(symbol);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'Added $symbol');
      Navigator.pop(context, true);
    } else {
      AppSnackbar.error(context, 'Could not add $symbol — it may already be in your watchlist.');
      setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final search = ref.watch(stockSearchProvider(StockSearchQuery(query: _query)));
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add stock', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search symbol or name (e.g. NABIL)',
                border: OutlineInputBorder(),
              ),
              onChanged: _onChanged,
              enabled: !_adding,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: search.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(e.toString(), style: const TextStyle(color: Colors.red)),
                ),
                data: (page) {
                  if (page.items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No matches.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: page.items.length,
                    itemBuilder: (_, i) {
                      final s = page.items[i];
                      return ListTile(
                        title: Text(s.symbol, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: _adding
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_circle_outline),
                        onTap: _adding ? null : () => _add(s.symbol),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
