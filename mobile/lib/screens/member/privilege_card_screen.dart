import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final GlobalKey _cardKey = GlobalKey();

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

  Future<Uint8List?> _captureCardImage() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _downloadCard() async {
    final bytes = await _captureCardImage();
    if (bytes == null || !mounted) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/privilege_card.png');
    await file.writeAsBytes(bytes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppTheme.successSnackBar('Card saved! Use Share to send it.'),
    );
  }

  Future<void> _shareCard() async {
    final bytes = await _captureCardImage();
    if (bytes == null || !mounted) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/privilege_card.png');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'My Privilege Card - ${_card?.organizationName ?? ""}',
    );
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
                      RepaintBoundary(
                        key: _cardKey,
                        child: Container(
                          color: AppTheme.background,
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              MemberPrivilegeCard(
                                card: _card!,
                                memberName: _card!.memberName ?? user?.name ?? 'Member',
                                organizationName: _card!.organizationName,
                                ayalkoottamName: _card!.ayalkoottamName,
                                photoUrl: _card!.photoUrl ?? user?.photoUrl,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _downloadCard,
                              icon: const Icon(Icons.download),
                              label: const Text('Save'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _shareCard,
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
