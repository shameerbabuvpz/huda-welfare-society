import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/member_service.dart';

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
}
