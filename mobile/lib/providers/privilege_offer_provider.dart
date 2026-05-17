import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/privilege_offer.dart';
import '../services/privilege_offer_service.dart';

class PrivilegeOfferProvider extends ChangeNotifier {
  List<PrivilegeOffer> _offers = [];
  bool _loading = false;
  String? _error;

  List<PrivilegeOffer> get offers => _offers;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadOffers({String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _offers = await PrivilegeOfferService.list(status: status);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<PrivilegeOffer> createOffer(
    Map<String, dynamic> data, {
    Uint8List? logoBytes,
    String? logoFilename,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    final offer = await PrivilegeOfferService.create(
      data,
      logoBytes: logoBytes,
      logoFilename: logoFilename,
      imageBytes: imageBytes,
      imageFilename: imageFilename,
    );
    _offers.insert(0, offer);
    notifyListeners();
    return offer;
  }

  Future<PrivilegeOffer> updateOffer(
    int id,
    Map<String, dynamic> data, {
    Uint8List? logoBytes,
    String? logoFilename,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    final offer = await PrivilegeOfferService.update(
      id,
      data,
      logoBytes: logoBytes,
      logoFilename: logoFilename,
      imageBytes: imageBytes,
      imageFilename: imageFilename,
    );
    final idx = _offers.indexWhere((o) => o.id == id);
    if (idx >= 0) _offers[idx] = offer;
    notifyListeners();
    return offer;
  }

  Future<void> deleteOffer(int id) async {
    await PrivilegeOfferService.delete(id);
    _offers.removeWhere((o) => o.id == id);
    notifyListeners();
  }
}
