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

  static Future<List<AppNotification>> list({int page = 1}) async {
    final data = await ApiService.get('/notifications', queryParams: {'page': '$page'});
    return (data['data'] as List).map((n) => AppNotification.fromJson(n)).toList();
  }

  static Future<AppNotification> update(int id, {required String title, required String body}) async {
    final data = await ApiService.put('/notifications/$id', {'title': title, 'body': body});
    return AppNotification.fromJson(data);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/notifications/$id');
  }

  static Future<List<AppNotification>> myNotifications({int page = 1}) async {
    final data = await ApiService.get('/notifications/my-notifications', queryParams: {'page': '$page'});
    return (data['data'] as List).map((n) => AppNotification.fromJson(n)).toList();
  }
}
