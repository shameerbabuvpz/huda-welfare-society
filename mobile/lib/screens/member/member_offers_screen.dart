import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/privilege_offer.dart';
import '../../services/privilege_offer_service.dart';

class MemberOffersScreen extends StatefulWidget {
  const MemberOffersScreen({super.key});

  @override
  State<MemberOffersScreen> createState() => _MemberOffersScreenState();
}

class _MemberOffersScreenState extends State<MemberOffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<PrivilegeOffer> _offers = [];
  List<PrivilegeRedemption> _redemptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        PrivilegeOfferService.listActive(),
        PrivilegeOfferService.myRedemptions(),
      ]);
      _offers = results[0] as List<PrivilegeOffer>;
      _redemptions = results[1] as List<PrivilegeRedemption>;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _scanQr() async {
    // Show a dialog to enter QR code manually (since web doesn't support camera)
    // On mobile, you'd use a QR scanner package
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Scan Privilege QR'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scan the QR code at the partner shop or enter the code manually:'),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'QR Code',
                  hintText: 'PO-XXXXXXXXXX',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Redeem')),
          ],
        );
      },
    );

    if (code == null || code.isEmpty) return;

    // Try to parse if it's a JSON QR payload
    String qrCode = code;
    try {
      final parsed = jsonDecode(code);
      if (parsed is Map && parsed['code'] != null) {
        qrCode = parsed['code'];
      }
    } catch (_) {
      // plain code string
    }

    try {
      final redemption = await PrivilegeOfferService.redeem(qrCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Redeemed at ${redemption.companyName}!'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privilege Offers'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Available Offers'),
            Tab(text: 'My Redemptions'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanQr,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildOffersList(),
                    _buildRedemptionsList(),
                  ],
                ),
    );
  }

  Widget _buildOffersList() {
    if (_offers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No offers available', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return _MemberOfferCard(offer: offer);
        },
      ),
    );
  }

  Widget _buildRedemptionsList() {
    if (_redemptions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No redemptions yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 4),
            Text('Scan a QR at a partner shop to get started!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _redemptions.length,
        itemBuilder: (context, index) {
          final r = _redemptions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: Icon(Icons.check_circle, color: Colors.green.shade700),
              ),
              title: Text(r.companyName ?? 'Partner'),
              subtitle: Text(
                r.redeemedAt != null
                    ? '${r.redeemedAt!.day}/${r.redeemedAt!.month}/${r.redeemedAt!.year}'
                    : 'Redeemed',
              ),
              trailing: Text(
                _redemptionLabel(r),
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
            ),
          );
        },
      ),
    );
  }

  String _redemptionLabel(PrivilegeRedemption r) {
    if (r.offerType == 'percentage' && r.offerValue != null) {
      return '${r.offerValue!.toInt()}% Off';
    } else if (r.offerType == 'flat' && r.offerValue != null) {
      return '₹${r.offerValue!.toInt()} Off';
    }
    return 'Free';
  }
}

class _MemberOfferCard extends StatelessWidget {
  final PrivilegeOffer offer;
  const _MemberOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOfferDetail(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              if (offer.logoUrl != null && offer.logoUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(offer.logoUrl!),
                  backgroundColor: Colors.grey.shade100,
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _offerBadge(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.companyName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (offer.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        offer.description!,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _offerBadge() {
    if (offer.offerType == 'percentage' && offer.offerValue != null) {
      return '${offer.offerValue!.toInt()}%\nOFF';
    } else if (offer.offerType == 'flat' && offer.offerValue != null) {
      return '₹${offer.offerValue!.toInt()}\nOFF';
    }
    return 'FREE';
  }

  void _showOfferDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              offer.companyName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _offerBadge().replaceAll('\n', ' '),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ),
            if (offer.description != null) ...[
              const SizedBox(height: 16),
              Text(offer.description!, style: const TextStyle(fontSize: 15, height: 1.5)),
            ],
            if (offer.termsAndConditions != null && offer.termsAndConditions!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Terms & Conditions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(offer.termsAndConditions!, style: const TextStyle(height: 1.5)),
              ),
            ],
            if (offer.contactPhone != null) ...[
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.phone, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(offer.contactPhone!),
              ]),
            ],
            const SizedBox(height: 24),
            const Text(
              'Visit the shop and scan the QR code to redeem this offer!',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
