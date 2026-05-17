import 'package:flutter/material.dart';
import '../models/kuri_group.dart';
import '../services/kuri_service.dart';

class KuriProvider extends ChangeNotifier {
  List<KuriGroup> _groups = [];
  KuriGroup? _selectedGroup;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _currentSearch;
  bool get hasMore => _currentPage < _totalPages;

  List<KuriGroup> get groups => _groups;
  KuriGroup? get selectedGroup => _selectedGroup;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;

  Future<void> loadGroups({int page = 1, String? search}) async {
    _loading = true;
    _error = null;
    _currentSearch = search;
    notifyListeners();
    try {
      final result = await KuriService.listGroups(page: page, search: search);
      _groups = (result['data'] as List).map((g) => KuriGroup.fromJson(g)).toList();
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
      final result = await KuriService.listGroups(page: nextPage, search: _currentSearch);
      final newGroups = (result['data'] as List).map((g) => KuriGroup.fromJson(g)).toList();
      _groups = [..._groups, ...newGroups];
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

  Future<void> loadGroupDetail(int id) async {
    _loading = true;
    notifyListeners();
    try {
      _selectedGroup = await KuriService.getGroup(id);
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(Map<String, dynamic> data) async {
    try {
      await KuriService.createGroup(data);
      await loadGroups(search: _currentSearch);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addMember(int groupId, int memberId) async {
    try {
      await KuriService.addMember(groupId, memberId);
      await loadGroupDetail(groupId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeMember(int groupId, int memberId) async {
    try {
      await KuriService.removeMember(groupId, memberId);
      await loadGroupDetail(groupId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordCollection(int groupId, {required int memberId, required int monthNumber, double? amount}) async {
    try {
      await KuriService.recordCollection(groupId, memberId: memberId, monthNumber: monthNumber, amount: amount);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> selectWinner(int groupId, int memberId, int monthNumber) async {
    try {
      await KuriService.selectWinner(groupId, memberId, monthNumber);
      await loadGroupDetail(groupId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPayout(int groupId, {required int winnerId, required double amount, String? reference}) async {
    try {
      await KuriService.recordPayout(groupId, winnerId: winnerId, amount: amount, reference: reference);
      await loadGroupDetail(groupId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateGroup(int groupId, Map<String, dynamic> data) async {
    try {
      await KuriService.updateGroup(groupId, data);
      await loadGroupDetail(groupId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
