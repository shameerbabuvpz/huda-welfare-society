import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/finance_provider.dart';
import '../../../widgets/app_bottom_sheet.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().loadCategories();
    });
  }

  void _showAddDialog() {
    String name = '';
    String type = 'income';

    showAppBottomSheet(
      context: context,
      title: 'Add Category',
      initialChildSize: 0.4,
      bodyBuilder: (ctx, sc) => StatefulBuilder(
        builder: (ctx, setSheetState) => SingleChildScrollView(
          controller: sc,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'income', label: Text('Income')),
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                ],
                selected: {type},
                onSelectionChanged: (val) => setSheetState(() => type = val.first),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    if (name.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    final success = await context.read<FinanceProvider>().createCategory(name.trim(), type);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.read<FinanceProvider>().error ?? 'Failed')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
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
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final incomeCategories = provider.categories.where((c) => c.type == 'income').toList();
          final expenseCategories = provider.categories.where((c) => c.type == 'expense').toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (incomeCategories.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Income Categories',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700], fontSize: 16)),
                ),
                ...incomeCategories.map((c) => _CategoryTile(category: c)),
              ],
              if (expenseCategories.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Expense Categories',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700], fontSize: 16)),
                ),
                ...expenseCategories.map((c) => _CategoryTile(category: c)),
              ],
              if (incomeCategories.isEmpty && expenseCategories.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No categories yet. Tap + to add.'),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final dynamic category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final isIncome = category.type == 'income';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(category.name),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final confirm = await showAppSheet<bool>(
              context: context,
              title: 'Delete Category',
              initialChildSize: 0.3,
              body: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Are you sure? Categories with transactions cannot be deleted.'),
              ),
              actions: [
                OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
            if (confirm == true && context.mounted) {
              final success = await context.read<FinanceProvider>().deleteCategory(category.id);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.read<FinanceProvider>().error ?? 'Cannot delete')),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
