import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/kaneev_provider.dart';
import '../../../providers/ayalkoottam_provider.dart';
import '../../../providers/member_provider.dart';
import '../../../models/kaneev_group.dart';
import '../../../models/member.dart';
import '../../../services/kaneev_service.dart';

class KaneevDetailScreen extends StatefulWidget {
  const KaneevDetailScreen({super.key});

  @override
  State<KaneevDetailScreen> createState() => _KaneevDetailScreenState();
}

class _KaneevDetailScreenState extends State<KaneevDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      Future.microtask(() => context.read<KaneevProvider>().loadKaneev());
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
        appBar: AppBar(title: const Text('Kaneev')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Members'),
            Tab(text: 'Recipients'),
            Tab(text: 'Balance'),
          ],
        ),
      ),
      floatingActionButton: _buildFab(group),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoTab(group: group),
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
        if (_tabController.index == 1) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'donate',
                onPressed: () => _showRecordDonationDialog(group),
                icon: const Icon(Icons.payments),
                label: const Text('Record Donation'),
                backgroundColor: Colors.deepPurple,
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
        } else if (_tabController.index == 2) {
          return FloatingActionButton.extended(
            onPressed: () => _showSelectRecipientDialog(group),
            icon: const Icon(Icons.card_giftcard),
            label: const Text('Select Recipient'),
            backgroundColor: Colors.deepPurple,
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

  void _showRecordDonationDialog(KaneevGroup group) {
    final enrolledMembers = group.members ?? [];
    if (enrolledMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No members enrolled')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No members enrolled')));
      return;
    }

    final recipientMemberIds = (group.recipients ?? []).map((r) => r.memberId).toSet();
    final eligibleMembers = enrolledMembers.where((m) => !recipientMemberIds.contains(m.memberId)).toList();

    if (eligibleMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All members have already received')));
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
  const _MonthOption({required this.year, required this.monthIndex, required this.monthNumber, required this.label});
}

List<_MonthOption> _buildMonthOptions() {
  const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  final now = DateTime.now();
  final opts = <_MonthOption>[];
  for (int y = 2025; y <= now.year + 1; y++) {
    for (int m = 0; m < 12; m++) {
      opts.add(_MonthOption(year: y, monthIndex: m, monthNumber: (y - 2025) * 12 + (m + 1), label: '${names[m]} $y'));
    }
  }
  return opts;
}

