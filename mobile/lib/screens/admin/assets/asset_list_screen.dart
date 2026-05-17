import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/asset_provider.dart';
import '../../../models/asset.dart';
import '../../../models/member.dart';
import '../../../services/asset_service.dart';
import '../../../services/member_service.dart';
import '../../../config/routes.dart';
import '../../../widgets/app_bottom_sheet.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final provider = context.read<AssetProvider>();
    provider.loadAssets();
    provider.loadStats();
    provider.loadIssueRegister();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(child: Text('Items', maxLines: 2, textAlign: TextAlign.center)),
            Tab(child: Text('Issue Register', maxLines: 2, textAlign: TextAlign.center)),
            Tab(child: Text('Report', maxLines: 2, textAlign: TextAlign.center)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Item',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addAsset),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ItemsTab(),
          _IssueRegisterTab(),
          _DamageReportTab(),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        if (_tabController.index == 1) {
          return FloatingActionButton.extended(
            heroTag: 'issue_fab',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.issueAsset),
            icon: const Icon(Icons.send),
            label: const Text('Issue Item'),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Tab 1: Items List ───────────────────────────────────────────────

class _ItemsTab extends StatelessWidget {
  const _ItemsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssetProvider>();
    final stats = provider.stats;

    return Column(
      children: [
        if (stats != null)
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(label: 'Total', value: '${stats.total}', color: AppTheme.primaryDark),
                _StatChip(label: 'Available', value: '${stats.available}', color: AppTheme.primary),
                _StatChip(label: 'Issued', value: '${stats.issued}', color: AppTheme.accent),
                _StatChip(label: 'Damaged', value: '${stats.damaged}', color: AppTheme.error),
              ],
            ),
          ),
        Expanded(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : provider.assets.isEmpty
                  ? const Center(child: Text('No items found'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await provider.loadAssets();
                        await provider.loadStats();
                      },
                      child: ListView.builder(
                        itemCount: provider.assets.length,
                        itemBuilder: (ctx, i) => _AssetTile(asset: provider.assets[i], provider: provider),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _AssetTile extends StatelessWidget {
  final Asset asset;
  final AssetProvider provider;
  const _AssetTile({required this.asset, required this.provider});

  Color _statusColor() {
    switch (asset.status) {
      case 'available': return AppTheme.primary;
      case 'issued': return AppTheme.accent;
      case 'damaged': return AppTheme.error;
      case 'missing': return AppTheme.primaryDark;
      default: return Colors.grey;
    }
  }

  IconData _conditionIcon() {
    switch (asset.condition) {
      case 'damaged': return Icons.warning_amber;
      case 'missing': return Icons.help_outline;
      default: return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor().withValues(alpha: 0.1),
          child: Icon(_conditionIcon(), color: _statusColor()),
        ),
        title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('${asset.category ?? 'General'} • ${asset.assetCode}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(asset.status.toUpperCase(), style: TextStyle(fontSize: 10, color: _statusColor(), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 4),
            PopupMenuButton(
              itemBuilder: (_) => [
                if (asset.isAvailableForIssue)
                  const PopupMenuItem(value: 'issue', child: Text('Issue to Member')),
                if (asset.status == 'issued')
                  const PopupMenuItem(value: 'return', child: Text('Return')),
                const PopupMenuItem(value: 'condition', child: Text('Change Condition')),
              ],
              onSelected: (v) {
                if (v == 'issue') {
                  _showIssueDialog(context);
                } else if (v == 'return') {
                  _showReturnDialog(context);
                } else if (v == 'condition') {
                  _showConditionDialog(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConditionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Item Condition', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _conditionTile(ctx, Icons.check_circle_outline, 'Working', Colors.green, () {
                  Navigator.pop(ctx);
                  provider.updateAsset(asset.id, {'condition': 'working', 'status': 'available'});
                }),
                _conditionTile(ctx, Icons.warning_amber_rounded, 'Damaged', Colors.orange, () {
                  Navigator.pop(ctx);
                  provider.updateAsset(asset.id, {'condition': 'damaged', 'status': 'damaged'});
                }),
                _conditionTile(ctx, Icons.cancel_outlined, 'Missing', AppTheme.error, () {
                  Navigator.pop(ctx);
                  provider.updateAsset(asset.id, {'condition': 'missing', 'status': 'missing'});
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _conditionTile(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  void _showIssueDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IssueAssetSheet(asset: asset, provider: provider),
    );
  }

  void _showReturnDialog(BuildContext context) {
    String selectedCondition = 'working';
    final remarksCtrl = TextEditingController();

    showAppBottomSheet(
      context: context,
      title: 'Return: ${asset.name}',
      initialChildSize: 0.55,
      bodyBuilder: (ctx, sc) => StatefulBuilder(
        builder: (ctx, setSheetState) => SingleChildScrollView(
          controller: sc,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('What condition is the item in?'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCondition,
                decoration: const InputDecoration(labelText: 'Condition', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'working', child: Text('✅ Working (re-issuable)')),
                  DropdownMenuItem(value: 'damaged', child: Text('⚠️ Damaged (cannot re-issue)')),
                  DropdownMenuItem(value: 'missing', child: Text('❌ Missing (cannot re-issue)')),
                ],
                onChanged: (v) => setSheetState(() => selectedCondition = v ?? 'working'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksCtrl,
                decoration: const InputDecoration(labelText: 'Remarks (optional)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              if (selectedCondition != 'working')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
                        const SizedBox(width: 8),
                        Expanded(child: Text('This item will be moved to damage report and cannot be re-issued.', style: TextStyle(fontSize: 12, color: Colors.orange.shade800))),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.returnAsset(asset.id, remarks: remarksCtrl.text.isNotEmpty ? remarksCtrl.text : null, conditionOnReturn: selectedCondition);
                      },
                      child: const Text('Confirm Return'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueAssetSheet extends StatefulWidget {
  final Asset asset;
  final AssetProvider provider;
  const _IssueAssetSheet({required this.asset, required this.provider});

  @override
  State<_IssueAssetSheet> createState() => _IssueAssetSheetState();
}

class _IssueAssetSheetState extends State<_IssueAssetSheet> {
  List<Member> _members = [];
  List<Member> _filtered = [];
  bool _loading = true;
  int? _selectedMemberId;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _loadMembers() async {
    try {
      final result = await MemberService.list(page: 1);
      final list = (result['data'] as List).map((m) => Member.fromJson(m)).toList();
      setState(() { _members = list; _filtered = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _filter(String query) {
    setState(() { _filtered = _members.where((m) => m.name.toLowerCase().contains(query.toLowerCase())).toList(); });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text('Issue "${widget.asset.name}"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close, size: 22), onPressed: () => Navigator.pop(context), splashRadius: 20),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search member...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: _filter,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final m = _filtered[i];
                        final selected = _selectedMemberId == m.id;
                        return ListTile(
                          dense: true,
                          selected: selected,
                          selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: selected ? AppTheme.primary : Colors.grey.shade200,
                            child: Text(
                              m.name[0].toUpperCase(),
                              style: TextStyle(
                                color: selected ? Colors.white : AppTheme.ink,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(m.name),
                          subtitle: Text(m.phone ?? ''),
                          trailing: selected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
                          onTap: () => setState(() => _selectedMemberId = m.id),
                        );
                      },
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _selectedMemberId == null ? null : () {
                      Navigator.pop(context);
                      widget.provider.issueAsset(widget.asset.id, _selectedMemberId!);
                    },
                    child: const Text('Issue Asset'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Issue Register ───────────────────────────────────────────

class _IssueRegisterTab extends StatelessWidget {
  const _IssueRegisterTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssetProvider>();

    if (provider.loading) return const Center(child: CircularProgressIndicator());
    if (provider.issueRegister.isEmpty) return const Center(child: Text('No issue records yet'));

    return RefreshIndicator(
      onRefresh: () => provider.loadIssueRegister(),
      child: ListView.builder(
        itemCount: provider.issueRegister.length,
        itemBuilder: (ctx, i) => _IssueRegisterTile(txn: provider.issueRegister[i]),
      ),
    );
  }
}

class _IssueRegisterTile extends StatelessWidget {
  final AssetTransaction txn;
  const _IssueRegisterTile({required this.txn});

  Color _statusColor() {
    if (txn.status == 'issued') return AppTheme.accent;
    if (txn.status == 'returned') return AppTheme.primary;
    if (txn.status == 'returned_damaged') return AppTheme.error;
    if (txn.status == 'returned_missing') return AppTheme.primaryDark;
    return Colors.grey;
  }

  String _statusLabel() {
    switch (txn.status) {
      case 'issued': return 'ISSUED';
      case 'returned': return 'RETURNED';
      case 'returned_damaged': return 'DAMAGED';
      case 'returned_missing': return 'MISSING';
      default: return txn.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(txn.assetName ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_statusLabel(), style: TextStyle(fontSize: 10, color: _statusColor(), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(txn.memberName ?? 'Unknown', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                const Spacer(),
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(txn.issueDate, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            if (txn.returnDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.assignment_return, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text('Returned: ${txn.returnDate}', style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
                  if (txn.conditionOnReturn != null && txn.conditionOnReturn != 'working') ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.warning_amber, size: 14, color: AppTheme.error),
                    Text(' ${txn.conditionOnReturn}', style: const TextStyle(fontSize: 12, color: AppTheme.error)),
                  ],
                ],
              ),
            ],
            if (txn.isOverdue) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.timer_off, size: 14, color: AppTheme.error),
                  const SizedBox(width: 4),
                  Text('OVERDUE - Due: ${txn.dueDate}', style: const TextStyle(fontSize: 12, color: AppTheme.error, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: Damage/Missing Report ────────────────────────────────────

class _DamageReportTab extends StatefulWidget {
  const _DamageReportTab();

  @override
  State<_DamageReportTab> createState() => _DamageReportTabState();
}

class _DamageReportTabState extends State<_DamageReportTab> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await AssetService.damageReport();
      setState(() { _items = result['data'] as List; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Theme.of(context).colorScheme.primaryContainer),
            const SizedBox(height: 12),
            Text('No damaged or missing items', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (ctx, i) {
          final item = _items[i];
          final condition = item['condition'] ?? 'unknown';
          final isDamaged = condition == 'damaged';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isDamaged
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                child: Icon(isDamaged ? Icons.warning_amber : Icons.help_outline, color: isDamaged ? AppTheme.accent : AppTheme.error),
              ),
              title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code: ${item['asset_code']}'),
                  if (item['last_transaction'] != null)
                    Text('Last with: ${item['last_transaction']['member_name'] ?? 'Unknown'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDamaged
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(condition.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDamaged ? AppTheme.accent : AppTheme.error)),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
