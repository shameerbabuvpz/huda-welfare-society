import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class MemberProvider extends ChangeNotifier {
  List<Member> _members = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _currentSearch;
  int? _currentAyalkoottamId;
  bool get hasMore => _currentPage < _totalPages;

  List<Member> get members => _members;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  Future<void> loadMembers({int page = 1, String? search, int? ayalkoottamId}) async {
    _loading = true;
    _error = null;
    _currentSearch = search;
    _currentAyalkoottamId = ayalkoottamId;
    notifyListeners();
    try {
      final result = await MemberService.list(page: page, search: search, ayalkoottamId: ayalkoottamId);
      _members = (result['data'] as List).map((m) => Member.fromJson(m)).toList();
      final pagination = result['pagination'];
      _currentPage = pagination['page'];
      _totalPages = pagination['totalPages'];
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final nextPage = _currentPage + 1;
      final result = await MemberService.list(page: nextPage, search: _currentSearch, ayalkoottamId: _currentAyalkoottamId);
      final newMembers = (result['data'] as List).map((m) => Member.fromJson(m)).toList();
      _members = [..._members, ...newMembers];
      final pagination = result['pagination'];
      _currentPage = pagination['page'];
      _totalPages = pagination['totalPages'];
      _loadingMore = false;
      notifyListeners();
    } catch (e) {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createMember(Map<String, dynamic> data) async {
    try {
      await MemberService.create(data);
      await loadMembers(search: _currentSearch, ayalkoottamId: _currentAyalkoottamId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMember(int id, Map<String, dynamic> data) async {
    try {
      await MemberService.update(id, data);
      await loadMembers(page: _currentPage, search: _currentSearch, ayalkoottamId: _currentAyalkoottamId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMember(int id) async {
    try {
      await MemberService.remove(id);
      await loadMembers(page: _currentPage, search: _currentSearch, ayalkoottamId: _currentAyalkoottamId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Member Authentication Methods (for member login with code)
  // ═══════════════════════════════════════════════════════════════════════════

  String? _memberToken;
  Map<String, dynamic>? _memberProfile;

  String? get memberToken => _memberToken;
  Map<String, dynamic>? get memberProfile => _memberProfile;

  /// Set member token (from login)
  Future<void> setMemberToken(String token) async {
    _memberToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('member_token', token);
    // Also save to storage service for API calls
    await StorageService.saveToken(token);
    notifyListeners();
  }

  /// Get saved member token
  Future<String?> getMemberToken() async {
    if (_memberToken != null) return _memberToken;
    final prefs = await SharedPreferences.getInstance();
    _memberToken = prefs.getString('member_token');
    return _memberToken;
  }

  /// Clear member token (logout)
  Future<void> clearMemberToken() async {
    _memberToken = null;
    _memberProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('member_token');
    notifyListeners();
  }

  /// Change member login code
  Future<Map<String, dynamic>> changeCode(String currentCode, String newCode) async {
    try {
      final response = await ApiService.post(
        '/member-auth/change-code',
        {
          'currentCode': currentCode,
          'newCode': newCode,
        },

      );
      return response;
    } catch (e) {
      throw Exception('Failed to change code: $e');
    }
  }

  /// Get member profile
  Future<Map<String, dynamic>> getMemberProfile() async {
    try {
      final response = await ApiService.get('/member-auth/profile');
      if (response['success'] == true) {
        _memberProfile = response['member'];
        notifyListeners();
      }
      return response;
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Reset member's code to default (Admin function)
  Future<Map<String, dynamic>> resetMemberCodeToDefault(int memberId) async {
    try {
      final response = await ApiService.post(
        '/member-auth/reset-code',
        {'memberId': memberId},
      );
      // Reload members list after reset
      await loadMembers(page: _currentPage, search: _currentSearch, ayalkoottamId: _currentAyalkoottamId);
      return response;
    } catch (e) {
      throw Exception('Failed to reset code: $e');
    }
  }

  /// Get member code status (Admin view)
  Future<Map<String, dynamic>> getMemberCodeStatus(int memberId) async {
    try {
      final response = await ApiService.get(
        '/member-auth/code-status/$memberId',
      );
      return response;
    } catch (e) {
      throw Exception('Failed to get code status: $e');
    }
  }
}
