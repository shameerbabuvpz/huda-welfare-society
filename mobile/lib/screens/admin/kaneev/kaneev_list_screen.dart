import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/kaneev_provider.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';

class KaneevListScreen extends StatefulWidget {
  const KaneevListScreen({super.key});

  @override
  State<KaneevListScreen> createState() => _KaneevListScreenState();
}

class _KaneevListScreenState extends State<KaneevListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<KaneevProvider>().loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KaneevProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('കനീവ് Groups')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.manageKaneev),
        child: const Icon(Icons.add),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.groups.isEmpty
              ? const Center(child: Text('No kaneev groups'))
              : ListView.builder(
                  itemCount: provider.groups.length,
                  itemBuilder: (ctx, i) {
                    final g = provider.groups[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.volunteer_activism, color: AppTheme.primary),
                        ),
                        title: Text(g.name),
                        subtitle: Text('${g.code} • ₹${g.donationAmount.toStringAsFixed(0)}/mo • ${g.durationMonths ?? '-'} months'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: g.status == 'active'
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            g.status,
                            style: TextStyle(
                              fontSize: 12,
                              color: g.status == 'active' ? AppTheme.primary : Colors.grey,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.manageKaneev);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
