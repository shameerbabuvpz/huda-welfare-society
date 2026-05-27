import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/infacc_sync_service.dart';
import 'infacc_sync_preview_screen.dart';

class InfaccSyncScreen extends StatefulWidget {
  const InfaccSyncScreen({super.key});

  @override
  State<InfaccSyncScreen> createState() => _InfaccSyncScreenState();
}

class _InfaccSyncScreenState extends State<InfaccSyncScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = true;
  bool _syncing = false;
  bool _hasCredentials = false;
  String? _infaccPhone;
  String? _lastSync;
  String? _syncResult;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await InfaccSyncService.getStatus();
      setState(() {
        _hasCredentials = status['hasCredentials'] == true;
        _infaccPhone = status['infaccPhone']?.toString();
        final ls = status['lastSync'];
        if (ls is Map) {
          _lastSync = ls['syncedAt']?.toString();
        } else if (ls is String) {
          _lastSync = ls;
        }
        if (_infaccPhone != null) _phoneController.text = _infaccPhone!;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Failed to load sync status'),
        );
      }
    }
  }

  Future<void> _saveCredentials() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar('Phone and password are required'),
      );
      return;
    }
    try {
      await InfaccSyncService.setCredentials(phone, password);
      setState(() {
        _hasCredentials = true;
        _infaccPhone = phone;
      });
      _passwordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Credentials saved'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Failed to save credentials'),
        );
      }
    }
  }

  Future<void> _triggerSync() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InfaccSyncPreviewScreen(),
      ),
    ).then((_) {
      // Reload status after syncing
      _loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync from INFACC')),
      body: _loading
          ? const ListSkeletonLoader()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _hasCredentials
                                    ? Icons.check_circle
                                    : Icons.warning_amber_rounded,
                                color: _hasCredentials
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _hasCredentials
                                    ? 'INFACC Connected'
                                    : 'Not Connected',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_infaccPhone != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Phone: $_infaccPhone',
                              style: TextStyle(
                                color: AppTheme.ink.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                          if (_lastSync != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Last sync: ${_formatDate(_lastSync!)}',
                              style: TextStyle(
                                color: AppTheme.ink.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Credentials section
                  const Text(
                    'INFACC Credentials',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your INFACC admin phone number and password to enable syncing.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.ink.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saveCredentials,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Credentials'),
                  ),
                  const SizedBox(height: 32),

                  // Sync button
                  FilledButton.icon(
                    onPressed: _hasCredentials && !_syncing
                        ? _triggerSync
                        : null,
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview & Sync'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  if (!_hasCredentials)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Save credentials first to enable sync.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.ink.withValues(alpha: 0.5),
                        ),
                      ),
                    ),

                  // Result
                  if (_syncResult != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: _syncResult!.startsWith('Synced')
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              _syncResult!.startsWith('Synced')
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _syncResult!.startsWith('Synced')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _syncResult!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes} min ago';
      if (diff.inDays < 1) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
