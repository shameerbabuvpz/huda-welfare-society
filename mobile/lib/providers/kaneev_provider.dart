import 'package:flutter/material.dart';
import '../models/kaneev_group.dart';
import '../services/kaneev_service.dart';

class KaneevProvider extends ChangeNotifier {
  KaneevGroup? _group;
  bool _loading = false;
  String? _error;

  KaneevGroup? get group => _group;
  KaneevGroup? get selectedGroup => _group;
  List<KaneevGroup> get groups => _group != null ? [_group!] : [];
  bool get loading => _loading;
  String? get error => _error;

  /// Alias used by list screen
  Future<void> loadGroups() => loadKaneev();

  /// Alias used by detail screen (groupId ignored – single group per org)
  Future<void> loadGroupDetail(int groupId) => loadKaneev();

  /// Load (or auto-create) the single kaneev group
  Future<void> loadKaneev() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _group = await KaneevService.getKaneev();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDonationAmount(double amount) async {
    try {
      await KaneevService.updateGroup({'donation_amount': amount});
      await loadKaneev();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addMember(int memberId) async {
    try {
      await KaneevService.addMember(memberId);
      await loadKaneev();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createGroup(Map<String, dynamic> data) async {
    try {
      await loadKaneev(); // auto-creates single group
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeMember(int memberId) async {
    try {
      await KaneevService.removeMember(memberId);
      await loadKaneev();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordDonation({required int memberId, required int monthNumber, double? amount}) async {
    try {
      await KaneevService.recordDonation(memberId: memberId, monthNumber: monthNumber, amount: amount);
      await loadKaneev();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> selectRecipient(int memberId, int monthNumber) async {
    try {
      await KaneevService.selectRecipient(memberId, monthNumber);
      await loadKaneev();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
