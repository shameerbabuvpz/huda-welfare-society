import '../models/asset.dart';
import 'api_service.dart';

class AssetService {
  static Future<Map<String, dynamic>> list({int page = 1, String? search, String? status, String? condition}) async {
    final params = <String, String>{'page': '$page'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;
    if (condition != null) params['condition'] = condition;
    return await ApiService.get('/assets', queryParams: params);
  }

  static Future<List<Asset>> listAvailable({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await ApiService.get('/assets/available', queryParams: params);
    return (data as List).map((a) => Asset.fromJson(a)).toList();
  }

  static Future<Map<String, dynamic>> issueRegister({int page = 1, String? status, String? search}) async {
    final params = <String, String>{'page': '$page'};
    if (status != null) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    return await ApiService.get('/assets/issue-register', queryParams: params);
  }

  static Future<Map<String, dynamic>> damageReport({int page = 1}) async {
    return await ApiService.get('/assets/damage-report', queryParams: {'page': '$page'});
  }

  static Future<Map<String, dynamic>> stats() async {
    return await ApiService.get('/assets/stats');
  }

  static Future<Asset> create(Map<String, dynamic> body) async {
    final data = await ApiService.post('/assets', body);
    return Asset.fromJson(data);
  }

  static Future<Asset> update(int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('/assets/$id', body);
    return Asset.fromJson(data);
  }

  static Future<void> issue(int assetId, int memberId, {String? dueDate, String? remarks}) async {
    final body = <String, dynamic>{'member_id': memberId};
    if (dueDate != null) body['due_date'] = dueDate;
    if (remarks != null) body['remarks'] = remarks;
    await ApiService.post('/assets/$assetId/issue', body);
  }

  static Future<void> returnAsset(int assetId, {String? remarks, String? conditionOnReturn}) async {
    final body = <String, dynamic>{};
    if (remarks != null) body['remarks'] = remarks;
    if (conditionOnReturn != null) body['condition_on_return'] = conditionOnReturn;
    await ApiService.post('/assets/$assetId/return', body);
  }

  static Future<List<AssetTransaction>> myAssets() async {
    final data = await ApiService.get('/assets/my-assets');
    return (data as List).map((a) => AssetTransaction.fromJson(a)).toList();
  }
}
