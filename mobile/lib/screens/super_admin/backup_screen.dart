import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _backingUp = false;
  bool _restoring = false;

  Future<void> _backup() async {
    setState(() => _backingUp = true);
    try {
      await BackupService.downloadBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Backup created. Save it somewhere safe.'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Backup failed: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  Future<void> _restore() async {
    // 1. Pick a .sql backup file
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (picked == null) return;
    final pickedFile = picked.files.single;
    final bytes = pickedFile.bytes;
    final name = pickedFile.name;

    if (bytes == null || !name.toLowerCase().endsWith('.sql')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Please choose a .sql backup file'),
        );
      }
      return;
    }

    // 2. Require typed confirmation — this overwrites ALL live data
    if (!mounted) return;
    final confirmed = await _confirmRestore();
    if (confirmed != true) return;

    setState(() => _restoring = true);
    try {
      final result = await BackupService.restoreBackup(bytes, filename: name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(
            'Restored ${result['totalRows'] ?? '?'} rows across '
            '${result['tables'] ?? '?'} tables.',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Restore failed: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<bool?> _confirmRestore() {
    final controller = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final canRestore = controller.text.trim() == 'RESTORE';
            return AlertDialog(
              title: const Text('Confirm Restore'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will ERASE all current data and replace it with the '
                    'contents of the backup file. This cannot be undone.\n\n'
                    'Type RESTORE to confirm.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'RESTORE',
                    ),
                    onChanged: (_) => setLocal(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: canRestore ? () => Navigator.pop(ctx, true) : null,
                  child: const Text(
                    'Restore',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _backingUp || _restoring;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InfoCard(),
          const SizedBox(height: 24),
          _ActionTile(
            icon: Icons.cloud_download_outlined,
            color: AppTheme.primary,
            title: 'Download Backup',
            subtitle:
                'Creates a full database backup (.sql) and lets you save or share it.',
            loading: _backingUp,
            onTap: busy ? null : _backup,
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.settings_backup_restore,
            color: AppTheme.error,
            title: 'Restore from Backup',
            subtitle:
                'Replaces ALL current data with a previously downloaded .sql file.',
            loading: _restoring,
            onTap: busy ? null : _restore,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'A backup is a complete copy of the live database. Download one '
              'regularly and keep it somewhere safe. Restoring will overwrite '
              'everything currently in the database.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.ink.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppTheme.ink.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
