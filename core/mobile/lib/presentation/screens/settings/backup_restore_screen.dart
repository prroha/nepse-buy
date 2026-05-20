import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/backup/backup_bundle.dart';
import '../../../domain/backup/backup_service.dart';

/// "Settings → Backup & Restore" screen. Two actions:
///   • Export — bundles user-personal data and hands it to the share sheet.
///   • Import — picks a JSON bundle and replaces local state atomically.
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _busy = false;
  String? _lastMessage;
  bool _lastWasError = false;

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _lastMessage = null;
    });
    try {
      final svc = await ref.read(backupServiceProvider.future);
      await svc.exportAndShare();
      if (!mounted) return;
      setState(() {
        _lastMessage = 'Backup shared. Save it to Drive, Files, or send it to '
            'yourself — you can restore from this file later.';
        _lastWasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMessage = 'Export failed: $e';
        _lastWasError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
          'This will replace your current watchlist, trades, debt accounts, '
          'fee schedule, and settings with the contents of the chosen backup. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Replace')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _lastMessage = null;
    });
    try {
      final svc = await ref.read(backupServiceProvider.future);
      final outcome = await svc.pickAndRestore();
      if (!mounted) return;
      setState(() {
        _lastMessage = outcome == null
            ? 'No file was picked.'
            : outcome.summary();
        _lastWasError = false;
      });
    } on BackupParseException catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMessage = 'That file isn\'t a valid nepse-buy backup: ${e.message}';
        _lastWasError = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMessage = 'Restore failed: $e';
        _lastWasError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Your watchlist, trades, debt accounts, and fee schedule live on '
            'this device. Export a backup to Google Drive (or any storage) '
            'so you can restore if you reinstall the app or switch phones.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Export backup'),
              subtitle: const Text(
                  'Creates a JSON file and opens the share sheet.'),
              trailing: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _busy ? null : _export,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore from backup'),
              subtitle: const Text(
                  'Pick a previously exported JSON file to replace local data.'),
              trailing: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _busy ? null : _restore,
            ),
          ),
          if (_lastMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lastWasError
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _lastWasError
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
