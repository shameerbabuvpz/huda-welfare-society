import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            Tab(text: 'All'),
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
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
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (result == true && mounted) {
            final provider = context.read<FinanceProvider>();
            final type = _tabController.index == 0
                ? null
                : _tabController.index == 1
                    ? 'income'
                    : 'expense';
            provider.loadTransactions(type: type);
            provider.loadSummary();
          }
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
                    color: Colors.green,
                    icon: Icons.arrow_downward,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Expense',
                    amount: expense,
                    color: Colors.red,
                    icon: Icons.arrow_upward,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Balance',
                    amount: balance,
                    color: balance >= 0 ? Colors.blue : Colors.red,
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
          return Center(child: Text(provider.error!, style: const TextStyle(color: Colors.red)));
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
        color: Colors.red,
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
            OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
          leading: CircleAvatar(
            backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red,
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
              color: isIncome ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          isThreeLine: txn.description != null && txn.description!.isNotEmpty,
        ),
      ),
    );
  }
}
