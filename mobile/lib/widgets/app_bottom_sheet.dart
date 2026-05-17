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
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.outline),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: 0.10),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 10),
              child: Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            // Title + close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: bodyBuilder(ctx, scrollController),
              ),
            ),
            // Actions
            if (actions != null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
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

/// Confirmation bottom sheet for destructive/important actions.
/// Returns `true` if confirmed, `null` or `false` otherwise.
Future<bool?> showConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  IconData? icon,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag indicator
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppTheme.error.withValues(alpha: 0.1)
                      : AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? (isDestructive ? Icons.delete_outline_rounded : Icons.info_outline_rounded),
                  color: isDestructive ? AppTheme.error : AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppTheme.outline),
                      ),
                      child: Text(cancelLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDestructive ? AppTheme.error : AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(confirmLabel),
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

/// Form bottom sheet — a modern bottom sheet for simple form inputs.
/// Returns the result from [onSubmit] or null if dismissed.
Future<T?> showFormSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context) bodyBuilder,
  double initialChildSize = 0.55,
}) {
  return showAppBottomSheet<T>(
    context: context,
    title: title,
    initialChildSize: initialChildSize,
    bodyBuilder: (ctx, sc) => SingleChildScrollView(
      controller: sc,
      child: bodyBuilder(ctx),
    ),
  );
}

class MemberPrivilegeCard extends StatelessWidget {
  final PrivilegeCard card;
  final String memberName;
  final String? organizationName;
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
    final titleText = (organizationName != null && organizationName!.trim().isNotEmpty)
        ? organizationName!.trim()
        : (ayalkoottamName != null && ayalkoottamName!.trim().isNotEmpty)
            ? ayalkoottamName!.trim()
            : 'Privilege Card';

    return AspectRatio(
      aspectRatio: 1.94,
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
                            Text(
                              titleText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                height: 1.2,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                  child: ClipOval(
                                    child: photoUrl != null && photoUrl!.isNotEmpty
                                        ? Image.network(
                                            photoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        memberName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'MEMBER',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.68),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 96,
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
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
                              const SizedBox(height: 10),
                              Text(
                                'Privilege Card',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
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
