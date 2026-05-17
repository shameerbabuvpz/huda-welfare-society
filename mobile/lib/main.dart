import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/member_provider.dart';
import 'providers/asset_provider.dart';
import 'providers/kuri_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/ayalkoottam_provider.dart';
import 'providers/kaneev_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/privilege_offer_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/members/member_list_screen.dart';
import 'screens/admin/members/add_member_screen.dart';
import 'screens/admin/assets/asset_list_screen.dart';
import 'screens/admin/assets/add_asset_screen.dart';
import 'screens/admin/assets/issue_asset_screen.dart';
import 'screens/admin/kuri/kuri_list_screen.dart';
import 'screens/admin/kuri/create_kuri_screen.dart';
import 'screens/admin/kuri/kuri_detail_screen.dart';
import 'screens/admin/notifications/send_notification_screen.dart';
import 'screens/admin/reports/reports_screen.dart';
import 'screens/member/member_dashboard.dart';
import 'screens/member/profile_screen.dart';
import 'screens/member/privilege_card_screen.dart';
import 'screens/member/my_assets_screen.dart';
import 'screens/member/my_kuri_screen.dart';
import 'screens/member/my_notifications_screen.dart';
import 'screens/admin/ayalkoottam/ayalkoottam_list_screen.dart';
import 'screens/admin/ayalkoottam/add_ayalkoottam_screen.dart';
import 'screens/admin/ayalkoottam/ayalkoottam_detail_screen.dart';
import 'screens/admin/kaneev/kaneev_detail_screen.dart';
import 'screens/admin/finance/finance_screen.dart';
import 'screens/admin/admin_management_screen.dart';
import 'screens/admin/privilege_offers/privilege_offer_list_screen.dart';
import 'screens/member/member_offers_screen.dart';
import 'screens/super_admin/super_admin_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AyalkoottamApp());
}

class AyalkoottamApp extends StatelessWidget {
  const AyalkoottamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => AssetProvider()),
        ChangeNotifierProvider(create: (_) => KuriProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AyalkoottamProvider()),
        ChangeNotifierProvider(create: (_) => KaneevProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => PrivilegeOfferProvider()),
      ],
      child: MaterialApp(
        title: 'Sangamam',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          // Super Admin
          AppRoutes.superAdminDashboard: (_) => const SuperAdminDashboard(),
          // Admin
          AppRoutes.adminDashboard: (_) => const AdminDashboard(),
          AppRoutes.manageMembers: (_) => const MemberListScreen(),
          AppRoutes.addMember: (_) => const AddMemberScreen(),
          AppRoutes.manageAssets: (_) => const AssetListScreen(),
          AppRoutes.addAsset: (_) => const AddAssetScreen(),
          AppRoutes.issueAsset: (_) => const IssueAssetScreen(),
          AppRoutes.manageKuri: (_) => const KuriListScreen(),
          AppRoutes.createKuri: (_) => const CreateKuriScreen(),
          AppRoutes.kuriDetail: (_) => const KuriDetailScreen(),
          AppRoutes.sendNotification: (_) => const SendNotificationScreen(),
          AppRoutes.reports: (_) => const ReportsScreen(),
          AppRoutes.manageAyalkoottam: (_) => const AyalkoottamListScreen(),
          AppRoutes.addAyalkoottam: (_) => const AddAyalkoottamScreen(),
          AppRoutes.ayalkoottamDetail: (_) => const AyalkoottamDetailScreen(),
          AppRoutes.manageKaneev: (_) => const KaneevDetailScreen(),
          AppRoutes.finance: (_) => const FinanceScreen(),
          AppRoutes.manageAdmins: (_) => const AdminManagementScreen(),
          AppRoutes.managePrivilegeOffers: (_) => const PrivilegeOfferListScreen(),
          // Member
          AppRoutes.memberDashboard: (_) => const MemberDashboard(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.privilegeCard: (_) => const PrivilegeCardScreen(),
          AppRoutes.myAssets: (_) => const MyAssetsScreen(),
          AppRoutes.myKuri: (_) => const MyKuriScreen(),
          AppRoutes.myNotifications: (_) => const MyNotificationsScreen(),
          AppRoutes.memberOffers: (_) => const MemberOffersScreen(),
        },
      ),
    );
  }
}
