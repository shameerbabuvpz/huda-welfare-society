import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/member_provider.dart';
import '../../../providers/ayalkoottam_provider.dart';
import '../../../services/member_service.dart';
import '../../../utils/ak_name_helper.dart';
import '../../../widgets/app_bottom_sheet.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _saving = false;
  int? _selectedAyalkoottamId;
  String? _designation; // null, 'president', or 'secretary'

  @override
  void initState() {
    super.initState();
    context.read<AyalkoottamProvider>().loadDropdown();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final memberProvider = context.read<MemberProvider>();
    if (_selectedAyalkoottamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar('Select an Ayalkoottam'),
      );
      return;
    }

    // Check if designation is already taken
    if (_designation != null) {
      final check = await MemberService.checkDesignation(_selectedAyalkoottamId!, _designation!);
      if (check != null && mounted) {
        final proceed = await showAppSheet<bool>(
          context: context,
          title: '${_designation == 'president' ? 'President' : 'Secretary'} already exists',
          initialChildSize: 0.3,
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('$check is currently the $_designation. Replace?'),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
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
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        );
        if (proceed != true) return;
      }
    }

    setState(() => _saving = true);

    final data = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      if (_addressController.text.isNotEmpty) 'address': _addressController.text.trim(),
      'ayalkoottam_id': _selectedAyalkoottamId,
      if (_designation != null) 'designation': _designation,
    };

    final success = await memberProvider.createMember(data);
    setState(() => _saving = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.successSnackBar('Member added'));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(memberProvider.error ?? 'Failed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ayalkoottam dropdown
              Consumer<AyalkoottamProvider>(
                builder: (ctx, akProvider, _) {
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Ayalkoottam *', prefixIcon: Icon(Icons.groups_2)),
                    value: _selectedAyalkoottamId,
                    isExpanded: true,
                    items: akProvider.dropdownList.map((ak) {
                      return DropdownMenuItem(value: ak.id, child: Text(shortAkName(ak.name), overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) => setState(() {
                      _selectedAyalkoottamId = v;
                      _designation = null;
                    }),
                    validator: (v) => v == null ? 'Select an Ayalkoottam' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.person)),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),

              // Phone (10 digits only)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Mobile Number (10 digits) *', prefixIcon: Icon(Icons.phone), counterText: ''),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Must be exactly 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address (optional)
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Address (optional)', prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 24),

              // Designation section
              const Text('Designation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('President'),
                      value: _designation == 'president',
                      onChanged: (v) => setState(() => _designation = v == true ? 'president' : null),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Secretary'),
                      value: _designation == 'secretary',
                      onChanged: (v) => setState(() => _designation = v == true ? 'secretary' : null),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Add Member'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
