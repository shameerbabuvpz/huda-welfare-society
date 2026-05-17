import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/privilege_card.dart';

/// Common bottom sheet used across the app for a consistent UX.
/// Shows a draggable sheet from the bottom with full-width, rounded top corners,
/// a drag handle, a title row with optional close button, and scrollable content.
///
/// Use [showAppBottomSheet] for convenience.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context, ScrollController scrollController) bodyBuilder,
  double initialChildSize = 0.5,
  double maxChildSize = 0.9,
  double minChildSize = 0.3,
  bool isDismissible = true,
  bool enableDrag = true,
  List<Widget>? actions,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AppBottomSheetContent<T>(
      title: title,
      bodyBuilder: bodyBuilder,
      initialChildSize: initialChildSize,
      maxChildSize: maxChildSize,
      minChildSize: minChildSize,
      actions: actions,
    ),
  );
}

/// Simpler variant for confirm/action dialogs (no scroll controller needed).
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required Widget body,
  List<Widget>? actions,
  double initialChildSize = 0.4,
}) {
  return showAppBottomSheet<T>(
    context: context,
    title: title,
    initialChildSize: initialChildSize,
    maxChildSize: 0.9,
    minChildSize: 0.25,
    bodyBuilder: (ctx, sc) => SingleChildScrollView(
      controller: sc,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          if (actions != null) ...[
            const SizedBox(height: 20),
            Row(
              children: actions.map((a) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: a))).toList(),
            ),
          ],
        ],
      ),
    ),
  );
}

class _AppBottomSheetContent<T> extends StatelessWidget {
  final String title;
  final Widget Function(BuildContext, ScrollController) bodyBuilder;
  final double initialChildSize;
  final double maxChildSize;
  final double minChildSize;
  final List<Widget>? actions;

  const _AppBottomSheetContent({
    required this.title,
    required this.bodyBuilder,
    required this.initialChildSize,
    required this.maxChildSize,
    required this.minChildSize,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      maxChildSize: maxChildSize,
      minChildSize: minChildSize,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Title + close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: bodyBuilder(ctx, scrollController),
              ),
            ),
            // Actions
            if (actions != null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: actions!
                        .map((a) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: a,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MemberPrivilegeCard extends StatelessWidget {
  final PrivilegeCard card;
  final String memberName;
  final String organizationName;
  final String? ayalkoottamName;
  final String? photoUrl;

  const MemberPrivilegeCard({
    super.key,
    required this.card,
    required this.memberName,
    required this.organizationName,
    this.ayalkoottamName,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.12,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: AppTheme.heroGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                top: -42,
                right: -20,
                child: _CardAccentOrb(
                  size: 132,
                  color: Colors.white.withValues(alpha: 0.11),
                ),
              ),
              Positioned(
                bottom: -34,
                left: -12,
                child: _CardAccentOrb(
                  size: 88,
                  color: AppTheme.accentSoft.withValues(alpha: 0.20),
                ),
              ),
              Positioned(
                right: -30,
                bottom: 18,
                child: Transform.rotate(
                  angle: -0.62,
                  child: Container(
                    width: 148,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'സംഗമം',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        organizationName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.84),
                                          fontSize: 11.5,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: photoUrl != null
                                      ? Image.network(
                                          photoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _CardAvatarFallback(label: memberName),
                                        )
                                      : _CardAvatarFallback(label: memberName),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                              ),
                              child: Text(
                                ayalkoottamName ?? 'Privilege Member',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              memberName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'AYALKOOTTAM PRIVILEGE',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.68),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 96,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 78,
                              height: 78,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: card.qrData != null
                                  ? Image.memory(
                                      _decodeQrImage(card.qrData!),
                                      fit: BoxFit.contain,
                                    )
                                  : const Icon(
                                      Icons.qr_code_2_rounded,
                                      color: AppTheme.primary,
                                      size: 40,
                                    ),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Uint8List _decodeQrImage(String dataUrl) {
    final base64 = dataUrl.split(',').last;
    return Uri.parse('data:image/png;base64,$base64').data!.contentAsBytes();
  }
}

class _CardAccentOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _CardAccentOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CardAvatarFallback extends StatelessWidget {
  final String label;

  const _CardAvatarFallback({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label.isEmpty ? 'M' : label[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
