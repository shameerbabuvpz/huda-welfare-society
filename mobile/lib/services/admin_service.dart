import 'api_service.dart';

class AdminService {
  static Future<Map<String, dynamic>> list({int page = 1, String? search}) async {
    final params = <String, String>{'page': '$page'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    return await ApiService.get('/admins', queryParams: params);
  }

  static Future<Map<String, dynamic>> getById(int id) async {
    final data = await ApiService.get('/admins/$id');
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final data = await ApiService.post('/admins', body);
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('/admins/$id', body);
    return Map<String, dynamic>.from(data);
  }

  static Future<void> remove(int id) async {
    await ApiService.delete('/admins/$id');
  }
}
