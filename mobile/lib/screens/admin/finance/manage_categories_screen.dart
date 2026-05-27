import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
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
                        AppTheme.errorSnackBar(context.read<FinanceProvider>().error ?? 'Failed'),
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
            return const ListSkeletonLoader();
          }

          final incomeCategories = provider.categories.where((c) => c.type == 'income').toList();
          final expenseCategories = provider.categories.where((c) => c.type == 'expense').toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (incomeCategories.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Income Categories',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16)),
                ),
                ...incomeCategories.map((c) => _CategoryTile(category: c)),
              ],
              if (expenseCategories.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Expense Categories',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error, fontSize: 16)),
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
          backgroundColor: isIncome
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.errorContainer,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? AppTheme.primary : AppTheme.error,
            size: 20,
          ),
        ),
        title: Text(category.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showEditDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: category.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(99))),
                const SizedBox(height: 20),
                Text('Rename Category', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final newName = controller.text.trim();
                          if (newName.isEmpty || newName == category.name) return;
                          Navigator.pop(ctx);
                          final success = await context.read<FinanceProvider>().updateCategory(category.id, newName);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppTheme.errorSnackBar(context.read<FinanceProvider>().error ?? 'Failed'),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirm = await showAppSheet<bool>(
      context: context,
      title: 'Delete Category',
      initialChildSize: 0.3,
      body: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Are you sure? Categories with transactions cannot be deleted.'),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.error,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
    if (confirm == true && context.mounted) {
      final success = await context.read<FinanceProvider>().deleteCategory(category.id);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(context.read<FinanceProvider>().error ?? 'Cannot delete'),
        );
      }
    }
  }
}
