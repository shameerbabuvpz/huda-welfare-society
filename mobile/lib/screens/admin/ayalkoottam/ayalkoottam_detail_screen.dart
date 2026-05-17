import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/ayalkoottam.dart';
import '../../../providers/ayalkoottam_provider.dart';
import '../../../providers/member_provider.dart';
import '../../../widgets/app_bottom_sheet.dart';

class AyalkoottamDetailScreen extends StatefulWidget {
  const AyalkoottamDetailScreen({super.key});

  @override
  State<AyalkoottamDetailScreen> createState() => _AyalkoottamDetailScreenState();
}

class _AyalkoottamDetailScreenState extends State<AyalkoottamDetailScreen> {
  late Ayalkoottam _ak;
  bool _membersLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ak = ModalRoute.of(context)!.settings.arguments as Ayalkoottam;
    if (!_membersLoaded) {
      _membersLoaded = true;
      Future.microtask(() {
        context.read<MemberProvider>().loadMembers(ayalkoottamId: _ak.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = context.watch<MemberProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_ak.name),
        actions: [
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
            ],
            onSelected: (v) {
              if (v == 'deactivate') _confirmDeactivate();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Master data card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Master Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _row('Place', _ak.place ?? 'N/A'),
                  _row('Status', _ak.status.toUpperCase()),
                  _row('Members', '${_ak.memberCount ?? 0}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Members in this ayalkoottam
          const Text('Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (memberProvider.loading)
            const Center(child: CircularProgressIndicator())
          else if (memberProvider.members.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No members in this ayalkoottam'))))
          else
            ...memberProvider.members.map((m) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(m.name[0].toUpperCase())),
                title: Text(m.name),
                subtitle: Text('${m.memberCode} • ${m.phone ?? ''}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: m.status == 'active'
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    m.status,
                    style: TextStyle(fontSize: 12, color: m.status == 'active' ? AppTheme.primary : AppTheme.error),
                  ),
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _confirmDeactivate() {
    showAppSheet(
      context: context,
      title: 'Deactivate',
      initialChildSize: 0.3,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Deactivate "${_ak.name}"?'),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
          onPressed: () async {
            Navigator.pop(context);
            await context.read<AyalkoottamProvider>().deactivate(_ak.id);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Deactivate'),
        ),
      ],
    );
  }
}
