import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/member_provider.dart';
import '../../../services/api_service.dart';

class MemberChangeCodeScreen extends StatefulWidget {
  final bool mustChange;

  const MemberChangeCodeScreen({
    super.key,
    this.mustChange = false,
  });

  @override
  State<MemberChangeCodeScreen> createState() => _MemberChangeCodeScreenState();
}

class _MemberChangeCodeScreenState extends State<MemberChangeCodeScreen> {
  late TextEditingController _currentCodeController;
  late TextEditingController _newCodeController;
  late TextEditingController _confirmCodeController;
  bool _loading = false;
  String? _error;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _currentCodeController = TextEditingController();
    _newCodeController = TextEditingController();
    _confirmCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _currentCodeController.dispose();
    _newCodeController.dispose();
    _confirmCodeController.dispose();
    super.dispose();
  }

  Future<void> _changeCode() async {
    final currentCode = _currentCodeController.text.trim();
    final newCode = _newCodeController.text.trim();
    final confirmCode = _confirmCodeController.text.trim();

    // Validation
    if (currentCode.length != 4) {
      setState(() => _error = 'Current code must be 4 digits');
      return;
    }

    if (newCode.length != 4) {
      setState(() => _error = 'New code must be 4 digits');
      return;
    }

    if (newCode != confirmCode) {
      setState(() => _error = 'Codes do not match');
      return;
    }

    if (currentCode == newCode) {
      setState(() => _error = 'New code must be different from current code');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);
      final response = await memberProvider.changeCode(currentCode, newCode);

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Code changed successfully'),
          );
          // Navigate to member dashboard
          Navigator.of(context).pushReplacementNamed('/member-dashboard');
        }
      } else {
        setState(() => _error = response['message'] ?? 'Failed to change code');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skip() async {
    if (!widget.mustChange) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Code'),
        automaticallyImplyLeading: !widget.mustChange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.mustChange) ...[
              // Warning banner for mandatory change
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please change your code before continuing',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text(
              'Change Login Code',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your code must be 4 digits. You will need to remember this code to log in.',
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 32),

            // Current code
            TextField(
              controller: _currentCodeController,
              keyboardType: TextInputType.number,
              obscureText: !_showCurrentPassword,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Current Code',
                hintText: '4 digits',
                prefixIcon: const Icon(Icons.lock_open),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _showCurrentPassword = !_showCurrentPassword);
                  },
                ),
                counterText: '',
              ),
              enabled: !_loading,
            ),

            const SizedBox(height: 16),

            // New code
            TextField(
              controller: _newCodeController,
              keyboardType: TextInputType.number,
              obscureText: !_showNewPassword,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'New Code',
                hintText: '4 digits',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _showNewPassword = !_showNewPassword);
                  },
                ),
                counterText: '',
              ),
              enabled: !_loading,
            ),

            const SizedBox(height: 16),

            // Confirm new code
            TextField(
              controller: _confirmCodeController,
              keyboardType: TextInputType.number,
              obscureText: !_showConfirmPassword,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Confirm New Code',
                hintText: '4 digits',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _showConfirmPassword = !_showConfirmPassword);
                  },
                ),
                counterText: '',
              ),
              enabled: !_loading,
            ),

            const SizedBox(height: 24),

            // Error
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

            // Buttons
            Row(
              children: [
                if (!widget.mustChange)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : _skip,
                      child: const Text('Cancel'),
                    ),
                  ),
                if (!widget.mustChange) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _changeCode,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Change Code'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Help
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Tips:',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Choose a code you can remember\n'
                    '• Avoid sequential numbers (1234, 5678)\n'
                    '• Don\'t share your code with anyone',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.ink.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
