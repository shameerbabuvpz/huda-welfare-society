import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = context.read<AuthProvider>();
    await auth.checkAuth();
    if (!mounted) return;

    if (auth.isLoggedIn) {
      // If user has multiple roles, show role switcher
      if (auth.hasMultipleRoles) {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSwitcher);
      } else if (auth.isSuperAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.superAdminDashboard);
      } else if (auth.isAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.memberDashboard);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.background, AppTheme.surfaceWarm],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.outline),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryDark.withValues(alpha: 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/splash.png', height: 220),
                  const SizedBox(height: 18),
                  Text(
                    'Sangamam',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ayalkoottam community platform',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const CupertinoActivityIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
