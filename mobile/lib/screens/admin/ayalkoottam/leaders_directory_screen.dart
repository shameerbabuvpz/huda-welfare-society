import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../../services/ayalkoottam_service.dart';
import '../../../services/export_service.dart';
import '../../../utils/ak_name_helper.dart';

/// Admin view: every ayalkoottam with its president & secretary (name, id,
/// mobile), with PDF/Excel export.
class LeadersDirectoryScreen extends StatefulWidget {
  const LeadersDirectoryScreen({super.key});

  @override
  State<LeadersDirectoryScreen> createState() => _LeadersDirectoryScreenState();
}

class _LeadersDirectoryScreenState extends State<LeadersDirectoryScreen> {
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  List<AyalkoottamLeaders> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final rows = await AyalkoottamService.leaders();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _export(bool pdf) async {
    setState(() => _exporting = true);
    try {
      if (pdf) {
        await ExportService.leadersPdf();
      } else {
        await ExportService.leadersExcel();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place a call to $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('President & Secretary'),
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              tooltip: 'Export',
              onSelected: (v) => _export(v == 'pdf'),
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: 'excel',
                  child: ListTile(
                    leading: Icon(Icons.table_chart, color: AppTheme.success),
                    title: Text('Export Excel'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf, color: AppTheme.error),
                    title: Text('Export PDF'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_rows.isEmpty) {
      return const Center(child: Text('No ayalkoottams found'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _rows.length,
        itemBuilder: (context, i) => _LeadersCard(row: _rows[i], onCall: _makeCall),
      ),
    );
  }
}

class _LeadersCard extends StatelessWidget {
  const _LeadersCard({required this.row, required this.onCall});

  final AyalkoottamLeaders row;
  final Future<void> Function(String phone) onCall;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_2, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shortAkName(row.ayalkoottamName),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            _RoleRow(
              role: 'President',
              roleColor: AppTheme.accent,
              name: row.presidentName,
              code: row.presidentCode,
              phone: row.presidentPhone,
              onCall: onCall,
            ),
            const SizedBox(height: 8),
            _RoleRow(
              role: 'Secretary',
              roleColor: AppTheme.primary,
              name: row.secretaryName,
              code: row.secretaryCode,
              phone: row.secretaryPhone,
              onCall: onCall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.roleColor,
    required this.name,
    required this.code,
    required this.phone,
    required this.onCall,
  });

  final String role;
  final Color roleColor;
  final String name;
  final String code;
  final String phone;
  final Future<void> Function(String phone) onCall;

  @override
  Widget build(BuildContext context) {
    final hasPerson = name.isNotEmpty;
    final hasPhone = phone.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 74,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            role,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: roleColor),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: hasPerson
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      'ID: ${code.isEmpty ? '-' : code}'
                      '${hasPhone ? '  ·  $phone' : ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                )
              : const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text('Not assigned', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ),
        ),
        if (hasPhone)
          IconButton(
            icon: const Icon(Icons.call, size: 20, color: AppTheme.success),
            tooltip: 'Call $name',
            onPressed: () => onCall(phone),
          ),
      ],
    );
  }
}
