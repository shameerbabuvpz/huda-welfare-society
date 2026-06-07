import 'package:flutter/material.dart';
import '../models/weekly_collection.dart';
import '../services/weekly_collection_service.dart';

class WeeklyCollectionProvider extends ChangeNotifier {
  // ─── State ──────────────────────────────────────────────────
  List<WeeklyCollection> _entries = [];
  ConsolidationReport? _report;
  bool _loading = false;
  bool _reportLoading = false;
  String? _error;

  // Balance cache: ayalkoottamId -> balance value
  final Map<int, double> _balanceCache = {};
  bool _balanceLoading = false;

  // Report filters
  String _groupBy = 'week';
  String? _fromDate;
  String? _toDate;
  int? _filterAyalkoottamId;

  // ─── Getters ────────────────────────────────────────────────
  List<WeeklyCollection> get entries => _entries;
  ConsolidationReport? get report => _report;
  bool get loading => _loading;
  bool get reportLoading => _reportLoading;
  String? get error => _error;
  bool get balanceLoading => _balanceLoading;
  double? balanceFor(int ayalkoottamId) => _balanceCache[ayalkoottamId];
  String get groupBy => _groupBy;
  String? get fromDate => _fromDate;
  String? get toDate => _toDate;
  int? get filterAyalkoottamId => _filterAyalkoottamId;

  // ─── Entries ────────────────────────────────────────────────
  Future<void> loadEntries({int? ayalkoottamId, String? weekStartDate}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await WeeklyCollectionService.list(
        ayalkoottamId: ayalkoottamId,
        weekStartDate: weekStartDate,
      );
      _entries = (result['data'] as List)
          .map((e) => WeeklyCollection.fromJson(e))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> saveEntry(Map<String, dynamic> body) async {
    try {
      await WeeklyCollectionService.upsert(body);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Look up an existing entry for a given ayalkoottam + collection day.
  /// Returns null if none exists yet.
  Future<WeeklyCollection?> findEntry(int ayalkoottamId, String date) async {
    try {
      final result = await WeeklyCollectionService.list(
        ayalkoottamId: ayalkoottamId,
        weekStartDate: date,
      );
      final list = (result['data'] as List);
      if (list.isEmpty) return null;
      return WeeklyCollection.fromJson(list.first);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteEntry(int id) async {
    try {
      await WeeklyCollectionService.delete(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Fetch and cache the running balance for an ayalkoottam (optionally before a given week).
  Future<void> fetchBalance(int ayalkoottamId, {String? beforeWeek}) async {
    _balanceLoading = true;
    notifyListeners();
    try {
      final data = await WeeklyCollectionService.getBalance(ayalkoottamId, beforeWeek: beforeWeek);
      _balanceCache[ayalkoottamId] = (double.tryParse('${data['balance'] ?? 0}') ?? 0);
    } catch (_) {
      _balanceCache[ayalkoottamId] = 0;
    }
    _balanceLoading = false;
    notifyListeners();
  }

  // ─── Consolidated report ────────────────────────────────────
  void setGroupBy(String value) {
    _groupBy = value;
    loadReport();
  }

  void setDateRange(String? from, String? to) {
    _fromDate = from;
    _toDate = to;
    loadReport();
  }

  void setAyalkoottamFilter(int? id) {
    _filterAyalkoottamId = id;
    loadReport();
  }

  Future<void> loadReport() async {
    _reportLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await WeeklyCollectionService.consolidated(
        groupBy: _groupBy,
        fromDate: _fromDate,
        toDate: _toDate,
        ayalkoottamId: _filterAyalkoottamId,
      );
      _report = ConsolidationReport.fromJson(data);
    } catch (e) {
      _error = e.toString();
    }
    _reportLoading = false;
    notifyListeners();
  }
}
