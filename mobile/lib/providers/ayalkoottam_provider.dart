import 'package:flutter/material.dart';
import '../models/ayalkoottam.dart';
import '../services/ayalkoottam_service.dart';

class AyalkoottamProvider extends ChangeNotifier {
  List<Ayalkoottam> _list = [];
  List<Ayalkoottam> _dropdownList = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _currentSearch;
  bool get hasMore => _currentPage < _totalPages;

  List<Ayalkoottam> get list => _list;
  List<Ayalkoottam> get dropdownList => _dropdownList;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;

  Future<void> load({int page = 1, String? search}) async {
    _loading = true;
    _error = null;
    _currentSearch = search;
    notifyListeners();
    try {
      final result = await AyalkoottamService.list(page: page, search: search);
      _list = (result['data'] as List).map((a) => Ayalkoottam.fromJson(a)).toList();
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
      final result = await AyalkoottamService.list(page: nextPage, search: _currentSearch);
      final newItems = (result['data'] as List).map((a) => Ayalkoottam.fromJson(a)).toList();
      _list = [..._list, ...newItems];
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

  Future<void> loadDropdown() async {
    try {
      _dropdownList = await AyalkoottamService.listAll();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await AyalkoottamService.create(data);
      await load(search: _currentSearch);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> data) async {
    try {
      await AyalkoottamService.update(id, data);
      await load(page: _currentPage, search: _currentSearch);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivate(int id) async {
    try {
      await AyalkoottamService.deactivate(id);
      await load(page: _currentPage, search: _currentSearch);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await AyalkoottamService.delete(id);
      await load(search: _currentSearch);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
