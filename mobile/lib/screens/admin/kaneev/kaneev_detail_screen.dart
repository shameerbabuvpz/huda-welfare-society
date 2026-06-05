import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../providers/kaneev_provider.dart';
import '../../../providers/ayalkoottam_provider.dart';
import '../../../providers/member_provider.dart';
import '../../../models/kaneev_group.dart';
import '../../../models/member.dart';
import '../../../utils/ak_name_helper.dart';
import '../../../services/kaneev_service.dart';
import '../../../services/export_service.dart';

class KaneevDetailScreen extends StatefulWidget {
  const KaneevDetailScreen({super.key});

  @override
  State<KaneevDetailScreen> createState() => _KaneevDetailScreenState();
}

class _KaneevDetailScreenState extends State<KaneevDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<KaneevProvider>().loadKaneev();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KaneevProvider>();
    final group = provider.group;

    if (provider.loading || group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kaniv')),
        body: const DetailSkeletonLoader(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaniv'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Group Info',
            onPressed: () => _showInfoSheet(group),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
                child:
                    Text('Members', maxLines: 2, textAlign: TextAlign.center)),
            Tab(
                child: Text('Recipients',
                    maxLines: 2, textAlign: TextAlign.center)),
            Tab(
                child:
                    Text('Balance', maxLines: 2, textAlign: TextAlign.center)),
          ],
        ),
      ),
      floatingActionButton: _buildFab(group),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MembersTab(group: group),
          _RecipientsTab(group: group),
          _BalanceTab(group: group),
        ],
      ),
    );
  }

  Widget? _buildFab(KaneevGroup group) {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, _) {
        if (_tabController.index == 0) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'donate',
                onPressed: () => _showRecordDonationDialog(group),
                icon: const Icon(Icons.payments),
                label: const Text('Record Donation'),
                backgroundColor: AppTheme.primary,
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'addMember',
                onPressed: () => _showAddMemberDialog(group),
                icon: const Icon(Icons.person_add),
                label: const Text('Add Member'),
              ),
            ],
          );
        } else if (_tabController.index == 1) {
          return FloatingActionButton.extended(
            onPressed: () => _showSelectRecipientDialog(group),
            icon: const Icon(Icons.card_giftcard),
            label: const Text('Select Recipient'),
            backgroundColor: AppTheme.primary,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showAddMemberDialog(KaneevGroup group) {
    context.read<AyalkoottamProvider>().loadDropdown();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddMemberSheet(),
    );
  }

  void _showInfoSheet(KaneevGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.7,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Kaniv Info',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              _infoRow('Code', group.code),
              _editableAmountRow(group),
              _infoRow('Status', group.status.toUpperCase()),
              _infoRow('Enrolled Members', '${group.members?.length ?? 0}'),
              _infoRow('Recipients so far', '${group.recipients?.length ?? 0}'),
              _infoRow('Current Balance',
                  '₹${group.currentBalance.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _editableAmountRow(KaneevGroup group) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Donation Amount',
              style: TextStyle(color: Colors.grey.shade600)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹${group.donationAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showEditAmountDialog(group);
                },
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit, size: 18, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditAmountDialog(KaneevGroup group) {
    final controller =
        TextEditingController(text: group.donationAmount.toStringAsFixed(0));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Edit Donation Amount',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final amount = double.tryParse(controller.text);
                          if (amount == null || amount <= 0) return;
                          Navigator.pop(ctx);
                          final success = await context
                              .read<KaneevProvider>()
                              .updateDonationAmount(amount);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppTheme.errorSnackBar(
                                  context.read<KaneevProvider>().error ??
                                      'Error'),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
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

  void _showRecordDonationDialog(KaneevGroup group) {
    final enrolledMembers = group.members ?? [];
    if (enrolledMembers.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(AppTheme.infoSnackBar('No members enrolled'));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DonationSheet(group: group),
    );
  }

  void _showSelectRecipientDialog(KaneevGroup group) {
    final enrolledMembers = group.members ?? [];
    if (enrolledMembers.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(AppTheme.infoSnackBar('No members enrolled'));
      return;
    }

    final recipientMemberIds =
        (group.recipients ?? []).map((r) => r.memberId).toSet();
    final eligibleMembers = enrolledMembers
        .where((m) => !recipientMemberIds.contains(m.memberId))
        .toList();

    if (eligibleMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.infoSnackBar('All members have already received'));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SelectRecipientSheet(
        eligibleMembers: eligibleMembers,
        recipientCount: recipientMemberIds.length,
        group: group,
      ),
    );
  }
}

class _MonthOption {
  final int year;
  final int monthIndex;
  final int monthNumber;
  final String label;
  const _MonthOption(
      {required this.year,
      required this.monthIndex,
      required this.monthNumber,
      required this.label});
}

String _monthLabel(int monthNumber) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final year = 2025 + ((monthNumber - 1) ~/ 12);
  final month = ((monthNumber - 1) % 12);
  return '${names[month]} $year';
}

String _monthShort(int monthNumber) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final month = ((monthNumber - 1) % 12);
  return names[month];
}

