import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/infacc_sync_service.dart';

class InfaccSyncPreviewScreen extends StatefulWidget {
  const InfaccSyncPreviewScreen({super.key});

  @override
  State<InfaccSyncPreviewScreen> createState() => _InfaccSyncPreviewScreenState();
}

class _InfaccSyncPreviewScreenState extends State<InfaccSyncPreviewScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _plan;

  bool _syncMembers = true;
  bool _syncAyalkoottams = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final result = await InfaccSyncService.preview();
      if (result['success'] == true) {
        setState(() {
          _plan = result['plan'] as Map<String, dynamic>;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load preview';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _performSync() async {
    final selectedTypes = <String>[];
    if (_syncMembers) selectedTypes.add('members');
    if (_syncAyalkoottams) selectedTypes.add('ayalkoottams');

    if (selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar('Select at least one type to sync'),
      );
      return;
    }

    setState(() => _syncing = true);
    try {
      final result = await InfaccSyncService.sync(selectedTypes: selectedTypes);
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Sync completed successfully'),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() => _error = result['message'] ?? 'Sync failed');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Changes'),
        centerTitle: true,
      ),
      body: _loading
          ? const ListSkeletonLoader()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadPreview,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${_plan?['totalMembers'] ?? 0}',
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Members',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${_plan?['totalAyalkoottams'] ?? 0}',
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Ayalkoottams',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Select what to sync
                      Text(
                        'What to sync',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sync Members checkbox
                      _buildCheckboxTile(
                        'Members',
                        _syncMembers,
                        (value) => setState(() => _syncMembers = value ?? true),
                        _buildMemberPlan(_plan?['members'] as Map<String, dynamic>?),
                      ),

                      const SizedBox(height: 12),

                      // Sync Ayalkoottams checkbox
                      _buildCheckboxTile(
                        'Ayalkoottams (Groups)',
                        _syncAyalkoottams,
                        (value) => setState(() => _syncAyalkoottams = value ?? true),
                        _buildAyalkoottamPlan(_plan?['ayalkoottams'] as Map<String, dynamic>?),
                      ),

                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _syncing ? null : () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _syncing ? null : _performSync,
                              child: _syncing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CupertinoActivityIndicator(),
                                    )
                                  : const Text('Sync Now'),
                            ),
                          ),
                        ],
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_error!, style: const TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
    Widget details,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            value: value,
            onChanged: onChanged,
          ),
          if (value)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: details,
            ),
        ],
      ),
    );
  }

  Widget _buildMemberPlan(Map<String, dynamic>? plan) {
    if (plan == null) return const SizedBox();
    
    final create = ((plan['create'] ?? []) as List).length;
    final update = ((plan['update'] ?? []) as List).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (create > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text('$create new members will be added'),
              ],
            ),
          ),
        if (update > 0)
          Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text('$update members will be updated'),
            ],
          ),
        if (create == 0 && update == 0)
          const Text('No changes'),
      ],
    );
  }

  Widget _buildAyalkoottamPlan(Map<String, dynamic>? plan) {
    if (plan == null) return const SizedBox();
    
    final create = ((plan['create'] ?? []) as List).length;
    final update = ((plan['update'] ?? []) as List).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (create > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text('$create new ayalkoottams will be added'),
              ],
            ),
          ),
        if (update > 0)
          Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text('$update ayalkoottams will be updated'),
            ],
          ),
        if (create == 0 && update == 0)
          const Text('No changes'),
      ],
    );
  }
}
