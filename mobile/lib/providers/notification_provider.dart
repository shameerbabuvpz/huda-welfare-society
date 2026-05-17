import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  List<AppNotification> _adminNotifications = [];
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get adminNotifications => _adminNotifications;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadMemberNotifications({int page = 1}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await NotificationApiService.myNotifications(page: page);
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminNotifications({int page = 1}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _adminNotifications = await NotificationApiService.list(page: page);
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> sendNotification({required String title, required String body, String audienceType = 'all', List<int>? memberIds}) async {
    try {
      await NotificationApiService.send(title: title, body: body, audienceType: audienceType, memberIds: memberIds);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNotification(int id, {required String title, required String body}) async {
    try {
      await NotificationApiService.update(id, title: title, body: body);
      await loadAdminNotifications();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNotification(int id) async {
    try {
      await NotificationApiService.delete(id);
      _adminNotifications.removeWhere((n) => n.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
