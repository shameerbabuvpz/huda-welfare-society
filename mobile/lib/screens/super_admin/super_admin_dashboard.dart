import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/organization.dart';
import '../../services/organization_service.dart';
import 'super_admin_org_detail_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  List<Organization> _organizations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrgs();
  }

  Future<void> _loadOrgs() async {
    setState(() => _loading = true);
    try {
      final orgs = await OrganizationService.list();
      setState(() {
        _organizations = orgs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error: $e'),
        );
      }
    }
  }

  Future<void> _createOrg() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CreateOrgSheet(),
    );
    if (result == null) return;

    try {
      await OrganizationService.create({
        'name': result['name']!,
        if (result['place'] != null && result['place']!.isNotEmpty) 'place': result['place'],
      });
      _loadOrgs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error: $e'),
        );
      }
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createOrg,
        icon: const Icon(Icons.add),
        label: const Text('New Organization'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _organizations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/ayalkoottam.png', height: 132),
                        const SizedBox(height: 18),
                        Text(
                          'No organizations yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the action button to create the first organization.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.ink.withValues(alpha: 0.72),
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrgs,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    itemCount: _organizations.length,
                    itemBuilder: (ctx, i) {
                      final org = _organizations[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: org.logoUrl != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(org.logoUrl!),
                                )
                              : const CircleAvatar(child: Icon(Icons.business)),
                          title: Text(org.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(org.place ?? ''),
                          trailing: Chip(
                            label: Text(org.status, style: const TextStyle(fontSize: 12)),
                            backgroundColor: org.status == 'active'
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.errorContainer,
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SuperAdminOrgDetailScreen(orgId: org.id),
                              ),
                            );
                            _loadOrgs();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _CreateOrgSheet extends StatefulWidget {
  const _CreateOrgSheet();

  @override
  State<_CreateOrgSheet> createState() => _CreateOrgSheetState();
}

class _CreateOrgSheetState extends State<_CreateOrgSheet> {
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 20),
              Text('Create Organization', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Organization Name *'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _placeController,
                decoration: const InputDecoration(labelText: 'Place'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(
                    onPressed: () {
                      if (_nameController.text.trim().isEmpty) return;
                      Navigator.pop(context, {'name': _nameController.text.trim(), 'place': _placeController.text.trim()});
                    },
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Create'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
