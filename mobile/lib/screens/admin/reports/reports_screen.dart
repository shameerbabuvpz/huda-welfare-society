import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _memberReport;
  Map<String, dynamic>? _assetReport;
  Map<String, dynamic>? _notifReport;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final results = await Future.wait([
        ApiService.get('/reports/members'),
        ApiService.get('/reports/assets'),
        ApiService.get('/reports/notifications'),
      ]);
      setState(() {
        _memberReport = results[0];
        _assetReport = results[1];
        _notifReport = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ReportCard(
                  title: 'Members',
                  icon: Icons.people,
                  color: AppTheme.primary,
                  items: _memberReport != null
                      ? {'Active': '${_memberReport!['active']}', 'Inactive': '${_memberReport!['inactive']}'}
                      : {},
                ),
                const SizedBox(height: 12),
                _ReportCard(
                  title: 'Assets',
                  icon: Icons.inventory,
                  color: AppTheme.accent,
                  items: _assetReport != null
                      ? {
                          'Available': '${_assetReport!['available']}',
                          'Issued': '${_assetReport!['issued']}',
                          'Overdue': '${_assetReport!['overdue']}',
                        }
                      : {},
                ),
                const SizedBox(height: 12),
                _ReportCard(
                  title: 'Notifications',
                  icon: Icons.notifications,
                  color: AppTheme.primaryDark,
                  items: _notifReport != null
                      ? {
                          'Total': '${_notifReport!['total_notifications']}',
                          'Sent': '${_notifReport!['sent']}',
                          'Failed': '${_notifReport!['failed']}',
                        }
                      : {},
                ),
              ],
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, String> items;

  const _ReportCard({required this.title, required this.icon, required this.color, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(),
            ...items.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: TextStyle(color: Colors.grey.shade600)),
                  Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
