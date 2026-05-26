import '../models/kuri_group.dart';
import 'api_service.dart';

class KuriService {
  // Groups
  static Future<Map<String, dynamic>> listGroups({int page = 1, String? search}) async {
    final params = <String, String>{'page': '$page'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    return await ApiService.get('/kuri', queryParams: params);
  }

  static Future<KuriGroup> getGroup(int id) async {
    final data = await ApiService.get('/kuri/$id');
    return KuriGroup.fromJson(data);
  }

  static Future<KuriGroup> createGroup(Map<String, dynamic> body) async {
    final data = await ApiService.post('/kuri', body);
    return KuriGroup.fromJson(data);
  }

  static Future<void> addMember(int groupId, int memberId) async {
    await ApiService.post('/kuri/$groupId/members', {'member_id': memberId});
  }

  static Future<void> addGuestMember(int groupId, {required String name, String? phone}) async {
    final body = <String, dynamic>{'name': name};
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    await ApiService.post('/kuri/$groupId/guests', body);
  }

  static Future<void> removeMember(int groupId, int memberId) async {
    await ApiService.delete('/kuri/$groupId/members/$memberId');
  }

  // Collections
  static Future<void> recordCollection(int groupId, {
    required int memberId,
    required int monthNumber,
    double? amount,
  }) async {
    final body = <String, dynamic>{
      'member_id': memberId,
      'month_number': monthNumber,
    };
    if (amount != null) body['amount'] = amount;
    await ApiService.post('/kuri/$groupId/collections', body);
  }

  static Future<List<dynamic>> getCollections(int groupId, {int? monthNumber}) async {
    final params = <String, String>{};
    if (monthNumber != null) params['monthNumber'] = '$monthNumber';
    return await ApiService.get('/kuri/$groupId/collections', queryParams: params);
  }

  // Winners
  static Future<void> selectWinner(int groupId, int memberId, int monthNumber) async {
    await ApiService.post('/kuri/$groupId/winners', {
      'member_id': memberId,
      'month_number': monthNumber,
    });
  }

  static Future<List<KuriWinner>> winnerHistory(int groupId) async {
    final data = await ApiService.get('/kuri/$groupId/winners');
    return (data as List).map((w) => KuriWinner.fromJson(w)).toList();
  }

  // Payouts
  static Future<void> recordPayout(int groupId, {
    required int winnerId,
    required double amount,
    String? reference,
  }) async {
    await ApiService.post('/kuri/$groupId/payouts', {
      'winner_id': winnerId,
      'amount': amount,
      if (reference != null) 'reference': reference,
    });
  }

  // Update group
  static Future<KuriGroup> updateGroup(int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('/kuri/$id', body);
    return KuriGroup.fromJson(data);
  }

  // Member view
  static Future<List<KuriPaymentStatus>> myKuri() async {
    final data = await ApiService.get('/kuri/my-kuri');
    return (data as List).map((k) => KuriPaymentStatus.fromJson(k)).toList();
  }
}
