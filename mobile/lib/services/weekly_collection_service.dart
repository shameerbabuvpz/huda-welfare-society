import 'api_service.dart';

class WeeklyCollectionService {
  static Future<Map<String, dynamic>> list({
    int page = 1,
    int? ayalkoottamId,
    String? weekStartDate,
    String? fromDate,
    String? toDate,
  }) async {
    final params = <String, String>{'page': '$page'};
    if (ayalkoottamId != null) params['ayalkoottam_id'] = '$ayalkoottamId';
    if (weekStartDate != null) params['week_start_date'] = weekStartDate;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    return await ApiService.get('/weekly-collections', queryParams: params);
  }

  static Future<Map<String, dynamic>> upsert(Map<String, dynamic> body) async {
    return await ApiService.post('/weekly-collections', body);
  }

  static Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    return await ApiService.put('/weekly-collections/$id', body);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/weekly-collections/$id');
  }

  static Future<Map<String, dynamic>> consolidated({
    String groupBy = 'week',
    String? fromDate,
    String? toDate,
    int? ayalkoottamId,
  }) async {
    final params = <String, String>{'group_by': groupBy};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (ayalkoottamId != null) params['ayalkoottam_id'] = '$ayalkoottamId';
    final data = await ApiService.get('/weekly-collections/consolidated', queryParams: params);
    return Map<String, dynamic>.from(data);
  }
}