// ── Select Recipient Sheet ──
class _SelectRecipientSheet extends StatefulWidget {
  final List<KaneevMemberSlot> eligibleMembers;
  final int recipientCount;
  final KaneevGroup group;
  const _SelectRecipientSheet({required this.eligibleMembers, required this.recipientCount, required this.group});

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
      list = list.where((m) => m.ayalkoottamName == _selectedAyalkoottam).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) =>
        (m.memberName?.toLowerCase().contains(q) ?? false) ||
        (m.memberCode?.toLowerCase().contains(q) ?? false)
      ).toList();
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
    context.read<KaneevProvider>().selectRecipient(_selectedMemberId!, _monthNumber);
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Text('Select Recipient', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close, size: 22), onPressed: () => Navigator.pop(context), splashRadius: 20),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Month dropdown
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                value: _monthNumber,
                isExpanded: true,
                items: monthOpts.map((opt) => DropdownMenuItem(value: opt.monthNumber, child: Text(opt.label, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) {
                  if (v != null) {
                    final opt = monthOpts.firstWhere((o) => o.monthNumber == v);
                    setState(() { _selectedYear = opt.year; _selectedMonthIdx = opt.monthIndex; });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Ayalkoottam filter + search
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Ayalkoottam', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      value: _selectedAyalkoottam,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ..._ayalkoottamList.map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) => setState(() { _selectedAyalkoottam = v; _selectedMemberId = null; }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search member...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                onChanged: (v) => setState(() { _searchQuery = v; _selectedMemberId = null; }),
              ),
              const SizedBox(height: 4),

              // Info bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${filtered.length} eligible', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const Spacer(),
                    if (widget.recipientCount > 0)
                      Text('${widget.recipientCount} already received', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
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
                            selectedTileColor: Colors.deepPurple.shade50,
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? Colors.deepPurple : Colors.grey.shade200,
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : Text(m.memberName?[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 14)),
                            ),
                            title: Text(m.memberName ?? 'Member #${m.memberId}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (m.ayalkoottamName != null)
                                  Text(m.ayalkoottamName!, style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade400)),
                                if (m.memberCode != null)
                                  Text(m.memberCode!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                            onTap: () => setState(() => _selectedMemberId = m.memberId),
                          );
                        },
                      ),
              ),

              // Confirm button
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _selectedMemberId != null ? _confirmRecipient : null,
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('Confirm Recipient'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
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
  final Set<int> _paidMemberIds = {};
  final Map<int, String?> _paidDates = {}; // memberId -> paid_date

  int get _monthNumber {
    // Compute a sequential month number from a reference start (Jan 2025 = 1)
    return (_selectedYear - 2025) * 12 + (_selectedMonthIndex + 1);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonthIndex = now.month - 1;
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    setState(() => _loading = true);
    try {
      final donations = await KaneevService.getDonations(monthNumber: _monthNumber);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Donation recorded ✓')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<KaneevProvider>().error ?? 'Error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Record Donations - ₹${widget.group.donationAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close, size: 22), onPressed: () => Navigator.pop(context), splashRadius: 20),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: _monthNumber,
                      isExpanded: true,
                      items: _buildMonthOptions().map((opt) => DropdownMenuItem(
                        value: opt.monthNumber,
                        child: Text(opt.label, style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          final opt = _buildMonthOptions().firstWhere((o) => o.monthNumber == v);
                          setState(() {
                            _selectedYear = opt.year;
                            _selectedMonthIndex = opt.monthIndex;
                          });
                          _loadDonations();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${_paidMemberIds.length}/${members.length} paid',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
              const Divider(),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: members.length,
                    itemBuilder: (ctx, i) {
                      final m = members[i];
                      final isPaid = _paidMemberIds.contains(m.memberId);
                      final paidDate = _paidDates[m.memberId];
                      final paidDateStr = paidDate != null ? paidDate.split('T')[0] : null;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPaid ? Colors.green.shade50 : Colors.grey.shade100,
                          child: isPaid
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : Text(m.memberName?[0].toUpperCase() ?? '?'),
                        ),
                        title: Text(m.memberName ?? 'Member #${m.memberId}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m.ayalkoottamName != null)
                              Text(m.ayalkoottamName!, style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade400)),
                            Text(isPaid
                                ? 'Paid ₹${widget.group.donationAmount.toStringAsFixed(0)} ✓${paidDateStr != null ? ' • $paidDateStr' : ''}'
                                : 'Pending'),
                          ],
                        ),
                        trailing: isPaid
                            ? const Icon(Icons.check, color: Colors.green)
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                                onPressed: () => _recordDonation(m.memberId),
                                child: const Text('₹ Pay', style: TextStyle(color: Colors.white)),
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Text('Add Member to Kaneev', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close, size: 22), onPressed: () => Navigator.pop(context), splashRadius: 20),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Filter by Ayalkoottam', border: OutlineInputBorder()),
                value: _selectedAyalkoottamId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...dropdownList.map((ak) => DropdownMenuItem(value: ak.id, child: Text(ak.name))),
                ],
                onChanged: (v) {
                  setState(() => _selectedAyalkoottamId = v);
                  _loadMembers(v);
                },
              ),
              const SizedBox(height: 12),
              if (_loadingMembers)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else
                Expanded(
                  child: _filteredMembers.isEmpty
                      ? const Center(child: Text('Select an ayalkoottam to see members'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _filteredMembers.length,
                          itemBuilder: (ctx, i) {
                            final m = _filteredMembers[i];
                            return ListTile(
                              leading: CircleAvatar(child: Text(m.name[0].toUpperCase())),
                              title: Text(m.name),
                              subtitle: Text(m.phone ?? ''),
                              trailing: ElevatedButton(
                                onPressed: () => _addMember(m.id),
                                child: const Text('Add'),
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
    setState(() => _loadingMembers = true);
    try {
      final provider = context.read<MemberProvider>();
      await provider.loadMembers(ayalkoottamId: ayalkoottamId);
      setState(() {
        _filteredMembers = provider.members;
        _loadingMembers = false;
      });
    } catch (_) {
      setState(() => _loadingMembers = false);
    }
  }

  Future<void> _addMember(int memberId) async {
    final success = await context.read<KaneevProvider>().addMember(memberId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added successfully')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<KaneevProvider>().error ?? 'Error')));
      }
    }
  }
}

// ── Info Tab ──
class _InfoTab extends StatelessWidget {
  final KaneevGroup group;
  const _InfoTab({required this.group});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Code', group.code),
        _editableAmountRow(context),
        _infoRow('Status', group.status.toUpperCase()),
        _infoRow('Enrolled Members', '${group.members?.length ?? 0}'),
        _infoRow('Recipients so far', '${group.recipients?.length ?? 0}'),
        _infoRow('Current Balance', '₹${group.currentBalance.toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _editableAmountRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Donation Amount', style: TextStyle(color: Colors.grey.shade600)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹${group.donationAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _showEditAmountDialog(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit, size: 18, color: Colors.deepPurple.shade400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditAmountDialog(BuildContext context) {
    final controller = TextEditingController(text: group.donationAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Donation Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (₹)',
            border: OutlineInputBorder(),
            prefixText: '₹ ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount <= 0) return;
              Navigator.pop(ctx);
              final success = await context.read<KaneevProvider>().updateDonationAmount(amount);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.read<KaneevProvider>().error ?? 'Error'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
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
}

// ── Members Tab ──
class _MembersTab extends StatelessWidget {
  final KaneevGroup group;
  const _MembersTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final members = group.members ?? [];
    final recipientMemberIds = (group.recipients ?? []).map((r) => r.memberId).toSet();

    if (members.isEmpty) {
      return const Center(child: Text('No members enrolled'));
    }

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (ctx, i) {
        final m = members[i];
        final hasReceived = recipientMemberIds.contains(m.memberId);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: hasReceived ? Colors.green.shade50 : Colors.deepPurple.shade50,
            child: Text('${m.slotNumber ?? (i + 1)}'),
          ),
          title: Text(m.memberName ?? 'Member #${m.memberId}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.ayalkoottamName != null)
                Text(m.ayalkoottamName!, style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade400)),
              Text(m.memberCode ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          trailing: hasReceived
              ? Chip(
                  label: const Text('Received', style: TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: Colors.green,
                )
              : Chip(
                  label: const Text('Pending', style: TextStyle(fontSize: 11)),
                  backgroundColor: Colors.orange.shade100,
                ),
        );
      },
    );
  }
}

// ── Recipients Tab ──
class _RecipientsTab extends StatelessWidget {
  final KaneevGroup group;
  const _RecipientsTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final recipients = group.recipients ?? [];

    if (recipients.isEmpty) {
      return const Center(child: Text('No recipients yet'));
    }

    return ListView.builder(
      itemCount: recipients.length,
      itemBuilder: (ctx, i) {
        final r = recipients[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade50,
              child: Text('${r.monthNumber}'),
            ),
            title: Text(r.memberName ?? 'Member #${r.memberId}'),
            subtitle: Text('Month ${r.monthNumber} • ₹${r.totalAmount?.toStringAsFixed(0) ?? '0'}'),
            trailing: Text(
              r.receivedDate?.split('T')[0] ?? '',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}

// ── Balance Tab ──
class _BalanceTab extends StatelessWidget {
  final KaneevGroup group;
  const _BalanceTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final logs = group.balanceLogs ?? [];

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('Current Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '₹${group.currentBalance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                group.currentBalance > 0 ? 'Surplus' : group.currentBalance < 0 ? 'Deficit' : 'Balanced',
                style: TextStyle(
                  color: group.currentBalance >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Monthly Balance History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('${logs.length} months', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (logs.isEmpty)
          const Expanded(child: Center(child: Text('No balance data yet.\nRecord donations & select recipients to see balance.', textAlign: TextAlign.center)))
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
                              backgroundColor: Colors.deepPurple.shade50,
                              child: Text('${log.monthNumber}', style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade700)),
                            ),
                            const SizedBox(width: 12),
                            Text('Month ${log.monthNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: log.cumulativeBalance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '₹${log.cumulativeBalance.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: log.cumulativeBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _balanceItem('Collected', '₹${log.totalCollected.toStringAsFixed(0)}', Colors.blue),
                            ),
                            Expanded(
                              child: _balanceItem('Distributed', '₹${log.totalDistributed.toStringAsFixed(0)}', Colors.orange),
                            ),
                            Expanded(
                              child: _balanceItem(
                                'Month Bal.',
                                '${log.monthBalance >= 0 ? '+' : ''}₹${log.monthBalance.toStringAsFixed(0)}',
                                log.monthBalance >= 0 ? Colors.green : Colors.red,
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
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
      ],
    );
  }
}
