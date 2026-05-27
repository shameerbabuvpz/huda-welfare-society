import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../services/export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _memberReport;
  Map<String, dynamic>? _assetReport;
  Map<String, dynamic>? _notifReport;
  List<dynamic> _ayalkoottams = [];
  List<dynamic> _kuriGroups = [];
  bool _loading = true;
  bool _exporting = false;

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
        ApiService.get('/ayalkoottams'),
        ApiService.get('/kuri'),
      ]);
      setState(() {
        _memberReport = results[0];
        _assetReport = results[1];
        _notifReport = results[2];
        _ayalkoottams = (results[3] is Map && results[3]['data'] != null)
            ? results[3]['data'] as List
            : (results[3] is List ? results[3] : []);
        _kuriGroups = (results[4] is Map && results[4]['data'] != null)
            ? results[4]['data'] as List
            : (results[4] is List ? results[4] : []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _doExport(Future<void> Function() action) async {
    setState(() { _exporting = true; });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showMemberExportSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Export Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('All Members - Excel'),
                onTap: () { Navigator.pop(ctx); _doExport(() => ExportService.membersExcel()); },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('All Members - PDF'),
                onTap: () { Navigator.pop(ctx); _doExport(() => ExportService.membersPdf()); },
              ),
              if (_ayalkoottams.isNotEmpty) ...[
                const Divider(),
                const Text('By Ayalkoottam:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    itemCount: _ayalkoottams.length,
                    itemBuilder: (_, i) {
                      final ak = _ayalkoottams[i];
                      final id = ak['id'];
                      final name = ak['name'] ?? 'Ayalkoottam $id';
                      return ListTile(
                        dense: true,
                        title: Text(name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.table_chart, size: 20, color: Colors.green),
                              tooltip: 'Excel',
                              onPressed: () { Navigator.pop(ctx); _doExport(() => ExportService.membersExcel(ayalkoottamId: id)); },
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
                              tooltip: 'PDF',
                              onPressed: () { Navigator.pop(ctx); _doExport(() => ExportService.membersPdf(ayalkoottamId: id)); },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showKuriExportSheet() {
    if (_kuriGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No kuri groups available')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Export Kuri Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ..._kuriGroups.map((g) {
                final id = g['id'];
                final name = g['name'] ?? 'Kuri $id';
                return ListTile(
                  title: Text(name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.table_chart, size: 20, color: Colors.green),
                        tooltip: 'Excel',
                        onPressed: () { Navigator.pop(ctx); _doExport(() => ExportService.kuriExcel(id)); },
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
                        tooltip: 'PDF',
                        onPressed: () { Navigator.pop(ctx); _doExport(() => ExportService.kuriPdf(id)); },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinanceExportSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Export Finance Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Finance - Excel'),
                onTap: () { Navigator.pop(ctx); _doExport(() => ExportService.financeExcel()); },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Finance - PDF'),
                onTap: () { Navigator.pop(ctx); _doExport(() => ExportService.financePdf()); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Export')),
      body: _loading
          ? const ListSkeletonLoader()
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Summary Cards ──
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
                    const SizedBox(height: 24),

                    // ── Export Section ──
                    const Text('Export Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _ExportTile(
                      icon: Icons.people,
                      color: AppTheme.primary,
                      title: 'Members',
                      subtitle: 'Export all or by ayalkoottam',
                      onTap: _showMemberExportSheet,
                    ),
                    _ExportTile(
                      icon: Icons.account_balance,
                      color: Colors.indigo,
                      title: 'Kuri Report',
                      subtitle: 'Collections & payouts per group',
                      onTap: _showKuriExportSheet,
                    ),
                    _ExportTile(
                      icon: Icons.volunteer_activism,
                      color: Colors.teal,
                      title: 'Kaneev Report',
                      subtitle: 'Donations & balance history',
                      onTap: () => _showFormatPicker(
                        'Kaneev Report',
                        onExcel: () => _doExport(() => ExportService.kaneevExcel()),
                        onPdf: () => _doExport(() => ExportService.kaneevPdf()),
                      ),
                    ),
                    _ExportTile(
                      icon: Icons.account_balance_wallet,
                      color: Colors.deepOrange,
                      title: 'Finance / Balance Sheet',
                      subtitle: 'Income, expense & balance',
                      onTap: _showFinanceExportSheet,
                    ),
                  ],
                ),
                if (_exporting)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoActivityIndicator(),
                              SizedBox(height: 16),
                              Text('Generating report...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showFormatPicker(String title, {required VoidCallback onExcel, required VoidCallback onPdf}) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Excel (.xlsx)'),
                onTap: () { Navigator.pop(ctx); onExcel(); },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF'),
                onTap: () { Navigator.pop(ctx); onPdf(); },
              ),
            ],
          ),
        ),
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

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.download_rounded),
        onTap: onTap,
      ),
    );
  }
}
