import 'api_service.dart';

class InfaccSyncService {
  static Future<Map<String, dynamic>> getStatus() async {
    final res = await ApiService.get('/infacc-sync/status');
    return Map<String, dynamic>.from(res);
  }

  static Future<Map<String, dynamic>> setCredentials(String phone, String password) async {
    final res = await ApiService.post('/infacc-sync/credentials', {
      'phone': phone,
      'password': password,
    });
    return Map<String, dynamic>.from(res);
  }

  static Future<Map<String, dynamic>> sync() async {
    final res = await ApiService.post('/infacc-sync/sync', {});
    return Map<String, dynamic>.from(res);
  }
}
