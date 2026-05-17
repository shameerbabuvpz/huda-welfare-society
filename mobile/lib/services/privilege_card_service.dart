import '../models/privilege_card.dart';
import 'api_service.dart';

class PrivilegeCardService {
  static Future<PrivilegeCard> generate(int memberId) async {
    final data = await ApiService.post('/privilege-cards/$memberId/generate', {});
    return PrivilegeCard.fromJson(data);
  }

  static Future<PrivilegeCard> getByMember(int memberId) async {
    final data = await ApiService.get('/privilege-cards/$memberId');
    return PrivilegeCard.fromJson(data);
  }

  static Future<PrivilegeCard> getMyCard() async {
    final data = await ApiService.get('/privilege-cards/my-card');
    return PrivilegeCard.fromJson(data);
  }
}
