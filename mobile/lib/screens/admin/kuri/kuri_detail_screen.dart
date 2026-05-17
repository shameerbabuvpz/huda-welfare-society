import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/kuri_provider.dart';
import '../../../providers/ayalkoottam_provider.dart';
import '../../../providers/member_provider.dart';
import '../../../models/kuri_group.dart';
import '../../../models/member.dart';
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
        Future.microtask(() => context.read<KuriProvider>().loadGroupDetail(args));
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
            Tab(text: 'Info'),
            Tab(text: 'Members'),
            Tab(text: 'Winners'),
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
        if (_tabController.index == 1) {
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
                      value: selectedMonth,
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
                      value: selectedYear,
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
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Filter by Ayalkoottam', border: OutlineInputBorder()),
              value: _selectedAyalkoottamId,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...dropdownList.map((ak) => DropdownMenuItem(value: ak.id, child: Text(ak.name))),
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
            // Bottom action bar
            if (_selectedMemberIds.isNotEmpty)
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
            if (_addedCount > 0 && _selectedMemberIds.isEmpty)
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
}

class _InfoTab extends StatelessWidget {
  final KuriGroup group;
  const _InfoTab({required this.group});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
        return ListTile(
          leading: CircleAvatar(child: Text('${m.slotNumber ?? i + 1}')),
          title: Text(m.memberName ?? 'Member #${m.memberId}'),
          subtitle: Text(m.memberCode ?? ''),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: m.status == 'active'
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(m.status, style: TextStyle(fontSize: 12, color: m.status == 'active' ? AppTheme.primary : AppTheme.error)),
          ),
        );
      },
    );
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
