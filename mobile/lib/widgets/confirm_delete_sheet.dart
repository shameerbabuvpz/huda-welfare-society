import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';

/// A confirmation bottom sheet for destructive (delete) actions that protects
/// against accidental taps by requiring the user to re-type a randomly
/// generated CAPTCHA-style code before the delete button is enabled.
///
/// Returns `true` if the user confirms the deletion, `null`/`false` otherwise.
Future<bool?> showConfirmDeleteSheet({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ConfirmDeleteSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    ),
  );
}

class _ConfirmDeleteSheet extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const _ConfirmDeleteSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  @override
  State<_ConfirmDeleteSheet> createState() => _ConfirmDeleteSheetState();
}

class _ConfirmDeleteSheetState extends State<_ConfirmDeleteSheet> {
  late String _code;
  final _controller = TextEditingController();
  bool _matched = false;

  @override
  void initState() {
    super.initState();
    _code = (1000 + Random().nextInt(9000)).toString();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final m = _controller.text.trim() == _code;
    if (m != _matched) setState(() => _matched = m);
  }

  void _regenerate() {
    setState(() {
      _code = (1000 + Random().nextInt(9000)).toString();
      _controller.clear();
      _matched = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(widget.message, style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 18),
                Text(
                  'Type this code to confirm:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Text(
                        _code,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 8,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'New code',
                      onPressed: _regenerate,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter code',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: _matched
                        ? const Icon(Icons.check_circle, color: AppTheme.primary)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _matched ? () => Navigator.pop(context, true) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(widget.confirmLabel),
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
}
