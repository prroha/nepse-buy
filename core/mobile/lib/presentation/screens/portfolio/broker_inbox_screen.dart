import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/local/broker_inbox_repository.dart';
import '../../../data/repositories/position_repository.dart';
import '../../../domain/broker_sms/sms_scanner_service.dart';
import '../../../domain/engine/fee_engine.dart';
import '../../providers/position_provider.dart';
import 'log_purchase_sheet.dart';

/// "Portfolio → Broker messages" — queue of SMS confirmations parsed off
/// the device. User can approve into a trade (which opens the trade sheet
/// pre-filled) or dismiss as not-a-trade.
class BrokerInboxScreen extends ConsumerStatefulWidget {
  const BrokerInboxScreen({super.key});

  @override
  ConsumerState<BrokerInboxScreen> createState() => _BrokerInboxScreenState();
}

class _BrokerInboxScreenState extends ConsumerState<BrokerInboxScreen> {
  bool _scanning = false;
  String? _scanError;

  /// Tries to scan the device inbox. Builds without the SMS plugin
  /// surface this via `SmsScanningDisabled` — we catch it and render
  /// the disabled-state copy.
  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _scanError = null;
    });
    try {
      final scanner = await ref.read(smsScannerServiceProvider.future);
      final queued = await scanner.scan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(queued == 0
              ? 'No new broker messages found.'
              : 'Found $queued new broker message${queued == 1 ? '' : 's'}.'),
        ),
      );
      ref.invalidate(_pendingMessagesProvider);
    } on SmsScanningDisabled catch (e) {
      if (!mounted) return;
      setState(() => _scanError = e.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanError = 'Scan failed: $e');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _approve(PendingBrokerMessage msg) async {
    final prefill = TradePrefill(
      symbol: msg.parsedSymbol ?? '',
      side: msg.parsedSide == 'SELL' ? TradeSide.sell : TradeSide.buy,
      grossPricePerShare: msg.parsedGrossPrice?.toStringAsFixed(2),
      shares: msg.parsedShares,
      executedAt: msg.parsedExecutedAt,
      note: 'From SMS: ${msg.sender}',
    );
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogPurchaseSheet(prefill: prefill),
    );
    if (saved == true) {
      final inbox = await ref.read(brokerInboxRepositoryProvider.future);
      await inbox.markApplied(msg.id, tradeId: msg.parsedSymbol ?? msg.id);
      ref.invalidate(_pendingMessagesProvider);
      ref.read(positionsProvider.notifier).refresh();
    }
  }

  Future<void> _dismiss(PendingBrokerMessage msg) async {
    final inbox = await ref.read(brokerInboxRepositoryProvider.future);
    await inbox.dismiss(msg.id, reason: 'User dismissed');
    ref.invalidate(_pendingMessagesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(_pendingMessagesProvider);
    final scannerAsync = ref.watch(smsScannerServiceProvider);
    final scanAvailable = scannerAsync.maybeWhen(
      data: (s) => s.isAvailable,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Broker messages'),
        actions: [
          if (scanAvailable)
            IconButton(
              tooltip: 'Scan SMS inbox',
              icon: _scanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
              onPressed: _scanning ? null : _scan,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_scanError != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Text(_scanError!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
          Expanded(
            child: pending.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        scanAvailable
                            ? 'No pending broker messages. Tap the sync '
                                'button to scan your SMS inbox.'
                            : 'No pending broker messages. Auto-scan from '
                                'SMS is disabled in this build — log trades '
                                'manually from Portfolio → Log purchase.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      _MessageCard(items[i], onApprove: _approve, onDismiss: _dismiss),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard(this.msg,
      {required this.onApprove, required this.onDismiss});
  final PendingBrokerMessage msg;
  final Future<void> Function(PendingBrokerMessage) onApprove;
  final Future<void> Function(PendingBrokerMessage) onDismiss;

  String _summary() {
    final b = StringBuffer();
    if (msg.parsedSide != null) b.write('${msg.parsedSide} ');
    if (msg.parsedShares != null) b.write('${msg.parsedShares} ');
    if (msg.parsedSymbol != null) b.write('${msg.parsedSymbol} ');
    if (msg.parsedGrossPrice != null) {
      b.write('@ Rs ${msg.parsedGrossPrice!.toStringAsFixed(2)}');
    }
    return b.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaryStr = _summary();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmsHeaderRow(sender: msg.sender, receivedAt: msg.receivedAt),
          const SizedBox(height: 8),
          if (summaryStr.isNotEmpty)
            Text(summaryStr,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          _FeeCrossCheck(msg: msg),
          const SizedBox(height: 6),
          _OriginalMessageTile(body: msg.body),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => onDismiss(msg),
                  child: const Text('Not a trade')),
              const SizedBox(width: 8),
              FilledButton.tonal(
                  onPressed: () => onApprove(msg),
                  child: const Text('Approve & log')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmsHeaderRow extends StatelessWidget {
  const _SmsHeaderRow({required this.sender, required this.receivedAt});
  final String sender;
  final DateTime receivedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.message_outlined, size: 16, color: theme.hintColor),
        const SizedBox(width: 6),
        Text(sender,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.hintColor)),
        const Spacer(),
        Text(DateFormat('MMM d, h:mm a').format(receivedAt),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.hintColor)),
      ],
    );
  }
}

class _OriginalMessageTile extends StatelessWidget {
  const _OriginalMessageTile({required this.body});
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text('Original message',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.hintColor)),
      children: [Text(body, style: theme.textTheme.bodySmall)],
    );
  }
}

