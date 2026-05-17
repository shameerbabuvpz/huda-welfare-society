import 'package:flutter/material.dart';
import '../models/finance.dart';
import '../services/finance_service.dart';

class FinanceProvider extends ChangeNotifier {
  // ─── State ──────────────────────────────────────────────────
  List<FinanceCategory> _categories = [];
  List<FinanceTransaction> _transactions = [];
  Map<String, dynamic> _summary = {'income': 0.0, 'expense': 0.0, 'balance': 0.0};
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _currentType;

  // ─── Getters ────────────────────────────────────────────────
  List<FinanceCategory> get categories => _categories;
  List<FinanceTransaction> get transactions => _transactions;
  Map<String, dynamic> get summary => _summary;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get hasMore => _currentPage < _totalPages;

  // ─── Categories ─────────────────────────────────────────────
  Future<void> loadCategories({String? type}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await FinanceService.listCategories(type: type);
      _categories = data.map((c) => FinanceCategory.fromJson(c)).toList();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory(String name, String type) async {
    try {
      await FinanceService.createCategory({'name': name, 'type': type});
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await FinanceService.deleteCategory(id);
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Transactions ──────────────────────────────────────────
  Future<void> loadTransactions({String? type, int page = 1}) async {
    _loading = true;
    _error = null;
    _currentType = type;
    notifyListeners();
    try {
      final result = await FinanceService.listTransactions(page: page, type: type);
      _transactions = (result['data'] as List).map((t) => FinanceTransaction.fromJson(t)).toList();
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
      final result = await FinanceService.listTransactions(page: nextPage, type: _currentType);
      final newTxns = (result['data'] as List).map((t) => FinanceTransaction.fromJson(t)).toList();
      _transactions = [..._transactions, ...newTxns];
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

  Future<bool> createTransaction(Map<String, dynamic> data) async {
    try {
      await FinanceService.createTransaction(data);
      await loadTransactions(type: _currentType);
      await loadSummary();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await FinanceService.deleteTransaction(id);
      await loadTransactions(type: _currentType);
      await loadSummary();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Summary ───────────────────────────────────────────────
  Future<void> loadSummary() async {
    try {
      _summary = await FinanceService.getSummary();
      notifyListeners();
    } catch (e) {
      // Silently fail - summary is optional
    }
  }
}
