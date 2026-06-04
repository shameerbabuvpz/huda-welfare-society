import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/asset_provider.dart';
import '../../../models/asset.dart';
import '../../../models/member.dart';
import '../../../services/member_service.dart';

class IssueAssetScreen extends StatefulWidget {
  const IssueAssetScreen({super.key});

  @override
  State<IssueAssetScreen> createState() => _IssueAssetScreenState();
}

class _IssueAssetScreenState extends State<IssueAssetScreen> {
  Asset? _selectedAsset;
  Member? _selectedMember;
  final _remarksCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _issuing = false;

  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  bool _loadingMembers = true;
  final _memberSearchCtrl = TextEditingController();
  String? _selectedAyalkoottam;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetProvider>().loadAvailableAssets();
    });
    _loadMembers();
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    _memberSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final result = await MemberService.list(page: 1);
      final list = (result['data'] as List).map((m) => Member.fromJson(m)).toList();
      if (mounted) {
        setState(() {
          _members = list;
          _filteredMembers = list;
          _loadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  void _filterMembers(String query) {
    setState(() {
      _filteredMembers = _members.where((m) {
        final matchesSearch = query.isEmpty ||
            m.name.toLowerCase().contains(query.toLowerCase()) ||
            (m.phone ?? '').contains(query);
        final matchesAyalkoottam = _selectedAyalkoottam == null || m.ayalkoottamName == _selectedAyalkoottam;
        return matchesSearch && matchesAyalkoottam;
      }).toList();
    });
  }

  void _onAyalkoottamFilterChanged(String? value) {
    setState(() {
      _selectedAyalkoottam = value;
    });
    _filterMembers(_memberSearchCtrl.text);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _issueItem() async {
    if (_selectedAsset == null || _selectedMember == null) return;

    setState(() => _issuing = true);
    final success = await context.read<AssetProvider>().issueAsset(
      _selectedAsset!.id,
      _selectedMember!.id,
      dueDate: _dueDate?.toIso8601String().split('T').first,
      remarks: _remarksCtrl.text.isNotEmpty ? _remarksCtrl.text : null,
    );
    setState(() => _issuing = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar('${_selectedAsset!.name} issued to ${_selectedMember!.name}'),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(context.read<AssetProvider>().error ?? 'Failed to issue'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssetProvider>();
    final availableAssets = provider.availableAssets;

    return Scaffold(
      appBar: AppBar(title: const Text('Issue Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Select Asset
            const Text('1. Select Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (availableAssets.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('No items available for issue')),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableAssets.length,
                  itemBuilder: (ctx, i) {
                    final asset = availableAssets[i];
                    final selected = _selectedAsset?.id == asset.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedAsset = asset),
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selected ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
                            border: Border.all(
                              color: selected ? AppTheme.primary : Theme.of(context).colorScheme.outline,
                              width: selected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2, size: 20, color: selected ? AppTheme.primary : Colors.grey),
                              const SizedBox(height: 4),
                              Text(asset.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: selected ? AppTheme.primary : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(asset.category ?? 'General', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // Step 2: Select Member
            const Text('2. Select Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedAyalkoottam,
              decoration: const InputDecoration(
                hintText: 'Filter by Ayalkoottam',
                prefixIcon: Icon(Icons.groups),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('All Ayalkoottams')),
                ..._members
                    .map((m) => m.ayalkoottamName)
                    .whereType<String>()
                    .toSet()
                    .map((name) => DropdownMenuItem<String>(value: name, child: Text(name))),
              ],
              onChanged: _onAyalkoottamFilterChanged,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _memberSearchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search member by name or phone...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterMembers,
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: _loadingMembers
                  ? const ListSkeletonLoader()
                  : _filteredMembers.isEmpty
                      ? const Center(child: Text('No members found'))
                      : ListView.builder(
                          itemCount: _filteredMembers.length,
                          itemBuilder: (ctx, i) {
                            final m = _filteredMembers[i];
                            final selected = _selectedMember?.id == m.id;
                            return ListTile(
                              dense: true,
                              selected: selected,
                              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: selected ? AppTheme.primary : Colors.grey.shade200,
                                child: Text(m.name[0].toUpperCase(), style: TextStyle(color: selected ? Colors.white : Colors.black, fontSize: 12)),
                              ),
                              title: Text(m.name, style: const TextStyle(fontSize: 14)),
                              subtitle: Text(m.ayalkoottamName ?? m.phone ?? '', style: const TextStyle(fontSize: 12)),
                              trailing: selected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
                              onTap: () => setState(() => _selectedMember = m),
                            );
                          },
                        ),
            ),

            const SizedBox(height: 24),

            // Step 3: Optional details
            const Text('3. Details (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Due Date', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                child: Text(
                  _dueDate != null ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}' : 'No due date set',
                  style: TextStyle(color: _dueDate != null ? Colors.black : Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksCtrl,
              decoration: const InputDecoration(labelText: 'Remarks', prefixIcon: Icon(Icons.notes), border: OutlineInputBorder()),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // Summary & Submit
            if (_selectedAsset != null && _selectedMember != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Item: ${_selectedAsset!.name} (${_selectedAsset!.assetCode})'),
                    Text('To: ${_selectedMember!.name}'),
                    if (_dueDate != null) Text('Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedAsset == null || _selectedMember == null || _issuing) ? null : _issueItem,
                icon: _issuing ? const SizedBox(width: 18, height: 18, child: CupertinoActivityIndicator()) : const Icon(Icons.send),
                label: Text(_issuing ? 'Issuing...' : 'Issue Item'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
