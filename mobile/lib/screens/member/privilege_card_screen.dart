import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/privilege_card.dart';
import '../../providers/auth_provider.dart';
import '../../services/privilege_card_service.dart';
import '../../widgets/app_bottom_sheet.dart';

class PrivilegeCardScreen extends StatefulWidget {
  const PrivilegeCardScreen({super.key});

  @override
  State<PrivilegeCardScreen> createState() => _PrivilegeCardScreenState();
}

class _PrivilegeCardScreenState extends State<PrivilegeCardScreen> {
  PrivilegeCard? _card;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _card = await PrivilegeCardService.getMyCard();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Privilege Card')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _card == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.card_membership, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(_error ?? 'No card available', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      MemberPrivilegeCard(
                        card: _card!,
                        memberName: _card!.memberName ?? user?.name ?? 'Member',
                        organizationName: _card!.organizationName ?? 'Sangamam',
                        ayalkoottamName: _card!.ayalkoottamName,
                        photoUrl: user?.photoUrl,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWarm,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
                        ),
                        child: Text(
                          'QR code is now included inside the privilege card itself so the full card is available in one compact view.',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
