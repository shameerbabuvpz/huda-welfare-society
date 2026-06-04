import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/kuri_provider.dart';
import '../../../config/routes.dart';

class KuriListScreen extends StatefulWidget {
  const KuriListScreen({super.key});

  @override
  State<KuriListScreen> createState() => _KuriListScreenState();
}

class _KuriListScreenState extends State<KuriListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KuriProvider>().loadGroups();
    });
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
      context.read<KuriProvider>().loadMore();
    }
  }

  void _search(String v) {
    context.read<KuriProvider>().loadGroups(search: v.isEmpty ? null : v);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KuriProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuri Groups'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search kuri...',
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
          await Navigator.pushNamed(context, AppRoutes.createKuri);
          if (!context.mounted) return;
          context.read<KuriProvider>().loadGroups();
        },
        child: const Icon(Icons.add),
      ),
      body: provider.loading
          ? const ListSkeletonLoader()
          : provider.groups.isEmpty
              ? const Center(child: Text('No kuri groups'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: provider.groups.length + (provider.loadingMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == provider.groups.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }
                    final g = provider.groups[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.account_balance, color: AppTheme.primary),
                        ),
                        title: Text(g.name),
                        subtitle: Text('${g.code} • ₹${g.monthlyAmount.toStringAsFixed(0)}/mo • ${g.durationMonths} months'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: g.status == 'active'
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            g.status,
                            style: TextStyle(fontSize: 12, color: g.status == 'active' ? AppTheme.primary : Colors.grey),
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.kuriDetail, arguments: g.id);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
