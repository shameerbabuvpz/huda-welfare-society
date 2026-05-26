import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/asset.dart';
import '../../models/kaneev_group.dart';
import '../../models/kuri_group.dart';
import '../../models/member.dart';
import '../../models/notification_model.dart';
import '../../models/privilege_card.dart';
import '../../models/banner.dart' as app;
import '../../providers/auth_provider.dart';
import '../../services/asset_service.dart';
import '../../services/kaneev_service.dart';
import '../../services/kuri_service.dart';
import '../../services/member_service.dart';
import '../../services/notification_service.dart';
import '../../services/privilege_card_service.dart';
import '../../services/banner_service.dart';
import '../../widgets/app_bottom_sheet.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  _MemberHomeData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final profileFuture = MemberService.getProfile();
      final cardFuture = PrivilegeCardService.getMyCard();
      final notificationsFuture = _loadNotifications();
      final equipmentsFuture = _loadEquipments();
      final kuriFuture = _loadKuri();
      final kaneevFuture = _loadKaneev();
      final bannersFuture = _loadBanners();

      final profile = await profileFuture;
      final card = await cardFuture;
      final notifications = await notificationsFuture;
      final equipments = await equipmentsFuture;
      final kuriEntries = await kuriFuture;
      final kaneev = await kaneevFuture;
      final banners = await bannersFuture;

      if (!mounted) return;

      setState(() {
        _data = _MemberHomeData(
          profile: profile,
          card: card,
          notifications: notifications,
          equipments: equipments,
          kuriEntries: kuriEntries,
          kaneev: kaneev,
          banners: banners,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<AppNotification>> _loadNotifications() async {
    try {
      return await NotificationApiService.myNotifications(page: 1);
    } catch (_) {
      return [];
    }
  }

  Future<List<AssetTransaction>> _loadEquipments() async {
    try {
      return await AssetService.myAssets();
    } catch (_) {
      return [];
    }
  }

  Future<List<KuriPaymentStatus>> _loadKuri() async {
    try {
      return await KuriService.myKuri();
    } catch (_) {
      return [];
    }
  }

  Future<KaneevMemberSummary?> _loadKaneev() async {
    try {
      return await KaneevService.myKaneev();
    } catch (_) {
      return null;
    }
  }

  Future<List<app.Banner>> _loadBanners() async {
    try {
      return await BannerService.listActive();
    } catch (_) {
      return [];
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.pushNamed(context, AppRoutes.myNotifications);
    if (!mounted) return;
    _load();
  }

  Future<void> _openProfile() async {
    await Navigator.pushNamed(context, AppRoutes.profile);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final data = _data;
    final latestNotification = data?.notifications.isNotEmpty == true ? data!.notifications.first : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _loading && data == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && data == null
                ? _DashboardErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _HeaderAction(
                              icon: Icons.account_circle_outlined,
                              onTap: _openProfile,
                            ),
                            const SizedBox(width: 8),
                            _HeaderAction(
                              icon: Icons.notifications_none_rounded,
                              activeCount: data?.notifications.length ?? 0,
                              onTap: _openNotifications,
                            ),
                            if (auth.hasMultipleRoles) ...[
                              const SizedBox(width: 8),
                              _HeaderAction(
                                icon: Icons.security,
                                onTap: () => Navigator.pushNamed(context, AppRoutes.roleSwitcher),
                              ),
                            ],
                            const SizedBox(width: 8),
                            _HeaderAction(
                              icon: Icons.logout_rounded,
                              onTap: _logout,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        if (data != null && data.banners.isNotEmpty)
                          _BannerCarousel(banners: data.banners),
                        if (data != null && data.banners.isNotEmpty)
                          const SizedBox(height: 16),
                        if (data != null)
                          MemberPrivilegeCard(
                            card: data.card,
                            memberName: data.profile.name,
                            organizationName: data.card.organizationName,
                            ayalkoottamName: data.profile.ayalkoottamName ?? data.card.ayalkoottamName,
                            photoUrl: data.card.photoUrl ?? user?.photoUrl,
                          ),
                        if (latestNotification != null) ...[
                          const SizedBox(height: 18),
                          _NotificationStrip(
                            notification: latestNotification,
                            totalCount: data!.notifications.length,
                            onTap: _openNotifications,
                          ),
                        ],
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Services',
                          subtitle: 'Only the items relevant to this member are shown here.',
                        ),
                        const SizedBox(height: 12),
                        if (data != null)
                          _ServiceSheet(
                            children: [
                              _ServiceRow(
                                icon: Icons.card_giftcard,
                                color: AppTheme.accent,
                                title: 'Privilege Offers',
                                subtitle: 'View & redeem partner offers',
                                onTap: () => Navigator.pushNamed(context, AppRoutes.memberOffers),
                              ),
                              _ServiceRow(
                                icon: Icons.medical_services_outlined,
                                color: AppTheme.success,
                                title: 'Health Equipments',
                                subtitle: data.equipments.isEmpty
                                    ? 'No health equipments are currently issued to you.'
                                    : '${data.equipments.length} health equipment${data.equipments.length == 1 ? '' : 's'} issued to you.',
                                onTap: () => Navigator.pushNamed(context, AppRoutes.myAssets),
                              ),
                              if (data.kuriEntries.isNotEmpty)
                                _ServiceRow(
                                  icon: Icons.savings_outlined,
                                  color: AppTheme.accent,
                                  title: 'Kuri',
                                  subtitle: _buildKuriSubtitle(data.kuriEntries),
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.myKuri),
                                ),
                            ],
                          ),
                        if (data != null && data.kaneev != null) ...[
                          const SizedBox(height: 22),
                          const _SectionTitle(
                            title: 'Kaniv',
                            subtitle: 'Your member details appear here only when you are part of Kaniv.',
                          ),
                          const SizedBox(height: 12),
                          _KaneevPanel(summary: data.kaneev!),
                        ],
                        if (data != null && data.kuriEntries.isEmpty && data.kaneev == null) ...[
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceWarm,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.auto_awesome_outlined, color: AppTheme.accent),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'More member services will appear here automatically when this member joins Kuri or Kaniv.',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 13.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

String _buildKuriSubtitle(List<KuriPaymentStatus> kuriEntries) {
  if (kuriEntries.length == 1) {
    final first = kuriEntries.first;
    final groupName = first.group['name']?.toString() ?? 'Kuri';
    if (first.pendingMonths.isEmpty) {
      return '$groupName is active and fully up to date.';
    }
    return '$groupName has ${first.pendingMonths.length} pending month${first.pendingMonths.length == 1 ? '' : 's'}.';
  }

  final pending = kuriEntries.fold<int>(0, (sum, item) => sum + item.pendingMonths.length);
  return '${kuriEntries.length} kuri groups active${pending > 0 ? ' • $pending pending months' : ' • all collections up to date'}.';
}

class _MemberHomeData {
  final Member profile;
  final PrivilegeCard card;
  final List<AppNotification> notifications;
  final List<AssetTransaction> equipments;
  final List<KuriPaymentStatus> kuriEntries;
  final KaneevMemberSummary? kaneev;
  final List<app.Banner> banners;

  const _MemberHomeData({
    required this.profile,
    required this.card,
    required this.notifications,
    required this.equipments,
    required this.kuriEntries,
    required this.kaneev,
    required this.banners,
  });
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final int activeCount;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.onTap,
    this.activeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outline),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(icon, color: AppTheme.ink, size: 20),
              ),
            ),
          ),
        ),
        if (activeCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppTheme.error,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                activeCount > 9 ? '9+' : '$activeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationStrip extends StatelessWidget {
  final AppNotification notification;
  final int totalCount;
  final VoidCallback onTap;

  const _NotificationStrip({
    required this.notification,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWarm,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.notifications_active_outlined, color: AppTheme.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                        if (totalCount > 1)
                          Text(
                            '$totalCount updates',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 12.8,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ServiceSheet extends StatelessWidget {
  final List<Widget> children;

  const _ServiceSheet({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12.8,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.ink.withValues(alpha: 0.40),
            ),
          ],
        ),
      ),
    );
  }
}

