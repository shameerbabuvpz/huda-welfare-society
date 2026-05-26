import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/user.dart';
import '../models/organization.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> requestOtp(String phone) async {
    return await ApiService.post('/auth/request-otp', {'phone': phone});
  }

  static Future<User> verifyOtp(String phone, String otp) async {
    final data = await ApiService.post('/auth/verify-otp', {
      'phone': phone,
      'otp': otp,
    });
    await StorageService.saveToken(data['token']);
    final user = User.fromJson(data['user']);
    await StorageService.saveUserInfo(user.id, user.role);
    return user;
  }

  static Future<Map<String, dynamic>> verifyOtpWithOrg(String phone, String otp) async {
    final data = await ApiService.post('/auth/verify-otp', {
      'phone': phone,
      'otp': otp,
    });
    await StorageService.saveToken(data['token']);
    final user = User.fromJson(data['user']);
    await StorageService.saveUserInfo(user.id, user.role);
    Organization? org;
    if (data['organization'] != null) {
      org = Organization.fromJson(data['organization']);
    }
    return {'user': user, 'organization': org};
  }

  static Future<Map<String, dynamic>> switchRole(String newRole) async {
    final data = await ApiService.post('/auth/switch-role', {'newRole': newRole});
    await StorageService.saveToken(data['token']);
    final user = User.fromJson(data['user']);
    await StorageService.saveUserInfo(user.id, user.role);
    return {'user': user};
  }

  static Future<User?> getCurrentUser() async {
    try {
      final data = await ApiService.get('/auth/me');
      return User.fromJson(data['user']);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getCurrentUserWithOrg() async {
    final data = await ApiService.get('/auth/me');
    final user = User.fromJson(data['user']);
    Organization? org;
    if (data['organization'] != null) {
      org = Organization.fromJson(data['organization']);
    }
    return {'user': user, 'organization': org};
  }

  static Future<void> updateFcmToken(String token) async {
    await ApiService.put('/auth/fcm-token', {'fcm_token': token});
  }

  static Future<void> logout() async {
    await StorageService.clear();
  }

  static Future<User> updateProfile({String? name}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    final data = await ApiService.put('/auth/profile', body);
    return User.fromJson(data['user']);
  }

  static Future<User> updatePhoto(XFile photo) async {
    final bytes = await photo.readAsBytes();
    final fileName = photo.name.isNotEmpty ? photo.name : 'profile-photo.jpg';
    final data = await ApiService.multipart(
      'PUT',
      '/auth/photo',
      files: [
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: fileName,
        ),
      ],
    );
    return User.fromJson(data['user']);
  }
}
