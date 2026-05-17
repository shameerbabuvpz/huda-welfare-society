import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../services/member_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  Member? _member;
  bool _loading = true;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _member = await MemberService.getProfile();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      setState(() => _uploadingPhoto = true);
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.updatePhoto(pickedFile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile photo updated successfully.'
                : (authProvider.error ?? 'Unable to update profile photo.'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to pick image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _member == null
              ? const Center(child: Text('Profile not found'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppTheme.outline),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              _ProfileAvatar(
                                name: _member!.name,
                                photoUrl: user?.photoUrl,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryDark,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: _uploadingPhoto
                                      ? const Padding(
                                          padding: EdgeInsets.all(9),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _member!.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _member!.memberCode,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          ),
                          if (_member!.ayalkoottamName != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _member!.ayalkoottamName!,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _uploadingPhoto ? null : () => _pickAndUpload(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Take Selfie'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _uploadingPhoto ? null : () => _pickAndUpload(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text('Upload from Gallery'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Column(
                        children: [
                          _profileRow(Icons.phone_outlined, 'Phone', _member!.phone ?? 'N/A'),
                          _profileRow(Icons.email_outlined, 'Email', _member!.email ?? 'N/A'),
                          if ((_member!.designation ?? '').isNotEmpty)
                            _profileRow(Icons.badge_outlined, 'Designation', _member!.designation!),
                          if ((_member!.ayalkoottamName ?? '').isNotEmpty)
                            _profileRow(Icons.groups_2_outlined, 'Ayalkoottam', _member!.ayalkoottamName!),
                          _profileRow(Icons.location_on_outlined, 'Address', _member!.address ?? 'N/A'),
                          _profileRow(Icons.calendar_today_outlined, 'Joined', _member!.joinDate ?? 'N/A'),
                          _profileRow(Icons.verified_outlined, 'Status', _member!.status.toUpperCase()),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _ProfileAvatar({
    required this.name,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceWarm,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ProfileAvatarFallback(name: name),
              )
            : _ProfileAvatarFallback(name: name),
      ),
    );
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  final String name;

  const _ProfileAvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceWarm,
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
    );
  }
}
