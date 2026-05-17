import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme.dart';
import '../../../models/privilege_offer.dart';
import '../../../providers/privilege_offer_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/app_bottom_sheet.dart';
import 'privilege_offer_form_screen.dart';

class PrivilegeOfferDetailScreen extends StatefulWidget {
  final int offerId;
  const PrivilegeOfferDetailScreen({super.key, required this.offerId});

  @override
  State<PrivilegeOfferDetailScreen> createState() => _PrivilegeOfferDetailScreenState();
}

class _PrivilegeOfferDetailScreenState extends State<PrivilegeOfferDetailScreen> {
  PrivilegeOffer? _offer;
  List<PrivilegeRedemption> _redemptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.get('/privilege-offers/${widget.offerId}');
      _offer = PrivilegeOffer.fromJson(data);
      if (data['redemptions'] != null) {
        _redemptions = (data['redemptions'] as List)
            .map((e) => PrivilegeRedemption.fromJson(e))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleStatus() async {
    if (_offer == null) return;
    final newStatus = _offer!.status == 'active' ? 'inactive' : 'active';
    final provider = context.read<PrivilegeOfferProvider>();
    try {
      await provider.updateOffer(widget.offerId, {'status': newStatus});
      if (!mounted) return;
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(AppTheme.errorSnackBar(e.toString()));
    }
  }

  Future<void> _deleteOffer() async {
    final confirm = await showConfirmSheet(
      context: context,
      title: 'Delete Offer?',
      message: 'This action cannot be undone. The privilege offer will be permanently removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirm != true) return;
    if (!mounted) return;
    final provider = context.read<PrivilegeOfferProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await provider.deleteOffer(widget.offerId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(AppTheme.errorSnackBar(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_offer?.companyName ?? 'Offer Details'),
        actions: [
          if (_offer != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _edit();
                if (v == 'toggle') _toggleStatus();
                if (v == 'delete') _deleteOffer();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(_offer!.status == 'active' ? 'Deactivate' : 'Activate'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.error))),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _offer == null
                  ? const Center(child: Text('Not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildOfferCard(),
                          const SizedBox(height: 20),
                          _buildQrSection(),
                          const SizedBox(height: 20),
                          if (_offer!.termsAndConditions != null && _offer!.termsAndConditions!.isNotEmpty) ...[
                            _buildTermsSection(),
                            const SizedBox(height: 20),
                          ],
                          _buildRedemptionsSection(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildOfferCard() {
    final offer = _offer!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner image
          if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
            Image.network(
              offer.imageUrl!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (offer.logoUrl != null && offer.logoUrl!.isNotEmpty) ...[
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(offer.logoUrl!),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(offer.companyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: offer.status == 'active'
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        offer.status == 'active' ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: offer.status == 'active' ? AppTheme.primary : AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (offer.description != null) ...[
                  const SizedBox(height: 8),
                  Text(offer.description!, style: TextStyle(color: Colors.grey.shade700)),
                ],
                const Divider(height: 24),
                Row(
                  children: [
                    _InfoChip(icon: Icons.local_offer, label: _offerLabel(offer)),
                    const SizedBox(width: 12),
                    _InfoChip(icon: Icons.qr_code_scanner, label: '${offer.redemptionCount} used'),
                  ],
                ),
                if (offer.contactPhone != null || offer.contactEmail != null) ...[
                  const SizedBox(height: 12),
                  if (offer.contactPhone != null)
                    Row(children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(offer.contactPhone!, style: const TextStyle(fontSize: 13)),
                    ]),
                  if (offer.contactEmail != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.email, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(offer.contactEmail!, style: const TextStyle(fontSize: 13)),
                    ]),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    final offer = _offer!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('QR Code for Shop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Print this and display at the partner shop',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (offer.qrData != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Image.memory(
                  base64Decode(offer.qrData!.split(',').last),
                  width: 200,
                  height: 200,
                ),
              )
            else
              const Text('QR not available'),
            const SizedBox(height: 12),
            Text(
              'Code: ${offer.qrCode}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'monospace'),
            ),
            if (offer.qrData != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _downloadQr(offer),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _shareQr(offer),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rule, size: 20),
                SizedBox(width: 8),
                Text('Terms & Conditions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(_offer!.termsAndConditions!, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildRedemptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Redemptions (${_redemptions.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (_redemptions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No redemptions yet', style: TextStyle(color: Colors.grey))),
            ),
          )
        else
          ...List.generate(_redemptions.length, (i) {
            final r = _redemptions[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primary)),
                ),
                title: Text(r.memberName ?? 'Member'),
                subtitle: Text(r.memberCode ?? ''),
                trailing: Text(
                  r.redeemedAt != null
                      ? '${r.redeemedAt!.day}/${r.redeemedAt!.month}/${r.redeemedAt!.year}'
                      : '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            );
          }),
      ],
    );
  }

  void _edit() async {
    if (_offer == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PrivilegeOfferFormScreen(
          offerId: widget.offerId,
          initialData: {
            'company_name': _offer!.companyName,
            'description': _offer!.description,
            'offer_type': _offer!.offerType,
            'offer_value': _offer!.offerValue,
            'terms_and_conditions': _offer!.termsAndConditions,
            'contact_phone': _offer!.contactPhone,
            'contact_email': _offer!.contactEmail,
            'logo_url': _offer!.logoUrl,
            'image_url': _offer!.imageUrl,
            'status': _offer!.status,
          },
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  Uint8List _qrBytes(PrivilegeOffer offer) {
    return base64Decode(offer.qrData!.split(',').last);
  }

  Future<void> _downloadQr(PrivilegeOffer offer) async {
    try {
      final bytes = _qrBytes(offer);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/qr_${offer.companyName.replaceAll(' ', '_')}.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar('QR saved to ${file.path}'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar('Failed to save QR: $e'),
      );
    }
  }

  Future<void> _shareQr(PrivilegeOffer offer) async {
    try {
      final bytes = _qrBytes(offer);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr_${offer.companyName.replaceAll(' ', '_')}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${offer.companyName} - Privilege Offer QR Code',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar('Failed to share QR: $e'),
      );
    }
  }

  String _offerLabel(PrivilegeOffer offer) {
    if (offer.offerType == 'percentage' && offer.offerValue != null) {
      return '${offer.offerValue!.toInt()}% Off';
    } else if (offer.offerType == 'flat' && offer.offerValue != null) {
      return '₹${offer.offerValue!.toInt()} Off';
    }
    return 'Free Gift';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.ink.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 13, color: AppTheme.ink.withValues(alpha: 0.78))),
        ],
      ),
    );
  }
}
