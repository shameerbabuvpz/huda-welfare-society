import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/notification_provider.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _audienceType = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final success = await context.read<NotificationProvider>().sendNotification(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      audienceType: _audienceType,
    );

    setState(() => _sending = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.successSnackBar('Notification sent'));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(context.read<NotificationProvider>().error ?? 'Failed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Notification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message *'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              const Text('Audience', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All Members')),
                  ButtonSegment(value: 'specific', label: Text('Specific')),
                ],
                selected: {_audienceType},
                onSelectionChanged: (s) => setState(() => _audienceType = s.first),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending ? const SizedBox(height: 20, width: 20, child: CupertinoActivityIndicator()) : const Icon(Icons.send),
                  label: const Text('Send Notification'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
