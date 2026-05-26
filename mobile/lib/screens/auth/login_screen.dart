import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  // OTP pin controllers (4 boxes)
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.requestOtp(_phoneController.text.trim());

    if (!mounted) return;
    if (success) {
      // Focus first OTP box
      _otpFocusNodes[0].requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(auth.error ?? 'Failed to send OTP'),
      );
    }
  }

  void _onPhoneChanged(String value) {
    // Clear error when user edits
    final auth = context.read<AuthProvider>();
    if (auth.error != null) {
      auth.resetOtp();
    }
    if (value.length == 10) {
      // Auto-send OTP when 10 digits entered
      _requestOtp();
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Move to next box
      if (index < 3) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered - auto verify
        _otpFocusNodes[index].unfocus();
        _verifyOtp();
      }
    }
  }

  void _onOtpKeyPress(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        // Move to previous box and clear it
        _otpControllers[index - 1].clear();
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
  }

  String get _otpText =>
      _otpControllers.map((c) => c.text).join();

  void _clearOtp() {
    for (final c in _otpControllers) {
      c.clear();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpText;
    if (otp.length < 4) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(
      _phoneController.text.trim(),
      otp,
    );

    if (!mounted) return;

    if (success) {
      if (auth.isSuperAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.superAdminDashboard);
      } else if (auth.isAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.memberDashboard);
      }
    } else {
      _clearOtp();
      _otpFocusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(auth.error ?? 'Invalid OTP'),
      );
    }
  }

  void _changeNumber() {
    final auth = context.read<AuthProvider>();
    auth.resetOtp();
    _clearOtp();
    _phoneController.clear();
  }

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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.outline),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryDark.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/ayalkoottam.png', height: 120),
                        const SizedBox(height: 12),
                        Text(
                          'Sangamam',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          auth.otpSent
                              ? 'Enter the OTP sent to your mobile number'
                              : 'Login with your mobile number',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppTheme.ink.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (!auth.otpSent) ...[
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: _onPhoneChanged,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              prefixIcon: Icon(Icons.phone),
                              prefixText: '+91 ',
                              counterText: '',
                            ),
                            validator: (v) {
                              if (v == null || v.length != 10) {
                                return 'Enter 10-digit mobile number';
                              }
                              if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                                return 'Only digits allowed';
                              }
                              return null;
                            },
                          ),
                          if (auth.error != null && !auth.otpSent) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          if (auth.loading) const CircularProgressIndicator(),
                        ],
                        if (auth.otpSent) ...[
                          Text(
                            '+91 ${_phoneController.text.substring(0, 2)}****${_phoneController.text.substring(6)}',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (i) {
                              return SizedBox(
                                width: 58,
                                height: 64,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: KeyboardListener(
                                    focusNode: FocusNode(),
                                    onKeyEvent: (event) => _onOtpKeyPress(i, event),
                                    child: TextFormField(
                                      controller: _otpControllers[i],
                                      focusNode: _otpFocusNodes[i],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                        counterText: '',
                                        filled: true,
                                        fillColor: AppTheme.surfaceWarm,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: AppTheme.outline),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.8),
                                        ),
                                      ),
                                      onChanged: (v) => _onOtpDigitChanged(i, v),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          if (auth.loading) const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _changeNumber,
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Change Number'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
