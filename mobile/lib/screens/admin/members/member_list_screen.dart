import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../../../providers/member_provider.dart';
import '../../../providers/ayalkoottam_provider.dart';
import '../../../models/member.dart';
import '../../../config/routes.dart';
import '../../../services/export_service.dart';
import '../../../utils/ak_name_helper.dart';
import '../../../widgets/app_bottom_sheet.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  int? _filterAyalkoottamId;
  String? _filterAyalkoottamName;

  @override
  void initState() {
    super.initState();
    context.read<MemberProvider>().loadMembers();
    context.read<AyalkoottamProvider>().loadDropdown();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<MemberProvider>().loadMore();
    }
  }

  void _search(String v) {
    context.read<MemberProvider>().loadMembers(search: v.isEmpty ? null : v, ayalkoottamId: _filterAyalkoottamId);
  }

  void _applyFilter(int? id, String? name) {
    setState(() {
      _filterAyalkoottamId = id;
      _filterAyalkoottamName = name;
    });
    final search = _searchController.text.isEmpty ? null : _searchController.text;
    context.read<MemberProvider>().loadMembers(search: search, ayalkoottamId: id);
  }

  void _showFilterSheet() {
    final akProvider = context.read<AyalkoottamProvider>();
    showAppBottomSheet(
      context: context,
      title: 'Filter by Ayalkoottam',
      initialChildSize: 0.5,
      bodyBuilder: (ctx, sc) => ListView(
        controller: sc,
        children: [
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('All Members'),
            selected: _filterAyalkoottamId == null,
            onTap: () {
              Navigator.pop(ctx);
              _applyFilter(null, null);
            },
          ),
          const Divider(),
          ...akProvider.dropdownList.map((ak) => ListTile(
            leading: const Icon(Icons.group_outlined),
            title: Text(shortAkName(ak.name)),
            selected: _filterAyalkoottamId == ak.id,
            onTap: () {
              Navigator.pop(ctx);
              _applyFilter(ak.id, shortAkName(ak.name));
            },
          )),
        ],
      ),
    );
  }

  void _exportMembers() async {
    try {
      await ExportService.membersExcel(ayalkoottamId: _filterAyalkoottamId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _filterAyalkoottamId != null,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter by Ayalkoottam',
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export to Excel',
            onPressed: _exportMembers,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_filterAyalkoottamId != null ? 92 : 56),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () { _searchController.clear(); _search(''); },
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: _search,
                ),
              ),
              if (_filterAyalkoottamId != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Row(
                    children: [
                      Chip(
                        label: Text(_filterAyalkoottamName ?? 'Filtered'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _applyFilter(null, null),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.addMember);
          if (!context.mounted) return;
          context.read<MemberProvider>().loadMembers();
        },
        child: const Icon(Icons.add),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.members.isEmpty
              ? const Center(child: Text('No members found'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: provider.members.length + (provider.loadingMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == provider.members.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final m = provider.members[i];
                    return _MemberTile(member: m);
                  },
                ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final isActive = member.status == 'active';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? null : Colors.grey.shade200,
          backgroundImage: member.photoUrl != null && member.photoUrl!.isNotEmpty
              ? NetworkImage(member.photoUrl!)
              : null,
          child: member.photoUrl == null || member.photoUrl!.isEmpty
              ? Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?', style: TextStyle(color: isActive ? null : Colors.grey))
              : null,
        ),
        title: Row(
          children: [
            Flexible(child: Text(member.name, overflow: TextOverflow.ellipsis)),
            if (member.designation != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: member.designation == 'president'
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  member.designation == 'president' ? 'P' : 'S',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: member.designation == 'president' ? AppTheme.accent : AppTheme.primary),
                ),
              ),
            ],
            if (!isActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(6)),
                child: const Text('Inactive', style: TextStyle(fontSize: 10, color: AppTheme.error)),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            if (member.phone != null && member.phone!.isNotEmpty)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${member.phone}${member.ayalkoottamName != null ? ' • ${member.ayalkoottamName}' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.call, size: 18),
                      onPressed: () => _makeCall(member.phone!),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Call ${member.name}',
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Text(
                  member.ayalkoottamName ?? 'No contact info',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'toggle_status',
              child: Text(isActive ? 'Deactivate' : 'Activate'),
            ),
            const PopupMenuItem(value: 'reset_code', child: Text('Reset Code')),
            const PopupMenuItem(value: 'delete', child: Text('Remove', style: TextStyle(color: AppTheme.error))),
          ],
          onSelected: (v) {
            if (v == 'edit') {
              _showEditDialog(context);
            } else if (v == 'toggle_status') {
              _confirmToggle(context);
            } else if (v == 'reset_code') {
              _resetMemberCode(context);
            } else if (v == 'delete') {
              _confirmDelete(context);
            }
          },
        ),
      ),
    );
  }

  void _confirmToggle(BuildContext context) {
    final isActive = member.status == 'active';
    showAppSheet(
      context: context,
      title: isActive ? 'Deactivate Member' : 'Activate Member',
      initialChildSize: 0.3,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Change ${member.name} status to ${isActive ? "inactive" : "active"}?'),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isActive ? AppTheme.error : AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            Navigator.pop(context);
            context.read<MemberProvider>().updateMember(member.id, {'status': isActive ? 'inactive' : 'active'});
          },
          child: Text(isActive ? 'Deactivate' : 'Activate'),
        ),
      ],
    );
  }

  void _resetMemberCode(BuildContext context) {
    showAppSheet(
      context: context,
      title: 'Reset Member Code',
      initialChildSize: 0.35,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text('Reset ${member.name}\'s login code to default (6789)?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'They will need to use code 6789 to log in next time.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () async {
            Navigator.pop(context);
            try {
              await context.read<MemberProvider>().resetMemberCodeToDefault(member.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.successSnackBar('Code reset to 6789'),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.errorSnackBar('Failed to reset code'),
                );
              }
            }
          },
          child: const Text('Reset Code'),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showAppSheet(
      context: context,
      title: 'Remove Member',
      initialChildSize: 0.3,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Remove ${member.name}? This action cannot be undone.'),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.error,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            Navigator.pop(context);
            context.read<MemberProvider>().deleteMember(member.id);
          },
          child: const Text('Remove'),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: member.name);
    final phoneCtrl = TextEditingController(text: member.phone ?? '');
    final addressCtrl = TextEditingController(text: member.address ?? '');
    int? selectedAkId = member.ayalkoottamId;
    final akProvider = context.read<AyalkoottamProvider>();

    showAppBottomSheet(
      context: context,
      title: 'Edit Member',
      initialChildSize: 0.6,
      bodyBuilder: (ctx, sc) => StatefulBuilder(
        builder: (ctx, setSheetState) => SingleChildScrollView(
          controller: sc,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Ayalkoottam', border: OutlineInputBorder(), prefixIcon: Icon(Icons.groups_2)),
                value: selectedAkId,
                isExpanded: true,
                items: akProvider.dropdownList.map((ak) {
                  return DropdownMenuItem(value: ak.id, child: Text(shortAkName(ak.name), overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) => setSheetState(() => selectedAkId = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final data = <String, dynamic>{};
                        if (nameCtrl.text.trim().isNotEmpty) data['name'] = nameCtrl.text.trim();
                        if (phoneCtrl.text.trim().isNotEmpty) data['phone'] = phoneCtrl.text.trim();
                        data['address'] = addressCtrl.text.trim();
                        if (selectedAkId != member.ayalkoottamId) data['ayalkoottam_id'] = selectedAkId;
                        context.read<MemberProvider>().updateMember(member.id, data);
                      },
                      child: const Text('Save'),
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

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
