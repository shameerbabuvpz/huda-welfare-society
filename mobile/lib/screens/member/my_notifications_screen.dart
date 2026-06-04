import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/notification_provider.dart';

class MyNotificationsScreen extends StatefulWidget {
  const MyNotificationsScreen({super.key});

  @override
  State<MyNotificationsScreen> createState() => _MyNotificationsScreenState();
}

class _MyNotificationsScreenState extends State<MyNotificationsScreen> {
  final Set<int> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadMemberNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: provider.loading
          ? const ListSkeletonLoader()
          : provider.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No notifications', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: provider.notifications.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (ctx, i) {
                    final n = provider.notifications[i];
                    final isExpanded = _expandedIds.contains(n.id);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedIds.remove(n.id);
                            } else {
                              _expandedIds.add(n.id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: const Icon(Icons.notifications, color: AppTheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.body,
                                      maxLines: isExpanded ? null : 3,
                                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (n.sentAt != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatDate(n.sentAt!),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                size: 20,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
