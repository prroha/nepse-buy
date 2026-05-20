import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/position_repository.dart';
import '../../providers/position_provider.dart';
import '../../widgets/molecules/app_snackbar.dart';

/// Log a BUY or SELL trade. Renamed conceptually from "purchase" in v0.7;
/// kept the filename + class name to keep route imports stable.
///
/// `prefill` lets callers (e.g., the Signals screen tapping "Trade this")
/// open the sheet with the form already populated.
class LogPurchaseSheet extends ConsumerStatefulWidget {
  const LogPurchaseSheet({super.key, this.prefill});
  final TradePrefill? prefill;

  @override
  ConsumerState<LogPurchaseSheet> createState() => _LogPurchaseSheetState();
}

class TradePrefill {
  const TradePrefill({
    required this.symbol,
    this.side = TradeSide.buy,
    this.grossPricePerShare,
    this.shares,
    this.executedAt,
    this.note,
  });
  final String symbol;
  final TradeSide side;
  final String? grossPricePerShare;
  final int? shares;
  final DateTime? executedAt;
  final String? note;
}

class _LogPurchaseSheetState extends ConsumerState<LogPurchaseSheet> {
  final _symbol = TextEditingController();
  final _shares = TextEditingController();
  final _price = TextEditingController();
  final _note = TextEditingController();
  DateTime _executedAt = DateTime.now();
  TradeSide _side = TradeSide.buy;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _symbol.text = p.symbol;
      _side = p.side;
      if (p.grossPricePerShare != null) _price.text = p.grossPricePerShare!;
      if (p.shares != null) _shares.text = p.shares!.toString();
      if (p.note != null) _note.text = p.note!;
      if (p.executedAt != null) _executedAt = p.executedAt!;
    }
  }

  @override
  void dispose() {
    _symbol.dispose();
    _shares.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _executedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _executedAt = picked);
  }

  Future<void> _save() async {
    final sym = _symbol.text.trim();
    final sh = int.tryParse(_shares.text.trim());
    final price = _price.text.trim();
    if (sym.isEmpty || sh == null || sh <= 0 || price.isEmpty) {
      AppSnackbar.error(context, 'Symbol, shares, and price are required');
      return;
    }
    setState(() => _saving = true);
    final ok = await ref.read(positionsProvider.notifier).logTrade(
          TradeInput(
            symbol: sym,
            side: _side,
            shares: sh,
            grossPricePerShare: price,
            executedAt: _executedAt,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          ),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      AppSnackbar.error(context, 'Save failed — check the symbol and try again');
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log trade', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            // BUY / SELL segmented control
            SegmentedButton<TradeSide>(
              segments: const [
                ButtonSegment(value: TradeSide.buy, label: Text('Buy'), icon: Icon(Icons.add_circle_outline)),
                ButtonSegment(value: TradeSide.sell, label: Text('Sell'), icon: Icon(Icons.remove_circle_outline)),
              ],
              selected: {_side},
              onSelectionChanged: _saving ? null : (s) => setState(() => _side = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _symbol,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Symbol (e.g., NABIL)', border: OutlineInputBorder()),
              enabled: !_saving,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _shares,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Shares', border: OutlineInputBorder()),
                    enabled: !_saving,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _side == TradeSide.buy ? 'Buy price/share (Rs)' : 'Sell price/share (Rs)',
                      border: const OutlineInputBorder(),
                    ),
                    enabled: !_saving,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _saving ? null : _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _side == TradeSide.buy ? 'Bought on' : 'Sold on',
                  border: const OutlineInputBorder(),
                ),
                child: Text('${_executedAt.year}-${_executedAt.month.toString().padLeft(2, '0')}-${_executedAt.day.toString().padLeft(2, '0')}'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
              enabled: !_saving,
            ),
            const SizedBox(height: 8),
            Text(
              'Broker commission, SEBON fee, DP fee, and CGT (for sells) are auto-computed. Adjust in Settings → Fee schedule if your broker offers different rates.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_side == TradeSide.buy ? 'Log buy' : 'Log sell'),
            ),
          ],
        ),
      ),
    );
  }
}
