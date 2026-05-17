import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/asset.dart';
import '../../services/asset_service.dart';

class MyAssetsScreen extends StatefulWidget {
  const MyAssetsScreen({super.key});

  @override
  State<MyAssetsScreen> createState() => _MyAssetsScreenState();
}

class _MyAssetsScreenState extends State<MyAssetsScreen> {
  List<AssetTransaction> _assets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _assets = await AssetService.myAssets();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Equipments')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No health equipments issued', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _assets.length,
                  itemBuilder: (ctx, i) {
                    final a = _assets[i];
                    final isOverdue = a.dueDate != null && DateTime.tryParse(a.dueDate!)?.isBefore(DateTime.now()) == true;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isOverdue
                              ? Theme.of(context).colorScheme.errorContainer
                              : Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.inventory, color: isOverdue ? AppTheme.error : AppTheme.primary),
                        ),
                        title: Text(a.assetName ?? 'Asset'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Code: ${a.assetCode ?? ''}'),
                            Text('Issued: ${a.issueDate}'),
                            if (a.dueDate != null) Text('Due: ${a.dueDate}', style: TextStyle(color: isOverdue ? AppTheme.error : null)),
                          ],
                        ),
                        trailing: isOverdue
                            ? const Chip(label: Text('OVERDUE', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: AppTheme.error)
                            : Chip(
                                label: const Text('ISSUED', style: TextStyle(fontSize: 10)),
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
