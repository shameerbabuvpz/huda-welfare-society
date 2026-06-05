import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../models/member.dart';
import '../../services/member_service.dart';

/// Member directory for the president/secretary of an ayalkoottam.
/// Shows every member of their own ayalkoottam with name, code, phone and a
/// one-tap call button.
class AyalkoottamMembersScreen extends StatefulWidget {
  const AyalkoottamMembersScreen({super.key});

  @override
  State<AyalkoottamMembersScreen> createState() => _AyalkoottamMembersScreenState();
}

class _AyalkoottamMembersScreenState extends State<AyalkoottamMembersScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _loading = true;
  String? _error;
  String? _ayalkoottamName;
  List<Member> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await MemberService.myAyalkoottamMembers(search: search);
      if (!mounted) return;
      setState(() {
        _ayalkoottamName = result.ayalkoottamName;
        _members = result.members;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearch(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _load(search: v.isEmpty ? null : v);
    });
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place a call to $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ayalkoottamName == null || _ayalkoottamName!.isEmpty
            ? 'Ayalkoottam Members'
            : _ayalkoottamName!),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search by name, code or phone',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => _load(), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_members.isEmpty) {
      return const Center(child: Text('No members found'));
    }
    return RefreshIndicator(
      onRefresh: () => _load(search: _searchController.text.isEmpty ? null : _searchController.text),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        itemCount: _members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, i) => _MemberTile(
          member: _members[i],
          onCall: _makeCall,
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onCall});

  final Member member;
  final Future<void> Function(String phone) onCall;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = member.photoUrl != null && member.photoUrl!.isNotEmpty;
    final hasPhone = member.phone != null && member.phone!.isNotEmpty;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.outline),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: hasPhoto ? CachedNetworkImageProvider(member.photoUrl!) : null,
          child: !hasPhoto
              ? Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?')
              : null,
        ),
        title: Row(
          children: [
            Flexible(child: Text(member.name, overflow: TextOverflow.ellipsis)),
            if (member.designation != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: member.designation == 'president'
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  member.designation == 'president' ? 'President' : 'Secretary',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: member.designation == 'president' ? AppTheme.accent : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${member.memberCode}', style: const TextStyle(fontSize: 12)),
            Text(
              hasPhone ? member.phone! : 'No phone',
              style: TextStyle(fontSize: 13, color: hasPhone ? null : Colors.grey),
            ),
          ],
        ),
        trailing: hasPhone
            ? IconButton(
                icon: const Icon(Icons.call, color: AppTheme.success),
                tooltip: 'Call ${member.name}',
                onPressed: () => onCall(member.phone!),
              )
            : null,
      ),
    );
  }
}
