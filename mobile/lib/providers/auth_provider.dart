import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user.dart';
import '../models/organization.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  Organization? _organization;
  bool _loading = false;
  String? _error;
  bool _otpSent = false;

  User? get user => _user;
  Organization? get organization => _organization;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isSuperAdmin => _user?.isSuperAdmin ?? false;
  bool get otpSent => _otpSent;
  List<String> get availableRoles => _user?.roles ?? [];
  bool get hasMultipleRoles => _user?.hasMultipleRoles ?? false;

  Future<bool> requestOtp(String phone) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await AuthService.requestOtp(phone);
      _otpSent = true;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await AuthService.verifyOtpWithOrg(phone, otp);
      _user = result['user'] as User;
      _organization = result['organization'] as Organization?;
      _otpSent = false;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> switchRole(String newRole) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await AuthService.switchRole(newRole);
      _user = result['user'] as User;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void resetOtp() {
    _otpSent = false;
    _error = null;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final token = await StorageService.getToken();
    if (token == null) return;
    try {
      final result = await AuthService.getCurrentUserWithOrg();
      _user = result['user'] as User?;
      _organization = result['organization'] as Organization?;
      notifyListeners();
    } catch (_) {
      await StorageService.clear();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _otpSent = false;
    notifyListeners();
  }

  Future<bool> updateProfile({String? name}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await AuthService.updateProfile(name: name);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePhoto(XFile photo) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await AuthService.updatePhoto(photo);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
