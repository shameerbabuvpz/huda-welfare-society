import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/ayalkoottam_provider.dart';
import '../../../models/ayalkoottam.dart';
import '../../../widgets/app_bottom_sheet.dart';

class AyalkoottamListScreen extends StatefulWidget {
  const AyalkoottamListScreen({super.key});

  @override
  State<AyalkoottamListScreen> createState() => _AyalkoottamListScreenState();
}

class _AyalkoottamListScreenState extends State<AyalkoottamListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AyalkoottamProvider>().load();
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
      context.read<AyalkoottamProvider>().loadMore();
    }
  }

  void _search(String v) {
    context.read<AyalkoottamProvider>().load(search: v.isEmpty ? null : v);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AyalkoottamProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayalkoottam'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/admin/ayalkoottam/add');
          if (!context.mounted) return;
          context.read<AyalkoottamProvider>().load();
        },
        child: const Icon(Icons.add),
      ),
      body: provider.loading
          ? const ListSkeletonLoader()
          : provider.list.isEmpty
              ? const Center(child: Text('No ayalkoottams found'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: provider.list.length + (provider.loadingMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == provider.list.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }
                    final ak = provider.list[i];
                    return _AyalkoottamTile(ak: ak);
                  },
                ),
    );
  }
}

class _AyalkoottamTile extends StatelessWidget {
  final Ayalkoottam ak;
  const _AyalkoottamTile({required this.ak});

  @override
  Widget build(BuildContext context) {
    final isActive = ak.status == 'active';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(Icons.groups_2, color: isActive ? AppTheme.primary : Colors.grey),
        ),
        title: Row(
          children: [
            Flexible(child: Text(ak.name, style: TextStyle(fontWeight: FontWeight.w600, color: isActive ? null : Colors.grey))),
            if (!isActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Inactive', style: TextStyle(fontSize: 10, color: AppTheme.error)),
              ),
            ],
          ],
        ),
        subtitle: ak.place != null ? Text(ak.place!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${ak.memberCount ?? 0}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                  ),
                ),
                const Text('Members', style: TextStyle(fontSize: 10)),
              ],
            ),
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'toggle', child: Text(isActive ? 'Deactivate' : 'Activate')),
              ],
              onSelected: (v) {
                if (v == 'edit') {
                  _showEditDialog(context);
                } else if (v == 'toggle') {
                  _confirmToggle(context);
                }
              },
            ),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, '/admin/ayalkoottam/detail', arguments: ak),
      ),
    );
  }

  void _confirmToggle(BuildContext context) {
    final isActive = ak.status == 'active';
    showAppSheet(
      context: context,
      title: isActive ? 'Deactivate' : 'Activate',
      initialChildSize: 0.3,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('"${ak.name}" — ${isActive ? "deactivate" : "activate"}?'),
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
            if (isActive) {
              context.read<AyalkoottamProvider>().deactivate(ak.id);
            } else {
              context.read<AyalkoottamProvider>().update(ak.id, {'status': 'active'});
            }
          },
          child: Text(isActive ? 'Deactivate' : 'Activate'),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: ak.name);
    final placeCtrl = TextEditingController(text: ak.place ?? '');

    showAppBottomSheet(
      context: context,
      title: 'Edit Ayalkoottam',
      initialChildSize: 0.45,
      bodyBuilder: (ctx, sc) => SingleChildScrollView(
        controller: sc,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: placeCtrl, decoration: const InputDecoration(labelText: 'Place', border: OutlineInputBorder())),
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
                      data['place'] = placeCtrl.text.trim();
                      context.read<AyalkoottamProvider>().update(ak.id, data);
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
