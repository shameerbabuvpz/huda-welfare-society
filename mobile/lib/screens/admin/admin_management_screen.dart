import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/admin.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_bottom_sheet.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAdmins();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<AdminProvider>().loadAdmins(search: query.isEmpty ? null : query);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdminDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Admin'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search admins...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearch,
            ),
          ),

          // Admin list
          Expanded(
            child: provider.loading
                ? const ListSkeletonLoader()
                : provider.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                            const SizedBox(height: 8),
                            Text(provider.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.loadAdmins(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : provider.admins.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text('No admins found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                                const SizedBox(height: 8),
                                Text('Tap + to add a new admin',
                                    style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.loadAdmins(search: _searchController.text.isEmpty ? null : _searchController.text),
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification is ScrollEndNotification && notification.metrics.extentAfter < 200) {
                                  provider.loadMore();
                                }
                                return false;
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: provider.admins.length + (provider.loadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == provider.admins.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(child: CupertinoActivityIndicator()),
                                    );
                                  }
                                  final admin = provider.admins[index];
                                  final isCurrentUser = admin.id == currentUserId;

                                  return _AdminCard(
                                    admin: admin,
                                    isCurrentUser: isCurrentUser,
                                    onEdit: () => _showAdminDialog(context, admin: admin),
                                    onDelete: isCurrentUser
                                        ? null
                                        : () => _confirmDelete(context, admin),
                                  );
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showAdminDialog(BuildContext context, {Admin? admin}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminFormSheet(admin: admin),
    );
  }

  void _confirmDelete(BuildContext context, Admin admin) async {
    final confirm = await showConfirmSheet(
      context: context,
      title: 'Remove Admin',
      message: 'Remove ${admin.name ?? admin.phone ?? 'this admin'}?\n\nThe account will be deactivated.',
      confirmLabel: 'Remove',
      isDestructive: true,
      icon: Icons.person_remove_outlined,
    );
    if (confirm != true) return;
    if (!context.mounted) return;
    final adminProvider = context.read<AdminProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final success = await adminProvider.deleteAdmin(admin.id);
    if (!context.mounted) return;
    scaffoldMessenger.showSnackBar(
      success
          ? AppTheme.successSnackBar('Admin removed')
          : AppTheme.errorSnackBar('Failed'),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final Admin admin;
  final bool isCurrentUser;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _AdminCard({
    required this.admin,
    required this.isCurrentUser,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: admin.isActive
                    ? (admin.isSuperAdmin
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : Theme.of(context).colorScheme.primaryContainer)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  admin.isSuperAdmin ? Icons.shield : Icons.admin_panel_settings,
                  size: 28,
                  color: admin.isActive
                      ? (admin.isSuperAdmin ? AppTheme.accent : AppTheme.primary)
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            admin.name ?? 'No name',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('You', style: TextStyle(fontSize: 11, color: AppTheme.primaryDark, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (admin.phone != null)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(admin.phone!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                        ],
                      ),
                    if (admin.email != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(admin.email!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: admin.isSuperAdmin
                                ? Theme.of(context).colorScheme.secondaryContainer
                                : Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            admin.isSuperAdmin ? 'Super Admin' : 'Admin',
                            style: TextStyle(
                              fontSize: 11,
                              color: admin.isSuperAdmin ? AppTheme.accent : AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: admin.isActive
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            admin.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              color: admin.isActive ? AppTheme.primary : AppTheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              if (onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') onDelete!();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete', child: Row(
                      children: [
                        Icon(Icons.delete, color: AppTheme.error, size: 20),
                        SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: AppTheme.error)),
                      ],
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

class _AdminFormSheet extends StatefulWidget {
  final Admin? admin;

  const _AdminFormSheet({this.admin});

  @override
  State<_AdminFormSheet> createState() => _AdminFormSheetState();
}

class _AdminFormSheetState extends State<_AdminFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _saving = false;

  bool get isEdit => widget.admin != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.admin?.name ?? '');
    _phoneController = TextEditingController(text: widget.admin?.phone ?? '');
    _emailController = TextEditingController(text: widget.admin?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    };
    if (_emailController.text.trim().isNotEmpty) {
      data['email'] = _emailController.text.trim();
    }

    final provider = context.read<AdminProvider>();
    final success = isEdit
        ? await provider.updateAdmin(widget.admin!.id, data)
        : await provider.createAdmin(data);

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar(isEdit ? 'Admin updated' : 'New admin added'),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(provider.error ?? 'Failed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
              const SizedBox(height: 20),
              Text(
                isEdit ? 'Edit Admin' : 'Add New Admin',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        prefixIcon: Icon(Icons.phone),
                        prefixText: '+91 ',
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.length != 10) return 'Enter 10-digit phone number';
                        if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Digits only';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                          return 'Enter valid email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CupertinoActivityIndicator())
                          : Text(isEdit ? 'Update' : 'Add'),
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
