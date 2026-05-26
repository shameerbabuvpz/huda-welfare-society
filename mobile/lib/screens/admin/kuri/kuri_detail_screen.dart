import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/kuri_provider.dart';
import '../../../providers/ayalkoottam_provider.dart';
import '../../../providers/member_provider.dart';
import '../../../models/kuri_group.dart';
import '../../../models/member.dart';
import '../../../utils/ak_name_helper.dart';
import '../../../widgets/app_bottom_sheet.dart';

class KuriDetailScreen extends StatefulWidget {
  const KuriDetailScreen({super.key});

  @override
  State<KuriDetailScreen> createState() => _KuriDetailScreenState();
}

class _KuriDetailScreenState extends State<KuriDetailScreen> with SingleTickerProviderStateMixin {
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
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _loaded = true;
        context.read<KuriProvider>().loadGroupDetail(args);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KuriProvider>();
    final group = provider.selectedGroup;

    if (provider.loading || group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kuri Detail')),
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
            Tab(child: Text('Info', maxLines: 2, textAlign: TextAlign.center)),
            Tab(child: Text('Members', maxLines: 2, textAlign: TextAlign.center)),
            Tab(child: Text('Winners', maxLines: 2, textAlign: TextAlign.center)),
          ],
        ),
      ),
      floatingActionButton: _buildFab(group),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoTab(group: group),
          _MembersTab(group: group),
          _WinnersTab(group: group),
        ],
      ),
    );
  }

  Widget? _buildFab(KuriGroup group) {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, _) {
        if (_tabController.index == 0) {
          return FloatingActionButton.extended(
            heroTag: 'recordCollection',
            onPressed: () => _showRecordCollectionDialog(group),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Record Collection'),
          );
        } else if (_tabController.index == 1) {
          return FloatingActionButton.extended(
            onPressed: () => _showAddMemberDialog(group),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Member'),
          );
        } else if (_tabController.index == 2) {
          return FloatingActionButton.extended(
            onPressed: () => _showSelectWinnerDialog(group),
            icon: const Icon(Icons.emoji_events),
            label: const Text('Select Winner'),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showEditGroupDialog(KuriGroup group) {
    final amountCtrl = TextEditingController(text: group.monthlyAmount.toStringAsFixed(0));
    final durationCtrl = TextEditingController(text: '${group.durationMonths}');
    final nameCtrl = TextEditingController(text: group.name);

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
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(99))),
                const SizedBox(height: 20),
                Text('Edit Kuri Group', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Group Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monthly Amount (₹)', border: OutlineInputBorder(), prefixText: '₹ '),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (months)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
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
                        onPressed: () {
                          final data = <String, dynamic>{};
                          if (nameCtrl.text.trim().isNotEmpty) data['name'] = nameCtrl.text.trim();
                          final amount = double.tryParse(amountCtrl.text);
                          if (amount != null && amount > 0) data['monthly_amount'] = amount;
                          final duration = int.tryParse(durationCtrl.text);
                          if (duration != null && duration > 0) data['duration_months'] = duration;
                          if (data.isEmpty) return;
                          Navigator.pop(ctx);
                          context.read<KuriProvider>().updateGroup(group.id, data);
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

  void _showRecordCollectionDialog(KuriGroup group) {
    final enrolledMembers = group.members ?? [];
    if (enrolledMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.infoSnackBar('No members enrolled'));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RecordCollectionSheet(group: group),
    );
  }

  void _showAddMemberDialog(KuriGroup group) {
    context.read<AyalkoottamProvider>().loadDropdown();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMemberSheet(groupId: group.id),
    );
  }

  void _showSelectWinnerDialog(KuriGroup group) {
    final enrolledMembers = group.members ?? [];
    if (enrolledMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.infoSnackBar('No members enrolled'));
      return;
    }

    int? selectedMemberId;
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;
    final years = [now.year - 1, now.year, now.year + 1, now.year + 2];
    const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    // Calculate month_number from start_date + selected month/year
    int calcMonthNumber() {
      try {
        final start = DateTime.parse(group.startDate);
        return (selectedYear - start.year) * 12 + (selectedMonth - start.month) + 1;
      } catch (_) {
        return 1;
      }
    }

    showAppBottomSheet(
      context: context,
      title: 'Select Winner',
      initialChildSize: 0.55,
      bodyBuilder: (ctx, sc) => StatefulBuilder(
        builder: (ctx, setSheetState) => SingleChildScrollView(
          controller: sc,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Member', border: OutlineInputBorder()),
                items: enrolledMembers.map((m) => DropdownMenuItem(
                  value: m.memberId,
                  child: Text(m.memberName ?? 'Member #${m.memberId}'),
                )).toList(),
                onChanged: (v) => setSheetState(() => selectedMemberId = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                      initialValue: selectedMonth,
                      items: List.generate(12, (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(monthNames[i]),
                      )),
                      onChanged: (v) => setSheetState(() => selectedMonth = v ?? selectedMonth),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                      initialValue: selectedYear,
                      items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                      onChanged: (v) => setSheetState(() => selectedYear = v ?? selectedYear),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedMemberId == null) return;
                    Navigator.pop(ctx);
                    context.read<KuriProvider>().selectWinner(
                      group.id,
                      selectedMemberId!,
                      calcMonthNumber(),
                    );
                  },
                  child: const Text('Confirm Winner'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  final int groupId;
  const _AddMemberSheet({required this.groupId});

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  int? _selectedAyalkoottamId;
  List<Member> _filteredMembers = [];
  bool _loadingMembers = false;
  final Set<int> _selectedMemberIds = {};
  final Set<int> _addedMemberIds = {};
  bool _adding = false;
  int _addedCount = 0;
  bool _guestMode = false;
  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  bool _addingGuest = false;

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    super.dispose();
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
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: Text('Add Members to Kuri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                if (_addedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('$_addedCount added', style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Toggle: Members / Guest
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Members'), icon: Icon(Icons.people, size: 18)),
                      ButtonSegment(value: true, label: Text('Guest'), icon: Icon(Icons.person_add_alt, size: 18)),
                    ],
                    selected: {_guestMode},
                    onSelectionChanged: (v) => setState(() => _guestMode = v.first),
                    style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_guestMode) ...[
              // Guest add form
              TextField(
                controller: _guestNameController,
                decoration: const InputDecoration(
                  labelText: 'Guest Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _guestPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _addingGuest || _guestNameController.text.trim().isEmpty
                      ? null
                      : _addGuest,
                  icon: _addingGuest
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.person_add),
                  label: Text(_addingGuest ? 'Adding...' : 'Add Guest to Kuri'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Guests are people outside the Ayalkoottam who participate only in this Kuri.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ] else ...[
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Filter by Ayalkoottam', border: OutlineInputBorder()),
              value: _selectedAyalkoottamId,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...dropdownList.map((ak) => DropdownMenuItem(value: ak.id, child: Text(shortAkName(ak.name)))),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedAyalkoottamId = v;
                  _selectedMemberIds.clear();
                });
                _loadMembers(v);
              },
            ),
            const SizedBox(height: 12),
            if (_loadingMembers)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_filteredMembers.isEmpty)
              const Expanded(child: Center(child: Text('Select an ayalkoottam to see members')))
            else ...[
              // Select all / count row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${_filteredMembers.length} members',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    if (_selectedMemberIds.isNotEmpty)
                      Text(
                        '${_selectedMemberIds.length} selected',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          final selectableIds = _filteredMembers
                              .where((m) => !_addedMemberIds.contains(m.id))
                              .map((m) => m.id)
                              .toSet();
                          if (_selectedMemberIds.containsAll(selectableIds)) {
                            _selectedMemberIds.clear();
                          } else {
                            _selectedMemberIds.addAll(selectableIds);
                          }
                        });
                      },
                      child: Text(
                        _selectedMemberIds.length == _filteredMembers.where((m) => !_addedMemberIds.contains(m.id)).length && _selectedMemberIds.isNotEmpty
                            ? 'Deselect All'
                            : 'Select All',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredMembers.length,
                  itemBuilder: (ctx, i) {
                    final m = _filteredMembers[i];
                    final isAdded = _addedMemberIds.contains(m.id);
                    final isSelected = _selectedMemberIds.contains(m.id);
                    return ListTile(
                      leading: isAdded
                        ? CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.check, color: AppTheme.primary))
                          : CircleAvatar(
                          backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : null,
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : Text(m.name[0].toUpperCase()),
                            ),
                      title: Text(m.name, style: TextStyle(color: isAdded ? Colors.grey : null)),
                      subtitle: Text(m.phone ?? '', style: TextStyle(color: isAdded ? Colors.grey.shade400 : null)),
                      trailing: isAdded
                          ? const Text('Added', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600))
                          : null,
                      onTap: isAdded ? null : () {
                        setState(() {
                          if (isSelected) {
                            _selectedMemberIds.remove(m.id);
                          } else {
                            _selectedMemberIds.add(m.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            ], // end else (members mode)
            // Bottom action bar
            if (!_guestMode && _selectedMemberIds.isNotEmpty)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _adding ? null : _addSelectedMembers,
                      icon: _adding
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.group_add),
                      label: Text(_adding ? 'Adding...' : 'Add ${_selectedMemberIds.length} Member${_selectedMemberIds.length > 1 ? 's' : ''}'),
                    ),
                  ),
                ),
              ),
            if (_addedCount > 0 && (_guestMode || _selectedMemberIds.isEmpty))
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
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

  Future<void> _addSelectedMembers() async {
    setState(() => _adding = true);
    final kuriProvider = context.read<KuriProvider>();
    int successCount = 0;
    final ids = _selectedMemberIds.toList();

    for (final memberId in ids) {
      final success = await kuriProvider.addMember(widget.groupId, memberId);
      if (success) {
        successCount++;
        if (mounted) {
          setState(() {
            _addedMemberIds.add(memberId);
            _selectedMemberIds.remove(memberId);
            _addedCount += 1;
          });
        }
      }
    }

    if (mounted) {
      setState(() => _adding = false);
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('$successCount member${successCount > 1 ? 's' : ''} added successfully'),
        );
      }
      if (successCount < ids.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('${ids.length - successCount} member${ids.length - successCount > 1 ? 's' : ''} failed'),
        );
      }
    }
  }

  Future<void> _addGuest() async {
    final name = _guestNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _addingGuest = true);
    final success = await context.read<KuriProvider>().addGuestMember(
      widget.groupId,
      name: name,
      phone: _guestPhoneController.text.trim(),
    );
    if (mounted) {
      setState(() => _addingGuest = false);
      if (success) {
        _guestNameController.clear();
        _guestPhoneController.clear();
        _addedCount += 1;
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Guest "$name" added to Kuri'),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(context.read<KuriProvider>().error ?? 'Failed to add guest'),
        );
      }
    }
  }
}

