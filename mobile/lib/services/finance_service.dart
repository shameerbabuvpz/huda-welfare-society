import 'api_service.dart';

class FinanceService {
  // ─── Categories ───────────────────────────────────────────────
  static Future<List<dynamic>> listCategories({String? type}) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type;
    final data = await ApiService.get('/finance/categories', queryParams: params);
    return data as List;
  }

  static Future<Map<String, dynamic>> createCategory(Map<String, dynamic> body) async {
    final data = await ApiService.post('/finance/categories', body);
    return data;
  }

  static Future<void> deleteCategory(int id) async {
    await ApiService.delete('/finance/categories/$id');
  }

  // ─── Transactions ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> listTransactions({
    int page = 1,
    String? type,
    int? categoryId,
    String? fromDate,
    String? toDate,
  }) async {
    final params = <String, String>{'page': '$page'};
    if (type != null) params['type'] = type;
    if (categoryId != null) params['category_id'] = '$categoryId';
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    return await ApiService.get('/finance/transactions', queryParams: params);
  }

  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> body) async {
    return await ApiService.post('/finance/transactions', body);
  }

  static Future<void> deleteTransaction(int id) async {
    await ApiService.delete('/finance/transactions/$id');
  }

  // ─── Summary ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getSummary({String? fromDate, String? toDate}) async {
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    final data = await ApiService.get('/finance/summary', queryParams: params);
    return Map<String, dynamic>.from(data);
  }
}
