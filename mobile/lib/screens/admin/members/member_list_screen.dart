import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/member_provider.dart';
import '../../../models/member.dart';
import '../../../config/routes.dart';
import '../../../widgets/app_bottom_sheet.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MemberProvider>().loadMembers());
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
    context.read<MemberProvider>().loadMembers(search: v.isEmpty ? null : v);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
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
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _search,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.addMember);
          if (mounted) context.read<MemberProvider>().loadMembers();
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
          child: Text(member.name[0].toUpperCase(), style: TextStyle(color: isActive ? null : Colors.grey)),
        ),
        title: Row(
          children: [
            Flexible(child: Text(member.name, overflow: TextOverflow.ellipsis)),
            if (member.designation != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: member.designation == 'president' ? Colors.amber.shade50 : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  member.designation == 'president' ? 'P' : 'S',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: member.designation == 'president' ? Colors.amber.shade800 : Colors.purple.shade800),
                ),
              ),
            ],
            if (!isActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                child: Text('Inactive', style: TextStyle(fontSize: 10, color: Colors.red.shade700)),
              ),
            ],
          ],
        ),
        subtitle: Text('${member.phone ?? ''}${member.ayalkoottamName != null ? ' • ${member.ayalkoottamName}' : ''}'),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'toggle_status',
              child: Text(isActive ? 'Deactivate' : 'Activate'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Remove', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (v) {
            if (v == 'edit') _showEditDialog(context);
            else if (v == 'toggle_status') _confirmToggle(context);
            else if (v == 'delete') _confirmDelete(context);
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
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.red : Colors.green),
          onPressed: () {
            Navigator.pop(context);
            context.read<MemberProvider>().updateMember(member.id, {'status': isActive ? 'inactive' : 'active'});
          },
          child: Text(isActive ? 'Deactivate' : 'Activate'),
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
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

    showAppBottomSheet(
      context: context,
      title: 'Edit Member',
      initialChildSize: 0.5,
      bodyBuilder: (ctx, sc) => SingleChildScrollView(
        controller: sc,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
    );
  }
}