class _InfoTab extends StatelessWidget {
  final KuriGroup group;
  const _InfoTab({required this.group});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                final state = context.findAncestorStateOfType<_KuriDetailScreenState>();
                state?._showEditGroupDialog(group);
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
          ],
        ),
        _infoRow('Code', group.code),
        _infoRow('Monthly Amount', '₹${group.monthlyAmount.toStringAsFixed(2)}'),
        _infoRow('Total Members', '${group.totalMembers}'),
        _infoRow('Duration', '${group.durationMonths} months'),
        _infoRow('Start Date', group.startDate),
        _infoRow('Status', group.status.toUpperCase()),
        _infoRow('Enrolled', '${group.members?.length ?? 0} / ${group.totalMembers}'),
      ],
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

class _MembersTab extends StatelessWidget {
  final KuriGroup group;
  const _MembersTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final members = group.members ?? [];
    if (members.isEmpty) return const Center(child: Text('No members enrolled'));

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (ctx, i) {
        final m = members[i];
        final subtitle = [
          if (m.isGuest) 'Guest',
          if (m.ayalkoottamName != null && m.ayalkoottamName!.isNotEmpty) m.ayalkoottamName!,
          if (m.memberPhone != null && m.memberPhone!.isNotEmpty) m.memberPhone!,
        ].join(' • ');

        return ListTile(
          leading: CircleAvatar(child: Text('${m.slotNumber ?? i + 1}')),
          title: Text(m.memberName ?? 'Member'),
          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: m.status == 'active'
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(m.status, style: TextStyle(fontSize: 12, color: m.status == 'active' ? AppTheme.primary : AppTheme.error)),
              ),
              if (m.status == 'active')
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.error, size: 20),
                  tooltip: 'Remove member',
                  onPressed: () => _confirmRemove(context, m),
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmRemove(BuildContext context, KuriMemberSlot member) async {
    final confirm = await showConfirmSheet(
      context: context,
      title: 'Remove Member',
      message: 'Are you sure you want to remove ${member.memberName ?? 'this member'} from the kuri group?',
      confirmLabel: 'Remove',
      isDestructive: true,
      icon: Icons.person_remove_outlined,
    );
    if (confirm == true && context.mounted) {
      context.read<KuriProvider>().removeMember(group.id, member.memberId);
    }
  }
}

