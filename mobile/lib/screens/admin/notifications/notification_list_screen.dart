import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notification_provider.dart';
import '../../../widgets/app_bottom_sheet.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationProvider>().loadAdminNotifications();
  }

  Future<void> _editNotification(AppNotification notification) async {
    final titleCtrl = TextEditingController(text: notification.title);
    final bodyCtrl = TextEditingController(text: notification.body);
    final provider = context.read<NotificationProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showAppSheet<bool>(
      context: context,
      title: 'Edit Notification',
      initialChildSize: 0.45,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bodyCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Save'),
        ),
      ],
    );

    if (result == true && mounted) {
      final success = await provider.updateNotification(
            notification.id,
            title: titleCtrl.text.trim(),
            body: bodyCtrl.text.trim(),
          );
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        success ? AppTheme.successSnackBar('Notification updated') : AppTheme.errorSnackBar('Update failed'),
      );
    }

    titleCtrl.dispose();
    bodyCtrl.dispose();
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    final provider = context.read<NotificationProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirm = await showConfirmSheet(
      context: context,
      title: 'Delete Notification',
      message: 'Delete "${notification.title}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      final success = await provider.deleteNotification(notification.id);
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        success ? AppTheme.successSnackBar('Notification deleted') : AppTheme.errorSnackBar('Delete failed'),
      );
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.sendNotification);
              if (!context.mounted) return;
              context.read<NotificationProvider>().loadAdminNotifications();
            },
          ),
        ],
      ),
      body: provider.loading
          ? const ListSkeletonLoader()
          : provider.adminNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No notifications sent yet', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          await Navigator.pushNamed(context, AppRoutes.sendNotification);
                          if (!context.mounted) return;
                          context.read<NotificationProvider>().loadAdminNotifications();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Send Notification'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<NotificationProvider>().loadAdminNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.adminNotifications.length,
                    itemBuilder: (ctx, i) {
                      final n = provider.adminNotifications[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.campaign, color: AppTheme.primary),
                          ),
                          title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(n.createdAt),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceWarm,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      n.audienceType == 'specific' ? 'Specific' : 'All',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _editNotification(n);
                              if (value == 'delete') _deleteNotification(n);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
