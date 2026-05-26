import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';

class AssetProvider extends ChangeNotifier {
  List<Asset> _assets = [];
  List<Asset> _availableAssets = [];
  List<AssetTransaction> _issueRegister = [];
  AssetStats? _stats;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _currentSearch;
  bool get hasMore => _currentPage < _totalPages;

  List<Asset> get assets => _assets;
  List<Asset> get availableAssets => _availableAssets;
  List<AssetTransaction> get issueRegister => _issueRegister;
  AssetStats? get stats => _stats;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;

  Future<void> loadAssets({int page = 1, String? search}) async {
    _loading = true;
    _error = null;
    _currentSearch = search;
    notifyListeners();
    try {
      final result = await AssetService.list(page: page, search: search);
      _assets = (result['data'] as List).map((a) => Asset.fromJson(a)).toList();
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
      final result = await AssetService.list(page: nextPage, search: _currentSearch);
      final newAssets = (result['data'] as List).map((a) => Asset.fromJson(a)).toList();
      _assets = [..._assets, ...newAssets];
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

  Future<void> loadAvailableAssets({String? search}) async {
    try {
      _availableAssets = await AssetService.listAvailable(search: search);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadIssueRegister({int page = 1, String? status, String? search}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await AssetService.issueRegister(page: page, status: status, search: search);
      _issueRegister = (result['data'] as List).map((a) => AssetTransaction.fromJson(a)).toList();
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

  Future<void> loadStats() async {
    try {
      final data = await AssetService.stats();
      _stats = AssetStats.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createAsset(Map<String, dynamic> data) async {
    try {
      await AssetService.create(data);
      await loadAssets(search: _currentSearch);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> issueAsset(int assetId, int memberId, {String? dueDate, String? remarks}) async {
    try {
      await AssetService.issue(assetId, memberId, dueDate: dueDate, remarks: remarks);
      await loadAssets(page: _currentPage, search: _currentSearch);
      await loadStats();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> returnAsset(int assetId, {String? remarks, String? conditionOnReturn}) async {
    try {
      await AssetService.returnAsset(assetId, remarks: remarks, conditionOnReturn: conditionOnReturn);
      await loadAssets(page: _currentPage, search: _currentSearch);
      await loadStats();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAsset(int assetId, Map<String, dynamic> data) async {
    try {
      await AssetService.update(assetId, data);
      await loadAssets(page: _currentPage, search: _currentSearch);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAsset(int assetId) async {
    try {
      await AssetService.delete(assetId);
      await loadAssets(page: _currentPage, search: _currentSearch);
      await loadStats();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
