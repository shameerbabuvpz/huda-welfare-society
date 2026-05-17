import 'package:http/http.dart' as http;
import '../models/banner.dart' as app;
import 'api_service.dart';

class BannerService {
  static Future<List<app.Banner>> list() async {
    final data = await ApiService.get('/banners');
    return (data as List).map((b) => app.Banner.fromJson(b)).toList();
  }

  static Future<List<app.Banner>> listActive() async {
    final data = await ApiService.get('/banners/active');
    return (data as List).map((b) => app.Banner.fromJson(b)).toList();
  }

  static Future<app.Banner> create({
    required String title,
    required String imagePath,
    int sortOrder = 0,
  }) async {
    final data = await ApiService.multipart(
      'POST',
      '/banners',
      fields: {
        'title': title,
        'sort_order': sortOrder.toString(),
      },
      files: [
        await http.MultipartFile.fromPath('image', imagePath),
      ],
    );
    return app.Banner.fromJson(data);
  }

  static Future<app.Banner> update(
    int id, {
    String? title,
    String? imagePath,
    int? sortOrder,
    bool? isActive,
  }) async {
    final fields = <String, String>{};
    if (title != null) fields['title'] = title;
    if (sortOrder != null) fields['sort_order'] = sortOrder.toString();
    if (isActive != null) fields['is_active'] = isActive.toString();

    final files = <http.MultipartFile>[];
    if (imagePath != null) {
      files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    final data = await ApiService.multipart(
      'PUT',
      '/banners/$id',
      fields: fields,
      files: files,
    );
    return app.Banner.fromJson(data);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/banners/$id');
  }
}
