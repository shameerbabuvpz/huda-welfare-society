import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
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

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 70);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _logoBytes = bytes;
      _logoFilename = picked.name;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 70);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageFilename = picked.name;
    });
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
        await provider.updateOffer(
          widget.offerId!,
          data,
          logoBytes: _logoBytes,
          logoFilename: _logoFilename,
          imageBytes: _imageBytes,
          imageFilename: _imageFilename,
        );
      } else {
        await provider.createOffer(
          data,
          logoBytes: _logoBytes,
          logoFilename: _logoFilename,
          imageBytes: _imageBytes,
          imageFilename: _imageFilename,
        );
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
              // Logo picker
              _buildImagePicker(
                label: 'Company Logo',
                icon: Icons.business,
                bytes: _logoBytes,
                existingUrl: _existingLogoUrl,
                onPick: _pickLogo,
                onClear: () => setState(() { _logoBytes = null; _logoFilename = null; }),
                isCircle: true,
              ),
              const SizedBox(height: 16),
              // Promo image picker
              _buildImagePicker(
                label: 'Promotional Image',
                icon: Icons.image,
                bytes: _imageBytes,
                existingUrl: _existingImageUrl,
                onPick: _pickImage,
                onClear: () => setState(() { _imageBytes = null; _imageFilename = null; }),
                isCircle: false,
              ),
              const SizedBox(height: 20),
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
                initialValue: _offerType,
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
                initialValue: _status,
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
                    ? const SizedBox(width: 18, height: 18, child: CupertinoActivityIndicator())
                    : const Icon(Icons.save),
                label: Text(_isEdit ? 'Update Offer' : 'Create Offer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required IconData icon,
    required Uint8List? bytes,
    required String? existingUrl,
    required VoidCallback onPick,
    required VoidCallback onClear,
    required bool isCircle,
  }) {
    final hasImage = bytes != null || (existingUrl != null && existingUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: onPick,
              child: Container(
                width: isCircle ? 80 : 120,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: isCircle ? null : BorderRadius.circular(12),
                  shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                  border: Border.all(color: Colors.grey.shade300),
                  image: bytes != null
                      ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                      : existingUrl != null && existingUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(existingUrl), fit: BoxFit.cover)
                          : null,
                ),
                child: !hasImage
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: Colors.grey.shade400, size: 28),
                          const SizedBox(height: 4),
                          Text('Upload', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      )
                    : null,
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 12),
              Column(
                children: [
                  TextButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change'),
                  ),
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 16, color: AppTheme.error),
                    label: const Text('Remove', style: TextStyle(color: AppTheme.error)),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('Choose File'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
