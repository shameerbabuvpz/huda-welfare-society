import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/finance_provider.dart';
import '../../../models/finance.dart';
import 'add_transaction_screen.dart';
import 'manage_categories_screen.dart';
import '../../../widgets/app_bottom_sheet.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FinanceProvider>();
      provider.loadTransactions();
      provider.loadSummary();
      provider.loadCategories();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final provider = context.read<FinanceProvider>();
      switch (_tabController.index) {
        case 0:
          provider.loadTransactions();
          break;
        case 1:
          provider.loadTransactions(type: 'income');
          break;
        case 2:
          provider.loadTransactions(type: 'expense');
          break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income & Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Manage Categories',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(child: Text('All', maxLines: 2, textAlign: TextAlign.center)),
            Tab(child: Text('Income', maxLines: 2, textAlign: TextAlign.center)),
            Tab(child: Text('Expense', maxLines: 2, textAlign: TextAlign.center)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _TransactionList(type: null),
                _TransactionList(type: 'income'),
                _TransactionList(type: 'expense'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = context.read<FinanceProvider>();
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (result != true || !context.mounted) return;
          final type = _tabController.index == 0
              ? null
              : _tabController.index == 1
                  ? 'income'
                  : 'expense';
          provider.loadTransactions(type: type);
          provider.loadSummary();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final income = (provider.summary['income'] as num?)?.toDouble() ?? 0;
        final expense = (provider.summary['expense'] as num?)?.toDouble() ?? 0;
        final balance = (provider.summary['balance'] as num?)?.toDouble() ?? 0;

        return Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Income',
                    amount: income,
                    color: AppTheme.primary,
                    icon: Icons.arrow_downward,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Expense',
                    amount: expense,
                    color: AppTheme.error,
                    icon: Icons.arrow_upward,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Balance',
                    amount: balance,
                    color: balance >= 0 ? AppTheme.accent : AppTheme.error,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  final String? type;
  const _TransactionList({this.type});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(child: Text(provider.error!, style: const TextStyle(color: AppTheme.error)));
        }
        if (provider.transactions.isEmpty) {
          return const Center(child: Text('No transactions yet'));
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.extentAfter < 100 &&
                provider.hasMore) {
              provider.loadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: provider.transactions.length + (provider.loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.transactions.length) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ));
              }
              final txn = provider.transactions[index];
              return _TransactionTile(txn: txn);
            },
          ),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final FinanceTransaction txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.type == 'income';
    return Dismissible(
      key: Key('txn_${txn.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showAppSheet<bool>(
          context: context,
          title: 'Delete Transaction',
          initialChildSize: 0.3,
          body: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Are you sure you want to delete this transaction?'),
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
      },
      onDismissed: (_) {
        context.read<FinanceProvider>().deleteTransaction(txn.id);
      },
      child: Card(
        child: ListTile(
          onTap: () => _showEditSheet(context),
          leading: CircleAvatar(
            backgroundColor: isIncome
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.errorContainer,
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? AppTheme.primary : AppTheme.error,
            ),
          ),
          title: Text(txn.categoryName ?? 'Unknown'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (txn.description != null && txn.description!.isNotEmpty)
                Text(txn.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(txn.date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          trailing: Text(
            '${isIncome ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isIncome ? AppTheme.primary : AppTheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          isThreeLine: txn.description != null && txn.description!.isNotEmpty,
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final amountCtrl = TextEditingController(text: txn.amount.toStringAsFixed(2));
    final descCtrl = TextEditingController(text: txn.description ?? '');
    DateTime selectedDate = DateTime.tryParse(txn.date) ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
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
                  Text('Edit Transaction', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), prefixText: '₹ '),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) setSheetState(() => selectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                      child: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                    ),
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
                            final amount = double.tryParse(amountCtrl.text);
                            if (amount == null || amount <= 0) return;
                            final data = <String, dynamic>{
                              'amount': amount,
                              'description': descCtrl.text.trim(),
                              'date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            };
                            Navigator.pop(ctx);
                            final success = await context.read<FinanceProvider>().updateTransaction(txn.id, data);
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
      ),
    );
  }
}
