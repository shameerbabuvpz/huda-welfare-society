import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/privilege_offer.dart';
import 'api_service.dart';

class PrivilegeOfferService {
  // ── Admin ──
  static Future<List<PrivilegeOffer>> list({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final data = await ApiService.get('/privilege-offers', queryParams: params.isNotEmpty ? params : null);
    return (data as List).map((e) => PrivilegeOffer.fromJson(e)).toList();
  }

  static Future<PrivilegeOffer> create(
    Map<String, dynamic> body, {
    Uint8List? logoBytes,
    String? logoFilename,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    final fields = <String, String>{};
    body.forEach((k, v) {
      if (v != null) fields[k] = v.toString();
    });

    final files = <http.MultipartFile>[];
    if (logoBytes != null) {
      files.add(http.MultipartFile.fromBytes('logo', logoBytes, filename: logoFilename ?? 'logo.jpg'));
    }
    if (imageBytes != null) {
      files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: imageFilename ?? 'image.jpg'));
    }

    final data = await ApiService.multipart('POST', '/privilege-offers', fields: fields, files: files);
    return PrivilegeOffer.fromJson(data);
  }

  static Future<PrivilegeOffer> getById(int id) async {
    final data = await ApiService.get('/privilege-offers/$id');
    return PrivilegeOffer.fromJson(data);
  }

  static Future<PrivilegeOffer> update(
    int id,
    Map<String, dynamic> body, {
    Uint8List? logoBytes,
    String? logoFilename,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    final fields = <String, String>{};
    body.forEach((k, v) {
      if (v != null) fields[k] = v.toString();
    });

    final files = <http.MultipartFile>[];
    if (logoBytes != null) {
      files.add(http.MultipartFile.fromBytes('logo', logoBytes, filename: logoFilename ?? 'logo.jpg'));
    }
    if (imageBytes != null) {
      files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: imageFilename ?? 'image.jpg'));
    }

    final data = await ApiService.multipart('PUT', '/privilege-offers/$id', fields: fields, files: files);
    return PrivilegeOffer.fromJson(data);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/privilege-offers/$id');
  }

  // ── Member ──
  static Future<List<PrivilegeOffer>> listActive() async {
    final data = await ApiService.get('/privilege-offers/active');
    return (data as List).map((e) => PrivilegeOffer.fromJson(e)).toList();
  }

  static Future<PrivilegeRedemption> redeem(String qrCode) async {
    final data = await ApiService.post('/privilege-offers/redeem', {'qr_code': qrCode});
    return PrivilegeRedemption.fromJson(data);
  }

  static Future<List<PrivilegeRedemption>> myRedemptions() async {
    final data = await ApiService.get('/privilege-offers/my-redemptions');
    return (data as List).map((e) => PrivilegeRedemption.fromJson(e)).toList();
  }
}
