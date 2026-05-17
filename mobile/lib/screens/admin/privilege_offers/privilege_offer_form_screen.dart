import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/privilege_offer_provider.dart';

class PrivilegeOfferFormScreen extends StatefulWidget {
  final int? offerId;
  final Map<String, dynamic>? initialData;

  const PrivilegeOfferFormScreen({super.key, this.offerId, this.initialData});

  @override
  State<PrivilegeOfferFormScreen> createState() => _PrivilegeOfferFormScreenState();
}

class _PrivilegeOfferFormScreenState extends State<PrivilegeOfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _offerValueCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _offerType = 'percentage';
  String _status = 'active';
  bool _saving = false;

  // Image state
  Uint8List? _logoBytes;
  String? _logoFilename;
  Uint8List? _imageBytes;
  String? _imageFilename;
  String? _existingLogoUrl;
  String? _existingImageUrl;

  bool get _isEdit => widget.offerId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _companyNameCtrl.text = d['company_name'] ?? '';
      _descriptionCtrl.text = d['description'] ?? '';
      _offerValueCtrl.text = d['offer_value']?.toString() ?? '';
      _termsCtrl.text = d['terms_and_conditions'] ?? '';
      _phoneCtrl.text = d['contact_phone'] ?? '';
      _emailCtrl.text = d['contact_email'] ?? '';
      _offerType = d['offer_type'] ?? 'percentage';
      _status = d['status'] ?? 'active';
      _existingLogoUrl = d['logo_url'];
      _existingImageUrl = d['image_url'];
    }
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _offerValueCtrl.dispose();
    _termsCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'company_name': _companyNameCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
      'offer_type': _offerType,
      'offer_value': double.tryParse(_offerValueCtrl.text.trim()),
      'terms_and_conditions': _termsCtrl.text.trim().isNotEmpty ? _termsCtrl.text.trim() : null,
      'contact_phone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      'contact_email': _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      'status': _status,
    };

    try {
      final provider = context.read<PrivilegeOfferProvider>();
      if (_isEdit) {
        await provider.updateOffer(widget.offerId!, data);
      } else {
        await provider.createOffer(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Offer' : 'Add Privilege Offer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _companyNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company / Shop Name *',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _offerType,
                decoration: const InputDecoration(
                  labelText: 'Offer Type',
                  prefixIcon: Icon(Icons.local_offer),
                ),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                  DropdownMenuItem(value: 'flat', child: Text('Flat Amount (₹)')),
                  DropdownMenuItem(value: 'freebie', child: Text('Freebie / Gift')),
                ],
                onChanged: (v) => setState(() => _offerType = v!),
              ),
              const SizedBox(height: 16),
              if (_offerType != 'freebie')
                TextFormField(
                  controller: _offerValueCtrl,
                  decoration: InputDecoration(
                    labelText: _offerType == 'percentage' ? 'Discount %' : 'Discount ₹',
                    prefixIcon: const Icon(Icons.percent),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (_offerType == 'freebie') return null;
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
              if (_offerType != 'freebie') const SizedBox(height: 16),
              TextFormField(
                controller: _termsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Terms & Conditions',
                  prefixIcon: Icon(Icons.rule),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.toggle_on),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isEdit ? 'Update Offer' : 'Create Offer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
