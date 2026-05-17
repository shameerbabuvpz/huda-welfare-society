import 'package:http/http.dart' as http;

import '../models/organization.dart';
import 'api_service.dart';

class OrganizationService {
  static Future<List<Organization>> list({int page = 1}) async {
    final data = await ApiService.get('/organizations', queryParams: {'page': '$page'});
    return (data['data'] as List).map((o) => Organization.fromJson(o)).toList();
  }

  static Future<Organization> getById(int id) async {
    final data = await ApiService.get('/organizations/$id');
    return Organization.fromJson(data);
  }

  static Future<Organization> create(Map<String, dynamic> body) async {
    final data = await ApiService.post('/organizations', body);
    return Organization.fromJson(data);
  }

  static Future<Organization> update(int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('/organizations/$id', body);
    return Organization.fromJson(data);
  }

  static Future<Organization> uploadLogo(int orgId, List<int> bytes, String filename) async {
    final data = await ApiService.multipart(
      'PUT',
      '/organizations/$orgId/logo',
      files: [
        http.MultipartFile.fromBytes('logo', bytes, filename: filename),
      ],
    );
    return Organization.fromJson(data);
  }

  static Future<List<Map<String, dynamic>>> listAdmins(int orgId) async {
    final data = await ApiService.get('/organizations/$orgId/admins');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<Map<String, dynamic>> addAdmin(int orgId, {required String phone, String? name}) async {
    final body = <String, dynamic>{'phone': phone};
    if (name != null && name.isNotEmpty) body['name'] = name;
    return await ApiService.post('/organizations/$orgId/admins', body);
  }

  static Future<Map<String, dynamic>> updateAdmin(int orgId, int adminId, {String? phone, String? name}) async {
    final body = <String, dynamic>{};
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (name != null && name.isNotEmpty) body['name'] = name;
    return await ApiService.put('/organizations/$orgId/admins/$adminId', body);
  }

  static Future<void> removeAdmin(int orgId, int adminId) async {
    await ApiService.delete('/organizations/$orgId/admins/$adminId');
  }

  static Future<void> deleteOrg(int orgId) async {
    await ApiService.delete('/organizations/$orgId');
  }
}
