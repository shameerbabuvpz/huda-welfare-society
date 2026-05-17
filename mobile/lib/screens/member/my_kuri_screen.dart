import 'package:flutter/material.dart';
import '../../models/kuri_group.dart';
import '../../services/kuri_service.dart';

class MyKuriScreen extends StatefulWidget {
  const MyKuriScreen({super.key});

  @override
  State<MyKuriScreen> createState() => _MyKuriScreenState();
}

class _MyKuriScreenState extends State<MyKuriScreen> {
  List<KuriPaymentStatus> _kuriList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _kuriList = await KuriService.myKuri();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Kuri')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _kuriList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Not enrolled in any kuri', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _kuriList.length,
                  itemBuilder: (ctx, i) => _KuriCard(status: _kuriList[i]),
                ),
    );
  }
}

class _KuriCard extends StatelessWidget {
  final KuriPaymentStatus status;
  const _KuriCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(status.group['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (status.hasWon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('Won Month ${status.winMonth}', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('₹${status.group['monthly_amount']}/month • Slot ${status.slotNumber ?? '-'}',
                style: TextStyle(color: Colors.grey.shade600)),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('${status.paidMonths.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      const Text('Paid', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('${status.pendingMonths.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                      const Text('Pending', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            if (status.pendingMonths.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Pending months: ${status.pendingMonths.join(', ')}', style: TextStyle(fontSize: 12, color: Colors.red.shade300)),
            ],
          ],
        ),
      ),
    );
  }
}
