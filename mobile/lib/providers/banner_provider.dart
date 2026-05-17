import 'package:flutter/material.dart';
import '../models/banner.dart' as app;
import '../services/banner_service.dart';

class BannerProvider extends ChangeNotifier {
  List<app.Banner> _banners = [];
  List<app.Banner> _activeBanners = [];
  bool _loading = false;
  String? _error;

  List<app.Banner> get banners => _banners;
  List<app.Banner> get activeBanners => _activeBanners;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadBanners() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _banners = await BannerService.list();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadActiveBanners() async {
    try {
      _activeBanners = await BannerService.listActive();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createBanner({
    required String title,
    required String imagePath,
    int sortOrder = 0,
  }) async {
    try {
      await BannerService.create(title: title, imagePath: imagePath, sortOrder: sortOrder);
      await loadBanners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBanner(int id, {String? title, String? imagePath, int? sortOrder, bool? isActive}) async {
    try {
      await BannerService.update(id, title: title, imagePath: imagePath, sortOrder: sortOrder, isActive: isActive);
      await loadBanners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBanner(int id) async {
    try {
      await BannerService.delete(id);
      _banners.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
