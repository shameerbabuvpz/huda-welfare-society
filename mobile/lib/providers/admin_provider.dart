import 'package:flutter/material.dart';
import '../models/admin.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  List<Admin> _admins = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _currentSearch;
  bool get hasMore => _currentPage < _totalPages;

  List<Admin> get admins => _admins;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  Future<void> loadAdmins({int page = 1, String? search}) async {
    _loading = true;
    _error = null;
    _currentSearch = search;
    notifyListeners();
    try {
      final result = await AdminService.list(page: page, search: search);
      _admins = (result['data'] as List).map((a) => Admin.fromJson(a)).toList();
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
      final result = await AdminService.list(page: nextPage, search: _currentSearch);
      final newAdmins = (result['data'] as List).map((a) => Admin.fromJson(a)).toList();
      _admins = [..._admins, ...newAdmins];
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

  Future<bool> createAdmin(Map<String, dynamic> data) async {
    try {
      await AdminService.create(data);
      await loadAdmins(search: _currentSearch);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAdmin(int id, Map<String, dynamic> data) async {
    try {
      await AdminService.update(id, data);
      await loadAdmins(page: _currentPage, search: _currentSearch);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAdmin(int id) async {
    try {
      await AdminService.remove(id);
      await loadAdmins(page: _currentPage, search: _currentSearch);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
