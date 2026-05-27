import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/member_provider.dart';
import '../../services/api_service.dart';

class MemberLoginScreen extends StatefulWidget {
  const MemberLoginScreen({super.key});

  @override
  State<MemberLoginScreen> createState() => _MemberLoginScreenState();
}

class _MemberLoginScreenState extends State<MemberLoginScreen> {
  late TextEditingController _memberIdController;
  late TextEditingController _codeController;
  bool _loading = false;
  String? _error;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _memberIdController = TextEditingController();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _memberIdController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final memberId = int.tryParse(_memberIdController.text.trim());
    final code = _codeController.text.trim();

    if (memberId == null) {
      setState(() => _error = 'Please enter a valid member ID');
      return;
    }

    if (code.length != 4) {
      setState(() => _error = 'Code must be 4 digits');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.post(
        '/member-auth/login',
        {
          'memberId': memberId,
          'organizationId': 2, // Sangamam organization ID
          'code': code,
        },
      );

      if (response['success'] == true) {
        final token = response['token'];
        final mustChangeCode = response['mustChangeCode'] ?? false;

        // Save token
        final memberProvider = Provider.of<MemberProvider>(context, listen: false);
        await memberProvider.setMemberToken(token);

        if (mounted) {
          if (mustChangeCode) {
            // Force member to change code
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.memberChangeCode,
              arguments: {'mustChange': true},
            );
          } else {
            // Go to member dashboard
            Navigator.of(context).pushReplacementNamed(AppRoutes.memberDashboard);
          }
        }
      } else {
        setState(() => _error = response['message'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Icon(
                  Icons.account_circle,
                  size: 80,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Member Login',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your member ID and code',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Member ID
                TextField(
                  controller: _memberIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Member ID',
                    hintText: 'Enter member ID',
                    prefixIcon: const Icon(Icons.badge),
                  ),
                  enabled: !_loading,
                ),

                const SizedBox(height: 16),

                // Code
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  obscureText: !_showPassword,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'Code',
                    hintText: '4-digit code',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                    counterText: '',
                  ),
                  enabled: !_loading,
                ),

                const SizedBox(height: 24),

                // Error message
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Login button
                FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CupertinoActivityIndicator(),
                        )
                      : const Text('Login'),
                ),

                const SizedBox(height: 16),

                // Login with phone number - navigate to main login screen
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Login with Phone Number'),
                ),

                const SizedBox(height: 8),

                // Help text
                Text(
                  'Default code: 6789\nYou will be asked to change it on first login.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
