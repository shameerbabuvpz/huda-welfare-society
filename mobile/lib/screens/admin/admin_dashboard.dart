import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    final isTablet = MediaQuery.of(context).size.shortestSide > 600;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isTablet ? 96 : kToolbarHeight,
        leading: Padding(
          padding: EdgeInsets.all(isTablet ? 12 : 8),
          child: Image.asset('assets/images/ayalkoottam.png'),
        ),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.name ?? 'Admin'}',
              style: TextStyle(fontSize: isTablet ? 24 : 18, fontWeight: FontWeight.w700),
            ),
            if (user?.lastLoginAt != null)
              Text(
                'Last login: ${_formatDate(user!.lastLoginAt!)}',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 11.5,
                  color: Colors.white.withValues(alpha: 0.76),
                ),
              ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => _showProfileSheet(context),
            child: Padding(
              padding: EdgeInsets.only(right: isTablet ? 24 : 12),
              child: CircleAvatar(
                radius: isTablet ? 32 : 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? Text(
                        (user?.name ?? 'A')[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 22 : null,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenShortestSide = MediaQuery.of(context).size.shortestSide;
          final isLargeTablet = screenShortestSide > 700; // iPad
          final isSmallTablet = !isLargeTablet && constraints.maxWidth > 600; // 7-inch tablet
          final isTablet = isLargeTablet;
          final crossAxisCount = isLargeTablet ? 4 : isSmallTablet ? 4 : 3;
          final childAspectRatio = isLargeTablet ? 0.95 : isSmallTablet ? 1.2 : 0.9;
          final gridSpacing = isLargeTablet ? 20.0 : isSmallTablet ? 12.0 : 14.0;
          final padding = isLargeTablet ? 32.0 : isSmallTablet ? 16.0 : 18.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, padding + 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: gridSpacing,
                    crossAxisSpacing: gridSpacing,
                    childAspectRatio: childAspectRatio,
                    physics: (isSmallTablet || isLargeTablet) ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                    children: [
                      _DashboardCard(
                        icon: Icons.health_and_safety,
                        label: 'Health',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageAssets),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                      _DashboardCard(
                        icon: Icons.favorite,
                        label: 'Kaniv',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageKaneev),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                      _DashboardCard(
                        icon: Icons.account_balance,
                        label: 'Kuri Chitts',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageKuri),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                      _DashboardCard(
                        icon: Icons.account_balance_wallet,
                        label: 'Income & Expense',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.finance),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                      _DashboardCard(
                        icon: Icons.event_note,
                        label: 'Weekly Collection',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.weeklyCollection),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                      _DashboardCard(
                        icon: Icons.notifications,
                        label: 'Notifications',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.notificationList),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                      _DashboardCard(
                        icon: Icons.groups_2,
                        label: 'Ayalkoottam',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageAyalkoottam),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                      _DashboardCard(
                        icon: Icons.people,
                        label: 'Members',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageMembers),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                      _DashboardCard(
                        icon: Icons.bar_chart,
                        label: 'Reports',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                      _DashboardCard(
                        icon: Icons.card_giftcard,
                        label: 'Privilege Card',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.managePrivilegeOffers),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                      _DashboardCard(
                        icon: Icons.photo_library,
                        label: 'Ad Banners',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageBanners),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                      _DashboardCard(
                        icon: Icons.sync,
                        label: 'INFACC Sync',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.infaccSync),
                        isTablet: isTablet,
                        isSmallTablet: isSmallTablet,
                      ),
                    ],
                  ),
                ),
                if (org != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '${org.name}${org.place != null ? ' • ${org.place}' : ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.ink.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Version 1.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 11,
                      color: AppTheme.ink.withValues(alpha: 0.46),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
                showModalBottomSheet(
                  context: ctx,
                  builder: (sheetCtx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take Photo'),
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            _pickAndUploadAdminPhoto(context, ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Choose from Gallery'),
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            _pickAndUploadAdminPhoto(context, ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
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
            const SizedBox(height: 20),
            if (auth.hasMultipleRoles) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, AppRoutes.roleSwitcher);
                  },
                  icon: const Icon(Icons.security),
                  label: const Text('Switch Role'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
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
          ],
        ),
      );
    },
  );
}

Future<void> _pickAndUploadAdminPhoto(BuildContext context, ImageSource source) async {
  final picker = ImagePicker();
  try {
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (pickedFile == null || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.updatePhoto(pickedFile);

    if (!context.mounted) return;
    if (success) {
      Navigator.of(context).pop(); // Close the profile bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar('Profile photo updated'),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(auth.error ?? 'Failed to update photo'),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppTheme.errorSnackBar('Unable to pick image: $e'),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isTablet;
  final bool isSmallTablet;

  const _DashboardCard({required this.icon, required this.label, required this.onTap, this.isTablet = false, this.isSmallTablet = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconContainerSize = isTablet ? 68.0 : isSmallTablet ? 44.0 : 52.0;
    final iconSize = isTablet ? 34.0 : isSmallTablet ? 22.0 : 26.0;
    final borderRadius = isTablet ? 28.0 : isSmallTablet ? 18.0 : 24.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
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
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : isSmallTablet ? 8 : 10, vertical: isTablet ? 18 : isSmallTablet ? 10 : 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(isTablet ? 22 : isSmallTablet ? 14 : 18),
                  ),
                  child: Icon(icon, size: iconSize, color: theme.colorScheme.primary),
                ),
                SizedBox(height: isTablet ? 16 : isSmallTablet ? 8 : 12),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 16 : isSmallTablet ? 12 : null,
                    color: AppTheme.ink,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
