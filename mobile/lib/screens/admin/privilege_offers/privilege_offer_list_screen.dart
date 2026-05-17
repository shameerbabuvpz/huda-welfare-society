import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/privilege_offer.dart';
import '../../../providers/privilege_offer_provider.dart';
import 'privilege_offer_form_screen.dart';
import 'privilege_offer_detail_screen.dart';

class PrivilegeOfferListScreen extends StatefulWidget {
  const PrivilegeOfferListScreen({super.key});

  @override
  State<PrivilegeOfferListScreen> createState() => _PrivilegeOfferListScreenState();
}

class _PrivilegeOfferListScreenState extends State<PrivilegeOfferListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PrivilegeOfferProvider>().loadOffers());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrivilegeOfferProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Privilege Card Offers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const PrivilegeOfferFormScreen()),
          );
          if (created == true && mounted) {
            context.read<PrivilegeOfferProvider>().loadOffers();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Offer'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : provider.offers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No offers yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('Add partner companies & their offers', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.loadOffers(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.offers.length,
                        itemBuilder: (context, index) {
                          final offer = provider.offers[index];
                          return _OfferCard(offer: offer);
                        },
                      ),
                    ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final PrivilegeOffer offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final isActive = offer.status == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PrivilegeOfferDetailScreen(offerId: offer.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _offerLabel(offer),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.companyName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    if (offer.description != null)
                      Text(
                        offer.description!,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.qr_code_scanner, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${offer.redemptionCount} redemptions',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _offerLabel(PrivilegeOffer offer) {
    if (offer.offerType == 'percentage' && offer.offerValue != null) {
      return '${offer.offerValue!.toInt()}%';
    } else if (offer.offerType == 'flat' && offer.offerValue != null) {
      return '₹${offer.offerValue!.toInt()}';
    }
    return 'FREE';
  }
}
