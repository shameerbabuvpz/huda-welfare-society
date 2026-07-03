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

  static Future<void> delete(int id) async {
    await ApiService.delete('/ayalkoottams/$id');
  }

  /// Simple list for dropdown selection (no pagination)
  static Future<List<Ayalkoottam>> listAll() async {
    final data = await ApiService.get('/ayalkoottams/all');
    return (data as List).map((a) => Ayalkoottam.fromJson(a)).toList();
  }

  /// Office-bearers directory: every ayalkoottam with its president & secretary.
  static Future<List<AyalkoottamLeaders>> leaders() async {
    final data = await ApiService.get('/ayalkoottams/leaders');
    return ((data['data'] as List?) ?? [])
        .map((e) => AyalkoottamLeaders.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// One row of the office-bearers directory.
class AyalkoottamLeaders {
  final int ayalkoottamId;
  final String ayalkoottamName;
  final String presidentName;
  final String presidentCode;
  final String presidentPhone;
  final String secretaryName;
  final String secretaryCode;
  final String secretaryPhone;

  AyalkoottamLeaders({
    required this.ayalkoottamId,
    required this.ayalkoottamName,
    required this.presidentName,
    required this.presidentCode,
    required this.presidentPhone,
    required this.secretaryName,
    required this.secretaryCode,
    required this.secretaryPhone,
  });

  factory AyalkoottamLeaders.fromJson(Map<String, dynamic> json) {
    return AyalkoottamLeaders(
      ayalkoottamId: json['ayalkoottam_id'] ?? 0,
      ayalkoottamName: json['ayalkoottam_name'] ?? '',
      presidentName: json['president_name'] ?? '',
      presidentCode: json['president_code'] ?? '',
      presidentPhone: json['president_phone'] ?? '',
      secretaryName: json['secretary_name'] ?? '',
      secretaryCode: json['secretary_code'] ?? '',
      secretaryPhone: json['secretary_phone'] ?? '',
    );
  }
}