/// Renders the gross / fees / net breakdown and (for BUY confirmations)
/// flags mismatch with the broker's `BAmt`. Returns an empty SizedBox
/// when shares or price didn't parse — keeps the card layout uncluttered.
class _FeeCrossCheck extends StatelessWidget {
  const _FeeCrossCheck({required this.msg});
  final PendingBrokerMessage msg;

  @override
  Widget build(BuildContext context) {
    final shares = msg.parsedShares;
    final price = msg.parsedGrossPrice;
    if (shares == null || price == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isBuy = msg.parsedSide == 'BUY';
    final txnValue = shares * price;
    final fees = isBuy ? computeBuyFees(shares, price, defaultFeeSchedule) : null;
    final computed = fees == null ? txnValue : txnValue + fees.totalFees;

    final lines = <Widget>[
      _kv(theme, 'Gross',
          'Rs ${txnValue.toStringAsFixed(2)} ($shares × ${price.toStringAsFixed(2)})'),
      if (fees != null)
        _kv(theme, 'Fees',
            'Rs ${fees.totalFees.toStringAsFixed(2)} '
            '(brk ${fees.brokerCommission.toStringAsFixed(2)}, '
            'sebon ${fees.sebonFee.toStringAsFixed(2)}, '
            'dp ${fees.dpFee.toStringAsFixed(0)})'),
      _kv(theme, isBuy ? 'Net cost' : 'Net (pre-CGT)',
          'Rs ${computed.toStringAsFixed(2)}'),
    ];
    if (msg.billAmount != null) {
      final delta = (computed - msg.billAmount!).abs();
      final mismatch = delta > 1; // tolerate 1 rupee rounding
      lines.add(_kv(theme, 'Broker BAmt',
          'Rs ${msg.billAmount!.toStringAsFixed(2)}'
          '${mismatch ? ' (off by Rs ${delta.toStringAsFixed(2)})' : ' ✓ matches'}',
          warn: mismatch));
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: lines),
    );
  }

  Widget _kv(ThemeData theme, String k, String v, {bool warn = false}) {
    final color = warn ? theme.colorScheme.error : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 84,
              child: Text(k,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.hintColor))),
          Expanded(
            child: Text(v,
                style: theme.textTheme.labelSmall?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

final _pendingMessagesProvider =
    FutureProvider<List<PendingBrokerMessage>>((ref) async {
  final inbox = await ref.watch(brokerInboxRepositoryProvider.future);
  return inbox.list(status: PendingMessageStatus.pending);
});