List<_MonthOption> _buildMonthOptions() {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  final now = DateTime.now();
  final opts = <_MonthOption>[];
  for (int y = 2025; y <= now.year + 1; y++) {
    for (int m = 0; m < 12; m++) {
      opts.add(_MonthOption(
          year: y,
          monthIndex: m,
          monthNumber: (y - 2025) * 12 + (m + 1),
          label: '${names[m]} $y'));
    }
  }
  return opts;
}

// ── Select Recipient Sheet ──
class _SelectRecipientSheet extends StatefulWidget {
  final List<KaneevMemberSlot> eligibleMembers;
  final int recipientCount;
  final KaneevGroup group;
  const _SelectRecipientSheet(
      {required this.eligibleMembers,
      required this.recipientCount,
      required this.group});

  @override
  State<_SelectRecipientSheet> createState() => _SelectRecipientSheetState();
}

class _SelectRecipientSheetState extends State<_SelectRecipientSheet> {
  String? _selectedAyalkoottam;
  String _searchQuery = '';
  int? _selectedMemberId;
  late int _selectedYear;
  late int _selectedMonthIdx;

  int get _monthNumber => (_selectedYear - 2025) * 12 + (_selectedMonthIdx + 1);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonthIdx = now.month - 1;
  }

  List<KaneevMemberSlot> get _filteredMembers {
    var list = widget.eligibleMembers;
    if (_selectedAyalkoottam != null) {
      list =
          list.where((m) => m.ayalkoottamName == _selectedAyalkoottam).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((m) =>
              (m.memberName?.toLowerCase().contains(q) ?? false) ||
              (m.memberCode?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  List<String> get _ayalkoottamList {
    final names = widget.eligibleMembers
        .where((m) => m.ayalkoottamName != null)
        .map((m) => m.ayalkoottamName!)
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  void _confirmRecipient() {
    if (_selectedMemberId == null) return;
    Navigator.pop(context);
    context
        .read<KaneevProvider>()
        .selectRecipient(_selectedMemberId!, _monthNumber);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMembers;
    final monthOpts = _buildMonthOptions();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                      child: Text('Select Recipient',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Month dropdown
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                value: _monthNumber,
                isExpanded: true,
                items: monthOpts
                    .map((opt) => DropdownMenuItem(
                        value: opt.monthNumber,
                        child: Text(opt.label,
                            style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    final opt = monthOpts.firstWhere((o) => o.monthNumber == v);
                    setState(() {
                      _selectedYear = opt.year;
                      _selectedMonthIdx = opt.monthIndex;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Ayalkoottam filter + search
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                          labelText: 'Ayalkoottam',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8)),
                      value: _selectedAyalkoottam,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ..._ayalkoottamList.map((name) => DropdownMenuItem(
                            value: name,
                            child:
                                Text(name, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedAyalkoottam = v;
                        _selectedMemberId = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search member...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  _selectedMemberId = null;
                }),
              ),
              const SizedBox(height: 4),

              // Info bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${filtered.length} eligible',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const Spacer(),
                    if (widget.recipientCount > 0)
                      Text('${widget.recipientCount} already received',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.accent)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Member list
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching members'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final m = filtered[i];
                          final isSelected = _selectedMemberId == m.memberId;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? AppTheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : Text(m.memberName?[0].toUpperCase() ?? '?',
                                      style: const TextStyle(fontSize: 14)),
                            ),
                            title:
                                Text(m.memberName ?? 'Member #${m.memberId}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (m.ayalkoottamName != null)
                                  Text(m.ayalkoottamName!,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primary)),
                                if (m.memberCode != null)
                                  Text(m.memberCode!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                              ],
                            ),
                            onTap: () =>
                                setState(() => _selectedMemberId = m.memberId),
                          );
                        },
                      ),
              ),

              // Confirm button
              const SizedBox(height: 8),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed:
                          _selectedMemberId != null ? _confirmRecipient : null,
                      icon: const Icon(Icons.card_giftcard),
                      label: const Text('Confirm Recipient'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Donation recording sheet ──
class _DonationSheet extends StatefulWidget {
  final KaneevGroup group;
  const _DonationSheet({required this.group});

  @override
  State<_DonationSheet> createState() => _DonationSheetState();
}

class _DonationSheetState extends State<_DonationSheet> {
  late int _selectedYear;
  late int _selectedMonthIndex; // 0-based (Jan=0)
  bool _loading = false;
  String _sortMode = 'all'; // all, unpaid, paid
  String _searchQuery = '';
  String? _selectedAyalkoottam;
  final Set<int> _paidMemberIds = {};
  final Map<int, String?> _paidDates = {}; // memberId -> paid_date

  int get _monthNumber {
    return (_selectedYear - 2025) * 12 + (_selectedMonthIndex + 1);
  }

  List<String> get _ayalkoottamList {
    final names = (widget.group.members ?? [])
        .map((m) => m.ayalkoottamName)
        .whereType<String>()
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonthIndex = now.month - 1;
    _loadDonations();
  }

  List<KaneevMemberSlot> get _sortedMembers {
    final members = widget.group.members ?? [];
    List<KaneevMemberSlot> list;
    if (_sortMode == 'unpaid') {
      list =
          members.where((m) => !_paidMemberIds.contains(m.memberId)).toList();
    } else if (_sortMode == 'paid') {
      list = members.where((m) => _paidMemberIds.contains(m.memberId)).toList();
    } else {
      // Sort unpaid first
      list = List.from(members);
      list.sort((a, b) {
        final aPaid = _paidMemberIds.contains(a.memberId) ? 1 : 0;
        final bPaid = _paidMemberIds.contains(b.memberId) ? 1 : 0;
        return aPaid.compareTo(bPaid);
      });
    }

    // Filter by ayalkoottam
    if (_selectedAyalkoottam != null) {
      list =
          list.where((m) => m.ayalkoottamName == _selectedAyalkoottam).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((m) =>
              (m.memberName?.toLowerCase().contains(q) ?? false) ||
              (m.memberCode?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return list;
  }

  Future<void> _loadDonations() async {
    setState(() => _loading = true);
    try {
      final donations =
          await KaneevService.getDonations(monthNumber: _monthNumber);
      _paidMemberIds.clear();
      _paidDates.clear();
      for (final d in donations) {
        _paidMemberIds.add(d['member_id']);
        _paidDates[d['member_id']] = d['paid_date']?.toString();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _recordDonation(int memberId) async {
    final success = await context.read<KaneevProvider>().recordDonation(
          memberId: memberId,
          monthNumber: _monthNumber,
          amount: widget.group.donationAmount,
        );
    if (success) {
      setState(() {
        _paidMemberIds.add(memberId);
        _paidDates[memberId] = DateTime.now().toIso8601String();
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppTheme.successSnackBar('Donation recorded'));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(
              context.read<KaneevProvider>().error ?? 'Error'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allMembers = widget.group.members ?? [];
    final sorted = _sortedMembers;
    final unpaidCount =
        allMembers.where((m) => !_paidMemberIds.contains(m.memberId)).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: Text('Record Donations',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Month dropdown
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                value: _monthNumber,
                isExpanded: true,
                items: _buildMonthOptions()
                    .map((opt) => DropdownMenuItem(
                          value: opt.monthNumber,
                          child: Text(opt.label,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    final opt = _buildMonthOptions()
                        .firstWhere((o) => o.monthNumber == v);
                    setState(() {
                      _selectedYear = opt.year;
                      _selectedMonthIndex = opt.monthIndex;
                    });
                    _loadDonations();
                  }
                },
              ),
              const SizedBox(height: 10),
              // Search + Ayalkoottam filter row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search member...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Ayalkoottam',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      value: _selectedAyalkoottam,
                      isExpanded: true,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                      items: [
                        const DropdownMenuItem(
                            value: null,
                            child: Text('All', style: TextStyle(fontSize: 12))),
                        ..._ayalkoottamList.map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12)),
                            )),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedAyalkoottam = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Status summary + sort chips
              Row(
                children: [
                  FilterChip(
                    label: Text('All (${allMembers.length})',
                        style: TextStyle(
                            fontSize: 11,
                            color: _sortMode == 'all' ? Colors.white : null)),
                    selected: _sortMode == 'all',
                    onSelected: (_) => setState(() => _sortMode = 'all'),
                    selectedColor: AppTheme.primary,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: Text('Unpaid ($unpaidCount)',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                _sortMode == 'unpaid' ? Colors.white : null)),
                    selected: _sortMode == 'unpaid',
                    onSelected: (_) => setState(() => _sortMode = 'unpaid'),
                    selectedColor: AppTheme.error,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: Text('Paid (${_paidMemberIds.length})',
                        style: TextStyle(
                            fontSize: 11,
                            color: _sortMode == 'paid' ? Colors.white : null)),
                    selected: _sortMode == 'paid',
                    onSelected: (_) => setState(() => _sortMode = 'paid'),
                    selectedColor: AppTheme.primary,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  const Spacer(),
                  Text('₹${widget.group.donationAmount.toStringAsFixed(0)}/ea',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(height: 1),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              Expanded(
                child: sorted.isEmpty
                    ? SingleChildScrollView(
                        controller: scrollController,
                        child: SizedBox(
                          height: 200,
                          child: Center(
                              child: Text(_sortMode == 'unpaid'
                                  ? 'All members have paid!'
                                  : (_sortMode == 'paid'
                                      ? 'No payments yet'
                                      : 'No members'))),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: sorted.length,
                        itemBuilder: (ctx, i) {
                          final m = sorted[i];
                          final isPaid = _paidMemberIds.contains(m.memberId);
                          final paidDate = _paidDates[m.memberId];
                          final paidDateStr =
                              paidDate != null ? paidDate.split('T')[0] : null;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isPaid
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  child: isPaid
                                      ? const Icon(Icons.check,
                                          color: AppTheme.primary, size: 18)
                                      : Text(
                                          m.memberName?[0].toUpperCase() ?? '?',
                                          style: const TextStyle(fontSize: 13)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.memberName ?? 'Member #${m.memberId}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Row(
                                        children: [
                                          if (m.memberCode != null) ...[
                                            Text(m.memberCode!,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            const SizedBox(width: 6),
                                          ],
                                          if (m.ayalkoottamName != null)
                                            Flexible(
                                              child: Text(m.ayalkoottamName!,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.primary),
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                          if (isPaid &&
                                              paidDateStr != null) ...[
                                            const SizedBox(width: 6),
                                            Text(paidDateStr,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.grey.shade500)),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                isPaid
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text('Paid ✓',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.w600)),
                                      )
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          minimumSize: const Size(0, 32),
                                          maximumSize: const Size(100, 32),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        onPressed: () =>
                                            _recordDonation(m.memberId),
                                        child: const Text('₹ Pay',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12)),
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Member Sheet ──
class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet();

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  int? _selectedAyalkoottamId;
  List<Member> _filteredMembers = [];
  bool _loadingMembers = false;

  @override
  void initState() {
    super.initState();
    // Auto-load all members when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMembers(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final akProvider = context.watch<AyalkoottamProvider>();
    final dropdownList = akProvider.dropdownList;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                      child: Text('Add Member to Kaneev',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                    labelText: 'Filter by Ayalkoottam',
                    border: OutlineInputBorder()),
                value: _selectedAyalkoottamId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...dropdownList.map((ak) => DropdownMenuItem(
                      value: ak.id, child: Text(shortAkName(ak.name)))),
                ],
                onChanged: (v) {
                  setState(() => _selectedAyalkoottamId = v);
                  _loadMembers(v);
                },
              ),
              const SizedBox(height: 12),
              if (_loadingMembers)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CupertinoActivityIndicator()))
              else
                Expanded(
                  child: _filteredMembers.isEmpty
                      ? const Center(
                          child: Text('No members found'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _filteredMembers.length,
                          itemBuilder: (ctx, i) {
                            final m = _filteredMembers[i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 18,
                                child: Text(
                                  m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              title: Text(
                                m.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${m.memberCode}${m.phone != null ? ' • ${m.phone}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                              trailing: SizedBox(
                                width: 56,
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () => _addMember(m.id),
                                  style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 12)),
                                  child: const Text('Add'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadMembers(int? ayalkoottamId) async {
    if (!mounted) return;
    setState(() => _loadingMembers = true);
    try {
      final provider = context.read<MemberProvider>();
      await provider.loadMembers(ayalkoottamId: ayalkoottamId);
      if (!mounted) return;
      setState(() {
        _filteredMembers = List<Member>.from(provider.members);
        _loadingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMembers = false);
    }
  }

  Future<void> _addMember(int memberId) async {
    final success = await context.read<KaneevProvider>().addMember(memberId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Member added successfully'));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(AppTheme.errorSnackBar(
            context.read<KaneevProvider>().error ?? 'Error'));
      }
    }
  }
}

// ── Members Tab ──
class _MembersTab extends StatefulWidget {
  final KaneevGroup group;
  const _MembersTab({required this.group});

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  String? _selectedAyalkoottam;
  String _statusFilter = 'all'; // all, pending, received
  String _searchQuery = '';
  bool _sortAscending = true; // slot number sort direction
  bool _groupByAyalkoottam = false;

  List<String> get _ayalkoottamList {
    final names = (widget.group.members ?? [])
        .where((m) => m.ayalkoottamName != null)
        .map((m) => m.ayalkoottamName!)
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  List<KaneevMemberSlot> get _filteredMembers {
    final recipientMemberIds =
        (widget.group.recipients ?? []).map((r) => r.memberId).toSet();
    var list = widget.group.members ?? <KaneevMemberSlot>[];

    // Filter by ayalkoottam
    if (_selectedAyalkoottam != null) {
      list =
          list.where((m) => m.ayalkoottamName == _selectedAyalkoottam).toList();
    }

    // Filter by status
    if (_statusFilter == 'received') {
      list =
          list.where((m) => recipientMemberIds.contains(m.memberId)).toList();
    } else if (_statusFilter == 'pending') {
      list =
          list.where((m) => !recipientMemberIds.contains(m.memberId)).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((m) =>
              (m.memberName?.toLowerCase().contains(q) ?? false) ||
              (m.memberCode?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    // Sort by slot number
    list = List.from(list);
    if (_groupByAyalkoottam) {
      list.sort((a, b) {
        final akCmp =
            (a.ayalkoottamName ?? '').compareTo(b.ayalkoottamName ?? '');
        if (akCmp != 0) return akCmp;
        final aSlot = a.slotNumber ?? 9999;
        final bSlot = b.slotNumber ?? 9999;
        return _sortAscending ? aSlot.compareTo(bSlot) : bSlot.compareTo(aSlot);
      });
    } else {
      list.sort((a, b) {
        final aSlot = a.slotNumber ?? 9999;
        final bSlot = b.slotNumber ?? 9999;
        return _sortAscending ? aSlot.compareTo(bSlot) : bSlot.compareTo(aSlot);
      });
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members ?? [];
    final recipientMemberIds =
        (widget.group.recipients ?? []).map((r) => r.memberId).toSet();
    final filtered = _filteredMembers;

    if (members.isEmpty) {
      return const Center(child: Text('No members enrolled'));
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search member...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),

        // Filter row: Ayalkoottam dropdown + sort button + group toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Ayalkoottam filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Ayalkoottam',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  value: _selectedAyalkoottam,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('All', style: TextStyle(fontSize: 13))),
                    ..._ayalkoottamList.map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedAyalkoottam = v),
                ),
              ),
              const SizedBox(width: 8),
              // Sort direction toggle
              InkWell(
                onTap: () => setState(() => _sortAscending = !_sortAscending),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          _sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                          color: AppTheme.primary),
                      const SizedBox(width: 2),
                      Text('No.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Group by ayalkoottam toggle
              InkWell(
                onTap: () =>
                    setState(() => _groupByAyalkoottam = !_groupByAyalkoottam),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _groupByAyalkoottam
                            ? AppTheme.primary
                            : Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: _groupByAyalkoottam
                        ? AppTheme.primary.withOpacity(0.1)
                        : null,
                  ),
                  child: Icon(Icons.group_work,
                      size: 18,
                      color: _groupByAyalkoottam
                          ? AppTheme.primary
                          : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Status filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Received', 'received'),
              const Spacer(),
              Text('${filtered.length}/${members.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(height: 1),

        // Total paid summary + export
        _buildTotalsHeader(filtered),

        // Member list (grouped or flat)
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No matching members'))
              : _groupByAyalkoottam
                  ? _buildGroupedList(filtered, recipientMemberIds)
                  : _buildFlatList(filtered, recipientMemberIds),
        ),
      ],
    );
  }

  Widget _buildTotalsHeader(List<KaneevMemberSlot> filtered) {
    final totalPaid =
        filtered.fold<double>(0, (sum, m) => sum + m.totalPaid);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.primary.withOpacity(0.06),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text('Total Paid: ',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          Text('₹${totalPaid.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary)),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _exportTotals,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  void _exportTotals() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Export Member Totals',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel (.xlsx)'),
              onTap: () async {
                Navigator.pop(ctx);
                await _runExport(() => ExportService.kaneevExcel());
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF'),
              onTap: () async {
                Navigator.pop(ctx);
                await _runExport(() => ExportService.kaneevPdf());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _runExport(Future<void> Function() task) async {
    try {
      await task();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppTheme.successSnackBar('Export ready'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppTheme.errorSnackBar('Export failed'));
      }
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label,
          style:
              TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: AppTheme.primary,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildFlatList(
      List<KaneevMemberSlot> filtered, Set<int> recipientMemberIds) {
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) =>
          _buildMemberTile(filtered[i], recipientMemberIds),
    );
  }

  Widget _buildGroupedList(
      List<KaneevMemberSlot> filtered, Set<int> recipientMemberIds) {
    // Group by ayalkoottam
    final Map<String, List<KaneevMemberSlot>> grouped = {};
    for (final m in filtered) {
      final key = m.ayalkoottamName ?? 'Other';
      grouped.putIfAbsent(key, () => []).add(m);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (ctx, gi) {
        final akName = sortedKeys[gi];
        final groupMembers = grouped[akName]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              child: Row(
                children: [
                  const Icon(Icons.group, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(akName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                  ),
                  Text('${groupMembers.length}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            ...groupMembers.map((m) => _buildMemberTile(m, recipientMemberIds)),
          ],
        );
      },
    );
  }

  Widget _buildMemberTile(KaneevMemberSlot m, Set<int> recipientMemberIds) {
    final hasReceived = recipientMemberIds.contains(m.memberId);
    final joined = _formatJoinedDate(m.joinedDate);
    final subtitleLines = <Widget>[];
    if (!_groupByAyalkoottam && m.ayalkoottamName != null) {
      subtitleLines.add(Text(m.ayalkoottamName!,
          style: const TextStyle(fontSize: 11, color: AppTheme.primary)));
    } else if (m.memberCode != null) {
      subtitleLines.add(Text(m.memberCode!,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)));
    }
    subtitleLines.add(Text(
      'Joined: ${joined ?? '-'}  ·  Paid: ₹${m.totalPaid.toStringAsFixed(0)}',
      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
    ));

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: hasReceived
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        child: Text('${m.slotNumber ?? '-'}',
            style: const TextStyle(fontSize: 13)),
      ),
      title: Text(m.memberName ?? 'Member #${m.memberId}',
          style: const TextStyle(fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subtitleLines,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasReceived)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('Received',
                  style: TextStyle(fontSize: 10, color: Colors.white)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Pending', style: TextStyle(fontSize: 10)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'deactivate') {
                _confirmSetStatus(context, m, 'withdrawn');
              } else if (value == 'delete') {
                _confirmRemoveMember(context, m);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'deactivate',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 18, color: Colors.orange),
                    SizedBox(width: 10),
                    Text('Deactivate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                    SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _formatJoinedDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return DateFormat('dd MMM yyyy').format(dt.toLocal());
  }

  void _confirmSetStatus(
      BuildContext context, KaneevMemberSlot member, String status) {
    final deactivating = status == 'withdrawn';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(deactivating ? 'Deactivate Member' : 'Activate Member'),
        content: Text(deactivating
            ? 'Set ${member.memberName ?? 'this member'} as inactive? Their payment history will be kept.'
            : 'Set ${member.memberName ?? 'this member'} as active?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<KaneevProvider>();
              final success =
                  await provider.setMemberStatus(member.memberId, status);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  success
                      ? AppTheme.successSnackBar(deactivating
                          ? 'Member deactivated'
                          : 'Member activated')
                      : AppTheme.errorSnackBar(
                          provider.error ?? 'Failed to update member'),
                );
              }
            },
            child: Text(deactivating ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, KaneevMemberSlot member) {
    final hasPayments = member.totalPaid > 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.outline,
                      borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 20),
              Icon(
                  hasPayments
                      ? Icons.info_outline
                      : Icons.warning_amber_rounded,
                  color: hasPayments ? Colors.orange : AppTheme.error,
                  size: 40),
              const SizedBox(height: 12),
              Text(hasPayments ? 'Cannot Delete' : 'Delete Member',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  hasPayments
                      ? '${member.memberName ?? 'This member'} has already paid ₹${member.totalPaid.toStringAsFixed(0)}. Members with payments cannot be deleted — you can deactivate them instead.'
                      : 'Do you want to delete ${member.memberName ?? 'this member'} from the Kaneev group?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final provider = context.read<KaneevProvider>();
                        if (hasPayments) {
                          final success = await provider.setMemberStatus(
                              member.memberId, 'withdrawn');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              success
                                  ? AppTheme.successSnackBar(
                                      'Member deactivated')
                                  : AppTheme.errorSnackBar(provider.error ??
                                      'Failed to deactivate member'),
                            );
                          }
                        } else {
                          final success =
                              await provider.removeMember(member.memberId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              success
                                  ? AppTheme.successSnackBar('Member deleted')
                                  : AppTheme.errorSnackBar(provider.error ??
                                      'Failed to delete member'),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            hasPayments ? Colors.orange : AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(hasPayments ? 'Deactivate' : 'Delete'),
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
}

// ── Recipients Tab ──
class _RecipientsTab extends StatefulWidget {
  final KaneevGroup group;
  const _RecipientsTab({required this.group});

  @override
  State<_RecipientsTab> createState() => _RecipientsTabState();
}

class _RecipientsTabState extends State<_RecipientsTab> {
  int? _selectedMonthNumber; // null = all months
  late List<_MonthOption> _monthOptions;

  @override
  void initState() {
    super.initState();
    _monthOptions = _buildMonthOptions();
  }

  List<KaneevRecipient> get _filteredRecipients {
    final recipients = widget.group.recipients ?? [];
    if (_selectedMonthNumber == null) return recipients;
    return recipients.where((r) => r.monthNumber == _selectedMonthNumber).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recipients = _filteredRecipients;

    return Column(
      children: [
        // Filter bar
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int?>(
                  value: _selectedMonthNumber,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Months'),
                    ),
                    ...(_monthOptions
                        .map((opt) => DropdownMenuItem(
                              value: opt.monthNumber,
                              child: Text(opt.label),
                            ))
                        .toList()),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedMonthNumber = val);
                  },
                ),
              ),
            ],
          ),
        ),
        if (recipients.isEmpty)
          Expanded(
              child: Center(
                  child: Text(_selectedMonthNumber == null
                      ? 'No recipients yet'
                      : 'No recipients for selected month')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: recipients.length,
              itemBuilder: (ctx, i) {
                final r = recipients[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      child: Text(_monthShort(r.monthNumber),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    title: Text(r.memberName ?? 'Member #${r.memberId}'),
                    subtitle: Text(
                        '${_monthLabel(r.monthNumber)} • ₹${r.totalAmount?.toStringAsFixed(0) ?? '0'}'),
                    trailing: Text(
                      r.receivedDate?.split('T')[0] ?? '',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Balance Tab ──
class _BalanceTab extends StatefulWidget {
  final KaneevGroup group;
  const _BalanceTab({required this.group});

  @override
  State<_BalanceTab> createState() => _BalanceTabState();
}

class _BalanceTabState extends State<_BalanceTab> {
  int? _selectedMonthNumber; // null = all months
  late List<_MonthOption> _monthOptions;

  @override
  void initState() {
    super.initState();
    _monthOptions = _buildMonthOptions();
  }

  List<KaneevBalanceLog> get _filteredLogs {
    final logs = widget.group.balanceLogs ?? [];
    if (_selectedMonthNumber == null) return logs;
    return logs.where((log) => log.monthNumber == _selectedMonthNumber).toList();
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;
    final allLogs = widget.group.balanceLogs ?? [];

    return Column(
      children: [
        // Summary card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('Current Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '₹${widget.group.currentBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.group.currentBalance > 0
                    ? 'Surplus'
                    : widget.group.currentBalance < 0
                        ? 'Deficit'
                        : 'Balanced',
                style: TextStyle(
                  color: widget.group.currentBalance >= 0
                      ? AppTheme.accentSoft
                      : Theme.of(context).colorScheme.errorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Filter bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int?>(
                  value: _selectedMonthNumber,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Months'),
                    ),
                    ...(_monthOptions
                        .map((opt) => DropdownMenuItem(
                              value: opt.monthNumber,
                              child: Text(opt.label),
                            ))
                        .toList()),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedMonthNumber = val);
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Monthly Balance History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('${logs.length}/${allLogs.length} months',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (logs.isEmpty)
          Expanded(
              child: Center(
                  child: Text(_selectedMonthNumber == null
                      ? 'No balance data yet.\nRecord donations & select recipients to see balance.'
                      : 'No data for selected month.')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (ctx, i) {
                final log = logs[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              child: Text(_monthShort(log.monthNumber),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryDark)),
                            ),
                            const SizedBox(width: 12),
                            Text(_monthLabel(log.monthNumber),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: log.cumulativeBalance >= 0
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '₹${log.cumulativeBalance.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: log.cumulativeBalance >= 0
                                      ? AppTheme.primary
                                      : AppTheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _balanceItem(
                                  'Collected',
                                  '₹${log.totalCollected.toStringAsFixed(0)}',
                                  AppTheme.primary),
                            ),
                            Expanded(
                              child: _balanceItem(
                                  'Distributed',
                                  '₹${log.totalDistributed.toStringAsFixed(0)}',
                                  AppTheme.accent),
                            ),
                            Expanded(
                              child: _balanceItem(
                                'Month Bal.',
                                '${log.monthBalance >= 0 ? '+' : ''}₹${log.monthBalance.toStringAsFixed(0)}',
                                log.monthBalance >= 0
                                    ? AppTheme.primary
                                    : AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _balanceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: color, fontSize: 13)),
      ],
    );
  }
}
