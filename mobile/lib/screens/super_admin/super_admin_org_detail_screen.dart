import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/organization.dart';
import '../../services/organization_service.dart';

class SuperAdminOrgDetailScreen extends StatefulWidget {
  final int orgId;
  const SuperAdminOrgDetailScreen({super.key, required this.orgId});

  @override
  State<SuperAdminOrgDetailScreen> createState() => _SuperAdminOrgDetailScreenState();
}

class _SuperAdminOrgDetailScreenState extends State<SuperAdminOrgDetailScreen> {
  Organization? _org;
  List<Map<String, dynamic>> _admins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final org = await OrganizationService.getById(widget.orgId);
      final admins = await OrganizationService.listAdmins(widget.orgId);
      setState(() {
        _org = org;
        _admins = admins;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      final filename = picked.name.isNotEmpty ? picked.name : 'logo.png';
      await OrganizationService.uploadLogo(widget.orgId, bytes, filename);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editOrg() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _EditOrgDialog(org: _org!),
    );
    if (result == null) return;

    try {
      await OrganizationService.update(widget.orgId, result);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addAdmin() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _AddAdminDialog(),
    );
    if (result == null) return;

    try {
      await OrganizationService.addAdmin(
        widget.orgId,
        phone: result['phone']!,
        name: result['name'],
      );
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin added'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_org?.name ?? 'Organization'),
        actions: [
          if (_org != null) IconButton(icon: const Icon(Icons.edit), onPressed: _editOrg),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo section
                  Center(
                    child: GestureDetector(
                      onTap: _uploadLogo,
                      child: Column(
                        children: [
                          _org?.logoUrl != null
                              ? CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(_org!.logoUrl!),
                                )
                              : const CircleAvatar(
                                  radius: 50,
                                  child: Icon(Icons.business, size: 40),
                                ),
                          const SizedBox(height: 8),
                          const Text('Tap to change logo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Org info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_org!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          if (_org!.place != null && _org!.place!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(_org!.place!, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(_org!.status),
                            backgroundColor: _org!.status == 'active' ? Colors.green.shade50 : Colors.red.shade50,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Admins section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Admins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _addAdmin,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Admin'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_admins.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No admins yet. Add one to manage this organization.'),
                      ),
                    )
                  else
                    ..._admins.map((admin) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(admin['name'] ?? 'Admin'),
                        subtitle: Text(admin['phone'] ?? ''),
                      ),
                    )),
                ],
              ),
            ),
    );
  }
}

class _EditOrgDialog extends StatefulWidget {
  final Organization org;
  const _EditOrgDialog({required this.org});

  @override
  State<_EditOrgDialog> createState() => _EditOrgDialogState();
}

class _EditOrgDialogState extends State<_EditOrgDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _placeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.org.name);
    _placeController = TextEditingController(text: widget.org.place ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Organization'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _placeController,
            decoration: const InputDecoration(labelText: 'Place'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'place': _placeController.text.trim(),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AddAdminDialog extends StatefulWidget {
  const _AddAdminDialog();

  @override
  State<_AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<_AddAdminDialog> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Admin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone (10 digits) *', prefixText: '+91 '),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_phoneController.text.trim().length != 10) return;
            Navigator.pop(context, {
              'phone': _phoneController.text.trim(),
              'name': _nameController.text.trim(),
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
