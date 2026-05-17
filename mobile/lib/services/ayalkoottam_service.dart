import '../models/ayalkoottam.dart';
import 'api_service.dart';

class AyalkoottamService {
  static Future<Map<String, dynamic>> list({int page = 1, String? search}) async {
    final params = {'page': '$page'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    return await ApiService.get('/ayalkoottams', queryParams: params);
  }

  static Future<Ayalkoottam> getById(int id) async {
    final data = await ApiService.get('/ayalkoottams/$id');
    return Ayalkoottam.fromJson(data);
  }

  static Future<Ayalkoottam> create(Map<String, dynamic> body) async {
    final data = await ApiService.post('/ayalkoottams', body);
    return Ayalkoottam.fromJson(data);
  }

  static Future<Ayalkoottam> update(int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('/ayalkoottams/$id', body);
    return Ayalkoottam.fromJson(data);
  }

  static Future<void> deactivate(int id) async {
    await ApiService.put('/ayalkoottams/$id/deactivate', {});
  }

  /// Simple list for dropdown selection (no pagination)
  static Future<List<Ayalkoottam>> listAll() async {
    final data = await ApiService.get('/ayalkoottams/all');
    return (data as List).map((a) => Ayalkoottam.fromJson(a)).toList();
  }
}
