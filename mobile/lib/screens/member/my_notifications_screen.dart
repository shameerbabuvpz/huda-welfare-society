import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class MyNotificationsScreen extends StatefulWidget {
  const MyNotificationsScreen({super.key});

  @override
  State<MyNotificationsScreen> createState() => _MyNotificationsScreenState();
}

class _MyNotificationsScreenState extends State<MyNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NotificationProvider>().loadMemberNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
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
                  itemBuilder: (ctx, i) {
                    final n = provider.notifications[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.notifications, color: Colors.blue),
                        ),
                        title: Text(n.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (n.sentAt != null)
                              Text(n.sentAt!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
