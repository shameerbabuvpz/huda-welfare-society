import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import 'admin_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    _DashboardHome(),
    AdminManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final org = auth.organization;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset('assets/images/ayalkoottam.png'),
        ),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.name ?? 'Admin'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (user?.lastLoginAt != null)
              Text(
                'Last login: ${_formatDate(user!.lastLoginAt!)}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.76),
                ),
              ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => _showProfileSheet(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? Text(
                        (user?.name ?? 'A')[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.9,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DashboardCard(
                  icon: Icons.health_and_safety,
                  label: 'Health',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.manageAssets),
                ),
                _DashboardCard(
                  icon: Icons.favorite,
                  label: 'Kaneev',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.manageKaneev),
                ),
                _DashboardCard(
                  icon: Icons.account_balance,
                  label: 'Kuri Chitts',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.manageKuri),
                ),
                _DashboardCard(
                  icon: Icons.account_balance_wallet,
                  label: 'Income & Expense',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.finance),
                ),
                _DashboardCard(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.notificationList),
                ),
                _DashboardCard(
                  icon: Icons.groups_2,
                  label: 'Ayalkoottam',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.manageAyalkoottam),
                ),
                _DashboardCard(
                  icon: Icons.people,
                  label: 'Members',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.manageMembers),
                ),
                _DashboardCard(
                  icon: Icons.bar_chart,
                  label: 'Reports',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
                ),
                _DashboardCard(
                  icon: Icons.card_giftcard,
                  label: 'Privilege Card',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.managePrivilegeOffers),
                ),
                _DashboardCard(
                  icon: Icons.photo_library,
                  label: 'Ad Banners',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.manageBanners),
                ),
                _DashboardCard(
                  icon: Icons.sync,
                  label: 'INFACC Sync',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.infaccSync),
                ),
              ],
            ),
            if (org != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  '${org.name}${org.place != null ? ' • ${org.place}' : ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.ink.withValues(alpha: 0.72),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Version 1.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.ink.withValues(alpha: 0.46),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(String dateStr) {
  try {
    final dt = DateTime.parse(dateStr).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return dateStr;
  }
}

void _showProfileSheet(BuildContext context) {
  final auth = context.read<AuthProvider>();
  final user = auth.user;
  final nameController = TextEditingController(text: user?.name ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            GestureDetector(
              onTap: () {
                // TODO: implement image picker
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.infoSnackBar('Photo upload coming soon'),
                );
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? Text(
                            (user?.name ?? 'A')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.phone ?? '',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dlgCtx) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Do you want to logout?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(dlgCtx, true),
                              child: const Text('Logout', style: TextStyle(color: AppTheme.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.login);
                      }
                    },
                    icon: const Icon(Icons.logout, color: AppTheme.error),
                    label: const Text('Logout',
                        style: TextStyle(color: AppTheme.error)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newName = nameController.text.trim();
                      if (newName.isNotEmpty && newName != user?.name) {
                        await auth.updateProfile(name: newName);
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 26, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppTheme.ink.withValues(alpha: 0.46),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
