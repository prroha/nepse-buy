import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/debt_repository.dart';
import '../../providers/debt_provider.dart';
import '../../widgets/molecules/app_snackbar.dart';

class DebtAccountsScreen extends ConsumerWidget {
  const DebtAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(debtAccountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Debt accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(debtAccountsProvider.notifier).refresh(),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(child: Text(e.toString(), textAlign: TextAlign.center)),
            ],
          ),
          data: (accounts) {
            if (accounts.isEmpty) return const _Empty();
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: accounts.length,
              itemBuilder: (_, i) => _AccountRow(account: accounts[i], onTap: () => _openEditor(context, ref, accounts[i])),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, DebtAccount? existing) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DebtEditor(existing: existing),
    );
    if (saved == true) ref.read(debtAccountsProvider.notifier).refresh();
  }
}

class _AccountRow extends ConsumerWidget {
  final DebtAccount account;
  final VoidCallback onTap;
  const _AccountRow({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bal = double.tryParse(account.balance) ?? 0;
    final rate = double.tryParse(account.interestRate) ?? 0;
    return Dismissible(
      key: ValueKey(account.id),
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
                title: Text('Remove "${account.name}"?'),
                content: const Text('This account will no longer feed the engine\'s OD-sweep calculation.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Remove', style: TextStyle(color: theme.colorScheme.error))),
                ],
              ),
            ) ?? false;
      },
      onDismissed: (_) async {
        final ok = await ref.read(debtAccountsProvider.notifier).remove(account.id);
        if (!context.mounted) return;
        AppSnackbar.info(context, ok ? 'Removed "${account.name}"' : 'Remove failed');
      },
      child: ListTile(
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${rate.toStringAsFixed(2)}% p.a. · ${account.isActive ? "Active" : "Inactive"}'),
        trailing: Text('Rs ${_compact(bal)}', style: theme.textTheme.titleMedium),
        onTap: onTap,
      ),
    );
  }

  String _compact(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _DebtEditor extends ConsumerStatefulWidget {
  final DebtAccount? existing;
  const _DebtEditor({required this.existing});
  @override
  ConsumerState<_DebtEditor> createState() => _DebtEditorState();
}

class _DebtEditorState extends ConsumerState<_DebtEditor> {
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late final TextEditingController _rate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _balance = TextEditingController(text: widget.existing?.balance ?? '');
    _rate = TextEditingController(text: widget.existing?.interestRate ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final balance = _balance.text.trim();
    final rate = _rate.text.trim();
    if (name.isEmpty || balance.isEmpty || rate.isEmpty) {
      AppSnackbar.error(context, 'All fields required');
      return;
    }
    setState(() => _saving = true);
    bool ok;
    if (widget.existing == null) {
      ok = await ref.read(debtAccountsProvider.notifier).create(
            DebtAccountInput(name: name, balance: balance, interestRate: rate),
          );
    } else {
      ok = await ref.read(debtAccountsProvider.notifier).edit(
            widget.existing!.id,
            DebtAccountPatch(name: name, balance: balance, interestRate: rate),
          );
    }
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      AppSnackbar.error(context, 'Save failed');
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
            Text(widget.existing == null ? 'Add debt account' : 'Edit debt account', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name (e.g., 15L OD Loan)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
              controller: _balance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Outstanding balance (NPR)', border: OutlineInputBorder(), prefixText: 'Rs '),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Annual interest rate (%)', border: OutlineInputBorder(), suffixText: '% p.a.'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(widget.existing == null ? 'Add' : 'Save'),
            ),
          ],
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
        SizedBox(height: 100),
        Center(child: Icon(Icons.account_balance_outlined, size: 56, color: Colors.grey)),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Text(
              'No debt accounts yet.\nAdd your OD loan so the engine can quantify interest savings during strong-season months.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
