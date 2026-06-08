class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String memberLogin = '/member-login';
  static const String memberChangeCode = '/member-change-code';
  static const String roleSwitcher = '/role-switcher';
  static const String superAdminDashboard = '/super-admin/dashboard';
  static const String backup = '/super-admin/backup';
  static const String adminDashboard = '/admin/dashboard';
  static const String memberDashboard = '/member/dashboard';

  // Admin
  static const String manageMembers = '/admin/members';
  static const String addMember = '/admin/members/add';
  static const String manageAssets = '/admin/assets';
  static const String addAsset = '/admin/assets/add';
  static const String issueAsset = '/admin/assets/issue';
  static const String manageKuri = '/admin/kuri';
  static const String createKuri = '/admin/kuri/create';
  static const String kuriDetail = '/admin/kuri/detail';
  static const String sendNotification = '/admin/notifications/send';
  static const String notificationList = '/admin/notifications';
  static const String reports = '/admin/reports';
  static const String manageAyalkoottam = '/admin/ayalkoottam';
  static const String addAyalkoottam = '/admin/ayalkoottam/add';
  static const String ayalkoottamDetail = '/admin/ayalkoottam/detail';
  static const String ayalkoottamLeaders = '/admin/ayalkoottam/leaders';
  static const String manageKaneev = '/admin/kaneev';
  static const String finance = '/admin/finance';
  static const String weeklyCollection = '/admin/weekly-collection';
  static const String manageAdmins = '/admin/admins';
  static const String managePrivilegeOffers = '/admin/privilege-offers';
  static const String manageBanners = '/admin/banners';
  static const String infaccSync = '/admin/infacc-sync';

  // Member
  static const String profile = '/member/profile';
  static const String privilegeCard = '/member/privilege-card';
  static const String memberOffers = '/member/offers';
  static const String myAssets = '/member/my-assets';
  static const String myKuri = '/member/my-kuri';
  static const String myNotifications = '/member/notifications';
  static const String ayalkoottamMembers = '/member/ayalkoottam-members';
}