class _KaneevPanel extends StatelessWidget {
  final KaneevMemberSummary summary;

  const _KaneevPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.volunteer_activism_outlined, color: AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.hasReceived
                          ? 'Kaneev benefit already received in month ${summary.receivedMonth ?? '-'}.'
                          : 'You are currently enrolled in Kaneev.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.8,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _KaneevMetric(
                  label: 'Slot',
                  value: summary.slotNumber?.toString() ?? '-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KaneevMetric(
                  label: 'Monthly',
                  value: '₹${summary.donationAmount.toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KaneevMetric(
                  label: 'Status',
                  value: summary.hasReceived ? 'Received' : 'Active',
                ),
              ),
            ],
          ),
          if (summary.currentBalance > 0) ...[
            const SizedBox(height: 14),
            Text(
              'Running balance: ₹${summary.currentBalance.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KaneevMetric extends StatelessWidget {
  final String label;
  final String value;

  const _KaneevMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<app.Banner> banners;

  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _pageController,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (ctx, i) {
                return Image.network(
                  banners[i].imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image, size: 40)),
                  ),
                );
              },
            ),
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (i) {
              return Container(
                width: _currentPage == i ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _currentPage == i ? AppTheme.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: AppTheme.error),
            const SizedBox(height: 14),
            const Text(
              'Unable to load member home',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
