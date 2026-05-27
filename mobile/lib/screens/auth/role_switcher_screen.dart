import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class RoleSwitcherScreen extends StatefulWidget {
  const RoleSwitcherScreen({super.key});

  @override
  State<RoleSwitcherScreen> createState() => _RoleSwitcherScreenState();
}

class _RoleSwitcherScreenState extends State<RoleSwitcherScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.security,
                            size: 56,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select Role',
                            style: textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have multiple roles. Choose one to continue:',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Role Options
                    ...auth.availableRoles.map((role) {
                      final isCurrent = auth.user?.role == role;
                      final isLoading = auth.loading;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoading
                                ? null
                                : () async {
                                    if (await auth.switchRole(role)) {
                                      if (!context.mounted) return;
                                      // Route based on new role
                                      if (role == 'super_admin') {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          AppRoutes.superAdminDashboard,
                                        );
                                      } else if (role == 'admin') {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          AppRoutes.adminDashboard,
                                        );
                                      } else {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          AppRoutes.memberDashboard,
                                        );
                                      }
                                    }
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppTheme.primary.withValues(alpha: 0.1)
                                    : AppTheme.surface,
                                border: Border.all(
                                  color: isCurrent
                                      ? AppTheme.primary
                                      : AppTheme.outline,
                                  width: isCurrent ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _getRoleDisplayName(role),
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isCurrent
                                                  ? AppTheme.primary
                                                  : AppTheme.ink,
                                            ),
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Current',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getRoleDescription(role),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isLoading && isCurrent) ...[
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CupertinoActivityIndicator(),
                                    ),
                                  ] else ...[
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: isCurrent
                                          ? AppTheme.primary
                                          : Colors.grey.shade500,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    if (auth.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: textTheme.bodySmall
                                    ?.copyWith(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: auth.loading
                            ? null
                            : () async {
                                await auth.logout();
                                if (context.mounted) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.login,
                                  );
                                }
                              },
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'member':
        return 'Member';
      default:
        return role;
    }
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'super_admin':
        return 'Manage organizations and configurations';
      case 'admin':
        return 'Manage members, assets, and activities';
      case 'member':
        return 'View privilege cards and my assets';
      default:
        return '';
    }
  }
}
