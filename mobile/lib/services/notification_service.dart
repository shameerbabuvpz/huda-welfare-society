import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationApiService {
  static Future<void> send({
    required String title,
    required String body,
    String audienceType = 'all',
    List<int>? memberIds,
  }) async {
    await ApiService.post('/notifications', {
      'title': title,
      'body': body,
      'audience_type': audienceType,
      if (memberIds != null) 'member_ids': memberIds,
    });
  }

  static Future<Map<String, dynamic>> list({int page = 1}) async {
    return await ApiService.get('/notifications', queryParams: {'page': '$page'});
  }

  static Future<List<AppNotification>> myNotifications({int page = 1}) async {
    final data = await ApiService.get('/notifications/my-notifications', queryParams: {'page': '$page'});
    return (data['data'] as List).map((n) => AppNotification.fromJson(n)).toList();
  }
}
