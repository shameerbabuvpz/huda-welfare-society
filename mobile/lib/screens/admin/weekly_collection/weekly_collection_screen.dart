import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/ayalkoottam.dart';
import '../../../models/weekly_collection.dart';
import '../../../providers/ayalkoottam_provider.dart';
import '../../../providers/weekly_collection_provider.dart';

String _fmtAmount(double v) {
  final isNeg = v < 0;
  final abs = v.abs();
  final s = abs.toStringAsFixed(abs == abs.roundToDouble() ? 0 : 2);
  // Indian-style grouping
  final parts = s.split('.');
  final intPart = parts[0];
  String grouped;
  if (intPart.length <= 3) {
    grouped = intPart;
  } else {
    final last3 = intPart.substring(intPart.length - 3);
    var rest = intPart.substring(0, intPart.length - 3);
    final buf = <String>[];
    while (rest.length > 2) {
      buf.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) buf.insert(0, rest);
    grouped = '${buf.join(',')},$last3';
  }
  final out = parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
  return '${isNeg ? '-' : ''}₹$out';
}

String _fmtDate(String iso) {
  try {
    final d = DateTime.parse(iso);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  } catch (_) {
    return iso;
  }
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class WeeklyCollectionScreen extends StatefulWidget {
  const WeeklyCollectionScreen({super.key});

  @override
  State<WeeklyCollectionScreen> createState() => _WeeklyCollectionScreenState();
}

class _WeeklyCollectionScreenState extends State<WeeklyCollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AyalkoottamProvider>().loadDropdown();
      context.read<WeeklyCollectionProvider>().loadReport();
      context.read<WeeklyCollectionProvider>().loadEntries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Collection'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Entry', icon: Icon(Icons.edit_note)),
            Tab(text: 'Consolidated', icon: Icon(Icons.summarize)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _EntryTab(),
          _ReportTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _openEntrySheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Entry'),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ENTRY TAB
// ═══════════════════════════════════════════════════════════════
class _EntryTab extends StatelessWidget {
  const _EntryTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeeklyCollectionProvider>();

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.entries.isEmpty) {
      return const _EmptyState(
        icon: Icons.edit_note,
        title: 'No entries yet',
        message: 'Tap "Add Entry" to record a week\'s collection for an ayalkoottam.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadEntries(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: provider.entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final e = provider.entries[i];
          return _EntryCard(entry: e);
        },
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final WeeklyCollection entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isPositive = entry.netTotal >= 0;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openEntrySheet(context, existing: entry),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.ayalkoottamName ?? 'Ayalkoottam #${entry.ayalkoottamId}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppTheme.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Collection: ${_fmtDate(entry.weekStartDate)}',
                            style: TextStyle(fontSize: 12, color: AppTheme.ink.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isPositive ? AppTheme.success : AppTheme.error).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _fmtAmount(entry.netTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isPositive ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniStat(label: 'Deposit', value: entry.deposit, color: AppTheme.success),
                    _MiniStat(label: 'Withdrawal', value: entry.withdrawal, color: AppTheme.error),
                    _MiniStat(label: 'Loan', value: entry.loan, color: AppTheme.accent),
                    _MiniStat(label: 'Repayment', value: entry.loanRepayment, color: AppTheme.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, color: AppTheme.ink.withValues(alpha: 0.6))),
          const SizedBox(height: 1),
          Text(_fmtAmount(value), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: color)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ENTRY FORM (bottom sheet)
// ═══════════════════════════════════════════════════════════════
void _openEntrySheet(BuildContext context, {WeeklyCollection? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _EntryForm(existing: existing),
  );
}

class _EntryForm extends StatefulWidget {
  final WeeklyCollection? existing;
  const _EntryForm({this.existing});

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  final _formKey = GlobalKey<FormState>();
  int? _ayalkoottamId;
  late DateTime _collectionDate;
  final _deposit = TextEditingController();
  final _withdrawal = TextEditingController();
  final _loan = TextEditingController();
  final _repayment = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  bool _lookingUp = false;
  WeeklyCollection? _loaded;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _loaded = e;
      _ayalkoottamId = e.ayalkoottamId;
      _collectionDate = DateTime.tryParse(e.weekStartDate) ?? _today();
      _fill(e);
    } else {
      _collectionDate = _today();
    }
  }

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _fill(WeeklyCollection e) {
    _deposit.text = e.deposit == 0 ? '' : _trim(e.deposit);
    _withdrawal.text = e.withdrawal == 0 ? '' : _trim(e.withdrawal);
    _loan.text = e.loan == 0 ? '' : _trim(e.loan);
    _repayment.text = e.loanRepayment == 0 ? '' : _trim(e.loanRepayment);
    _note.text = e.note ?? '';
  }

  void _clearAmounts() {
    _deposit.clear();
    _withdrawal.clear();
    _loan.clear();
    _repayment.clear();
    _note.clear();
  }

  /// When the ayalkoottam or collection day changes, pull any existing entry
  /// so it can be edited / deleted instead of duplicated.
  Future<void> _lookup() async {
    if (_ayalkoottamId == null) return;
    setState(() => _lookingUp = true);
    final found = await context
        .read<WeeklyCollectionProvider>()
        .findEntry(_ayalkoottamId!, _isoDate(_collectionDate));
    if (!mounted) return;
    setState(() {
      if (found != null) {
        _loaded = found;
        _fill(found);
      } else {
        _loaded = null;
        _clearAmounts();
      }
      _lookingUp = false;
    });
  }

  String _trim(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _deposit.dispose();
    _withdrawal.dispose();
    _loan.dispose();
    _repayment.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _net {
    double d(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
    return d(_deposit) - d(_withdrawal) - d(_loan) + d(_repayment);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _collectionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      helpText: 'Select the collection day',
    );
    if (picked != null) {
      setState(() => _collectionDate = DateTime(picked.year, picked.month, picked.day));
      await _lookup();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ayalkoottamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.errorSnackBar('Please select an ayalkoottam'));
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<WeeklyCollectionProvider>();
    double d(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
    final ok = await provider.saveEntry({
      'ayalkoottam_id': _ayalkoottamId,
      'week_start_date': _isoDate(_collectionDate),
      'deposit': d(_deposit),
      'withdrawal': d(_withdrawal),
      'loan': d(_loan),
      'loan_repayment': d(_repayment),
      'note': _note.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      await provider.loadEntries();
      await provider.loadReport();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.successSnackBar('Entry saved'));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(provider.error ?? 'Could not save entry'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ayalkoottams = context.watch<AyalkoottamProvider>().dropdownList;
    final isPositive = _net >= 0;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42, height: 4,
                  decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _loaded == null ? 'Add Collection Entry' : 'Edit Collection Entry',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                  ),
                  const SizedBox(width: 10),
                  if (_lookingUp)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              if (_loaded != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Existing entry loaded — edit or delete below.',
                    style: TextStyle(fontSize: 12, color: AppTheme.accent.withValues(alpha: 0.95), fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _ayalkoottamId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ayalkoottam',
                  prefixIcon: Icon(Icons.groups_2),
                ),
                items: ayalkoottams
                    .map((Ayalkoottam a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _ayalkoottamId = v);
                  _lookup();
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Collection Day',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _fmtDate(_isoDate(_collectionDate)),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _AmountField(controller: _deposit, label: 'Deposit (നിക്ഷേപം)', icon: Icons.south_west, color: AppTheme.success, onChanged: () => setState(() {})),
              const SizedBox(height: 10),
              _AmountField(controller: _withdrawal, label: 'Withdrawal (പിൻവലിക്കൽ)', icon: Icons.north_east, color: AppTheme.error, onChanged: () => setState(() {})),
              const SizedBox(height: 10),
              _AmountField(controller: _loan, label: 'Loan (ലോൺ)', icon: Icons.call_made, color: AppTheme.accent, onChanged: () => setState(() {})),
              const SizedBox(height: 10),
              _AmountField(controller: _repayment, label: 'Loan Repayment (ലോൺ തിരിച്ചടവ്)', icon: Icons.call_received, color: AppTheme.primary, onChanged: () => setState(() {})),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: (isPositive ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: (isPositive ? AppTheme.success : AppTheme.error).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Net Total', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
                    Text(
                      '${isPositive ? '+' : ''}${_fmtAmount(_net)}',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: isPositive ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (_loaded != null) ...[
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                      label: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check),
                      label: Text(_saving ? 'Saving...' : (_loaded == null ? 'Save Entry' : 'Update Entry')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = context.read<WeeklyCollectionProvider>();
    final ok = await provider.deleteEntry(_loaded!.id);
    if (!mounted) return;
    if (ok) {
      await provider.loadEntries();
      await provider.loadReport();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.successSnackBar('Entry deleted'));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(provider.error ?? 'Could not delete entry'),
      );
    }
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onChanged;
  const _AmountField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        prefixText: '₹ ',
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CONSOLIDATED REPORT TAB
// ═══════════════════════════════════════════════════════════════
class _ReportTab extends StatelessWidget {
  const _ReportTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeeklyCollectionProvider>();
    final report = provider.report;

    return Column(
      children: [
        _ReportFilters(provider: provider),
        Expanded(
          child: provider.reportLoading
              ? const Center(child: CircularProgressIndicator())
              : report == null || report.periods.isEmpty
                  ? const _EmptyState(
                      icon: Icons.summarize,
                      title: 'No data for this range',
                      message: 'Add entries or change the filters to see the consolidated report.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.loadReport(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          _GrandTotalCard(totals: report.totals, groupBy: report.groupBy),
                          const SizedBox(height: 16),
                          const _SectionLabel('By Period'),
                          const SizedBox(height: 8),
                          ...report.periods.map((p) => _PeriodCard(period: p, groupBy: report.groupBy)),
                          if (report.byAyalkoottam.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const _SectionLabel('By Ayalkoottam (whole range)'),
                            const SizedBox(height: 8),
                            ...report.byAyalkoottam.map((g) => _AyalkoottamSummaryCard(group: g)),
                          ],
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class _ReportFilters extends StatelessWidget {
  final WeeklyCollectionProvider provider;
  const _ReportFilters({required this.provider});

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 7)),
      initialDateRange: provider.fromDate != null && provider.toDate != null
          ? DateTimeRange(
              start: DateTime.parse(provider.fromDate!),
              end: DateTime.parse(provider.toDate!),
            )
          : null,
    );
    if (picked != null) {
      provider.setDateRange(_isoDate(picked.start), _isoDate(picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRange = provider.fromDate != null && provider.toDate != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWarm,
        border: Border(bottom: BorderSide(color: AppTheme.outline)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'week', label: Text('Weekly'), icon: Icon(Icons.view_week, size: 18)),
                    ButtonSegment(value: 'month', label: Text('Monthly'), icon: Icon(Icons.calendar_month, size: 18)),
                  ],
                  selected: {provider.groupBy},
                  onSelectionChanged: (s) => provider.setGroupBy(s.first),
                  showSelectedIcon: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickRange(context),
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    hasRange
                        ? '${_fmtDate(provider.fromDate!)} → ${_fmtDate(provider.toDate!)}'
                        : 'All dates',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (hasRange) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear range',
                  onPressed: () => provider.setDateRange(null, null),
                  icon: const Icon(Icons.clear),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GrandTotalCard extends StatelessWidget {
  final ConsolidationGroup totals;
  final String groupBy;
  const _GrandTotalCard({required this.totals, required this.groupBy});

  @override
  Widget build(BuildContext context) {
    final isPositive = totals.netTotal >= 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
              ),
              Text(
                '${totals.entryCount} entries',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${isPositive ? '+' : ''}${_fmtAmount(totals.netTotal)}',
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TotalCell('Deposit', totals.deposit),
              _TotalCell('Withdrawal', totals.withdrawal),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TotalCell('Loan', totals.loan),
              _TotalCell('Repayment', totals.loanRepayment),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  final String label;
  final double value;
  const _TotalCell(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5)),
          const SizedBox(height: 2),
          Text(_fmtAmount(value), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final ConsolidationPeriod period;
  final String groupBy;
  const _PeriodCard({required this.period, required this.groupBy});

  String get _title {
    if (groupBy == 'month') {
      try {
        final d = DateTime.parse(period.periodStart);
        const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        return '${months[d.month - 1]} ${d.year}';
      } catch (_) {
        return period.periodKey;
      }
    }
    return 'Collection: ${_fmtDate(period.periodStart)}';
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = period.netTotal >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Text(_title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              groupBy == 'month'
                  ? '${_fmtDate(period.periodStart)} – ${_fmtDate(period.periodEnd)} • ${period.ayalkoottams.length} ayalkoottam(s)'
                  : '${period.ayalkoottams.length} ayalkoottam(s)',
              style: TextStyle(fontSize: 11.5, color: AppTheme.ink.withValues(alpha: 0.6)),
            ),
          ),
          trailing: Text(
            '${isPositive ? '+' : ''}${_fmtAmount(period.netTotal)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: isPositive ? AppTheme.success : AppTheme.error,
            ),
          ),
          children: [
            _BreakdownRow(deposit: period.deposit, withdrawal: period.withdrawal, loan: period.loan, repayment: period.loanRepayment),
            const Divider(height: 18),
            ...period.ayalkoottams.map((g) => _AyalkoottamLine(group: g)),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final double deposit, withdrawal, loan, repayment;
  const _BreakdownRow({required this.deposit, required this.withdrawal, required this.loan, required this.repayment});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniStat(label: 'Deposit', value: deposit, color: AppTheme.success),
        _MiniStat(label: 'Withdrawal', value: withdrawal, color: AppTheme.error),
        _MiniStat(label: 'Loan', value: loan, color: AppTheme.accent),
        _MiniStat(label: 'Repayment', value: repayment, color: AppTheme.primary),
      ],
    );
  }
}

class _AyalkoottamLine extends StatelessWidget {
  final ConsolidationGroup group;
  const _AyalkoottamLine({required this.group});

  @override
  Widget build(BuildContext context) {
    final isPositive = group.netTotal >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.groups_2, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(group.ayalkoottamName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink)),
          ),
          Text(
            '${isPositive ? '+' : ''}${_fmtAmount(group.netTotal)}',
            style: TextStyle(fontWeight: FontWeight.w700, color: isPositive ? AppTheme.success : AppTheme.error),
          ),
        ],
      ),
    );
  }
}

class _AyalkoottamSummaryCard extends StatelessWidget {
  final ConsolidationGroup group;
  const _AyalkoottamSummaryCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final isPositive = group.netTotal >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(group.ayalkoottamName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.ink)),
              ),
              Text(
                '${isPositive ? '+' : ''}${_fmtAmount(group.netTotal)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: isPositive ? AppTheme.success : AppTheme.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _BreakdownRow(deposit: group.deposit, withdrawal: group.withdrawal, loan: group.loan, repayment: group.loanRepayment),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Shared widgets
// ═══════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: AppTheme.ink.withValues(alpha: 0.5),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _EmptyState({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.ink.withValues(alpha: 0.25)),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.ink)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}