class _WinnersTab extends StatelessWidget {
  final KuriGroup group;
  const _WinnersTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final winners = group.winners ?? [];
    if (winners.isEmpty) return const Center(child: Text('No winners yet'));

    return ListView.builder(
      itemCount: winners.length,
      itemBuilder: (ctx, i) {
        final w = winners[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: const Icon(Icons.emoji_events, color: AppTheme.accent),
          ),
          title: Text(w.memberName ?? 'Member'),
          subtitle: Text('Month ${w.monthNumber} • ${w.wonDate}'),
          trailing: w.payoutAmount != null
              ? Text('₹${w.payoutAmount!.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary))
              : const Text('Pending', style: TextStyle(color: AppTheme.accent)),
        );
      },
    );
  }
}

// ── Record Collection Sheet ──
class _RecordCollectionSheet extends StatefulWidget {
  final KuriGroup group;
  const _RecordCollectionSheet({required this.group});

  @override
  State<_RecordCollectionSheet> createState() => _RecordCollectionSheetState();
}

class _RecordCollectionSheetState extends State<_RecordCollectionSheet> {
  final Set<int> _selectedMemberIds = {};
  final Set<int> _recordedMemberIds = {};
  bool _recording = false;
  int _recordedCount = 0;
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  int get _monthNumber {
    try {
      final start = DateTime.parse(widget.group.startDate);
      return (_selectedYear - start.year) * 12 + (_selectedMonth - start.month) + 1;
    } catch (_) {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members ?? [];
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final years = [DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Text('Record Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  if (_recordedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
                      child: Text('$_recordedCount recorded', style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  IconButton(icon: const Icon(Icons.close, size: 22), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Month/Year selector
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      initialValue: _selectedMonth,
                      items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(monthNames[i]))),
                      onChanged: (v) => setState(() => _selectedMonth = v ?? _selectedMonth),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      initialValue: _selectedYear,
                      items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                      onChanged: (v) => setState(() => _selectedYear = v ?? _selectedYear),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Month #$_monthNumber • ₹${widget.group.monthlyAmount.toStringAsFixed(0)} per member', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              // Select all row
              Row(
                children: [
                  Text('${members.length} members', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const Spacer(),
                  if (_selectedMemberIds.isNotEmpty)
                    Text('${_selectedMemberIds.length} selected', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        final selectableIds = members.where((m) => !_recordedMemberIds.contains(m.memberId)).map((m) => m.memberId).toSet();
                        if (_selectedMemberIds.containsAll(selectableIds)) {
                          _selectedMemberIds.clear();
                        } else {
                          _selectedMemberIds.addAll(selectableIds);
                        }
                      });
                    },
                    child: Text('Select All', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: members.length,
                  itemBuilder: (ctx, i) {
                    final m = members[i];
                    final isRecorded = _recordedMemberIds.contains(m.memberId);
                    final isSelected = _selectedMemberIds.contains(m.memberId);
                    return ListTile(
                      leading: isRecorded
                          ? CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.check, color: AppTheme.primary))
                          : CircleAvatar(
                              backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : null,
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : Text('${m.slotNumber ?? i + 1}'),
                            ),
                      title: Text(m.memberName ?? 'Member', style: TextStyle(color: isRecorded ? Colors.grey : null)),
                      subtitle: Text(m.memberCode ?? '', style: TextStyle(color: isRecorded ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                      trailing: isRecorded
                          ? const Text('✓ Paid', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600))
                          : null,
                      onTap: isRecorded ? null : () {
                        setState(() {
                          if (isSelected) {
                            _selectedMemberIds.remove(m.memberId);
                          } else {
                            _selectedMemberIds.add(m.memberId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              if (_selectedMemberIds.isNotEmpty)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _recording ? null : _recordSelected,
                        icon: _recording
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.payments),
                        label: Text(_recording ? 'Recording...' : 'Record ${_selectedMemberIds.length} Payment${_selectedMemberIds.length > 1 ? 's' : ''}'),
                        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                  ),
                ),
              if (_recordedCount > 0 && _selectedMemberIds.isEmpty)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: const Text('Done'),
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

  Future<void> _recordSelected() async {
    setState(() => _recording = true);
    final provider = context.read<KuriProvider>();
    int successCount = 0;
    final ids = _selectedMemberIds.toList();
    final monthNum = _monthNumber;

    for (final memberId in ids) {
      final success = await provider.recordCollection(widget.group.id, memberId: memberId, monthNumber: monthNum);
      if (success) {
        successCount++;
        if (mounted) {
          setState(() {
            _recordedMemberIds.add(memberId);
            _selectedMemberIds.remove(memberId);
            _recordedCount++;
          });
        }
      }
    }

    if (mounted) {
      setState(() => _recording = false);
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('$successCount collection${successCount > 1 ? 's' : ''} recorded'),
        );
      }
      if (successCount < ids.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('${ids.length - successCount} failed (may already be recorded)'),
        );
      }
    }
  }
}
