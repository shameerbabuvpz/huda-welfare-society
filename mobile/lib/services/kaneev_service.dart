import '../models/kaneev_group.dart';
import 'api_service.dart';

class KaneevService {
  /// Get (or auto-create) the single kaneev group for this org
  static Future<KaneevGroup> getKaneev() async {
    final data = await ApiService.get('/kaneev/group');
    return KaneevGroup.fromJson(data);
  }

  static Future<void> updateGroup(Map<String, dynamic> body) async {
    await ApiService.put('/kaneev/group', body);
  }

  static Future<void> addMember(int memberId) async {
    await ApiService.post('/kaneev/members', {'member_id': memberId});
  }

  static Future<void> removeMember(int memberId) async {
    await ApiService.delete('/kaneev/members/$memberId');
  }

  static Future<void> setMemberStatus(int memberId, String status) async {
    await ApiService.patch('/kaneev/members/$memberId/status', {'status': status});
  }

  // Donations
  static Future<void> recordDonation({
    required int memberId,
    required int monthNumber,
    double? amount,
  }) async {
    final body = <String, dynamic>{
      'member_id': memberId,
      'month_number': monthNumber,
    };
    if (amount != null) body['amount'] = amount;
    await ApiService.post('/kaneev/donations', body);
  }

  static Future<List<dynamic>> getDonations({int? monthNumber}) async {
    final params = <String, String>{};
    if (monthNumber != null) params['monthNumber'] = '$monthNumber';
    return await ApiService.get('/kaneev/donations', queryParams: params);
  }

  // Recipients
  static Future<void> selectRecipient(int memberId, int monthNumber) async {
    await ApiService.post('/kaneev/recipients', {
      'member_id': memberId,
      'month_number': monthNumber,
    });
  }

  static Future<List<dynamic>> recipientHistory() async {
    return await ApiService.get('/kaneev/recipients');
  }

  static Future<KaneevMemberSummary?> myKaneev() async {
    final data = await ApiService.get('/kaneev/my-kaneev');
    if (data == null) return null;
    return KaneevMemberSummary.fromJson(data as Map<String, dynamic>);
  }
}
