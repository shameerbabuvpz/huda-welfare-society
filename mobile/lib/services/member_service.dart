import '../models/member.dart';
import 'api_service.dart';

class MemberService {
  static Future<Map<String, dynamic>> list({int page = 1, int? limit, String? search, int? ayalkoottamId}) async {
    final params = {'page': '$page'};
    if (limit != null) params['limit'] = '$limit';
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (ayalkoottamId != null) params['ayalkoottam_id'] = '$ayalkoottamId';
    return await ApiService.get('/members', queryParams: params);
  }

  static Future<Member> getById(int id) async {
    final data = await ApiService.get('/members/$id');
    return Member.fromJson(data);
  }

  static Future<Member> create(Map<String, dynamic> body) async {
    final data = await ApiService.post('/members', body);
    return Member.fromJson(data);
  }

  static Future<Member> update(int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('/members/$id', body);
    return Member.fromJson(data);
  }

  static Future<void> remove(int id) async {
    await ApiService.delete('/members/$id');
  }

  static Future<Member> getProfile() async {
    final data = await ApiService.get('/members/profile');
    return Member.fromJson(data);
  }

  /// President/Secretary: list members of the logged-in user's own ayalkoottam.
  /// Returns the ayalkoottam name plus the list of members (contact info).
  static Future<({String? ayalkoottamName, List<Member> members})> myAyalkoottamMembers({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await ApiService.get('/members/my-ayalkoottam', queryParams: params.isEmpty ? null : params);
    final list = (data['data'] as List? ?? [])
        .map((e) => Member.fromJson(e as Map<String, dynamic>))
        .toList();
    final akName = data['ayalkoottam'] is Map ? data['ayalkoottam']['name'] as String? : null;
    return (ayalkoottamName: akName, members: list);
  }

  /// Returns the name of existing member with this designation, or null if available
  static Future<String?> checkDesignation(int ayalkoottamId, String designation) async {
    final data = await ApiService.get('/members/check-designation', queryParams: {
      'ayalkoottam_id': '$ayalkoottamId',
      'designation': designation,
    });
    if (data['exists'] == true) {
      return data['member']['name'];
    }
    return null;
  }
}
