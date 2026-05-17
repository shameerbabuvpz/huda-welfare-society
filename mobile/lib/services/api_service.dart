import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> _headers() async {
    return {
      'Content-Type': 'application/json',
      ...await _authHeaders(),
    };
  }

  static Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http.post(uri, headers: await _headers(), body: jsonEncode(body));
    return _handleResponse(response);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http.put(uri, headers: await _headers(), body: jsonEncode(body));
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http.delete(uri, headers: await _headers());
    return _handleResponse(response);
  }

  static Future<dynamic> multipart(
    String method,
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.MultipartRequest(method, uri);
    request.headers.addAll(await _authHeaders());

    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body['error']?['message'] ?? 'Something went wrong';
    throw ApiException(response.statusCode, message);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
