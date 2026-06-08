import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config/api_config.dart';
import 'storage_service.dart';
// ignore_for_file: deprecated_member_use

class BackupService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Download a full database backup (.sql) and share/save it.
  /// Returns the saved file path.
  static Future<String> downloadBackup() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/backup/download');
    final response = await http.get(uri, headers: await _authHeaders());

    if (response.statusCode != 200) {
      throw Exception('Backup failed (${response.statusCode})');
    }

    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .substring(0, 19);
    final filename = 'ayalkoottam-backup-$ts.sql';

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(response.bodyBytes);

    if (!kIsWeb) {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/sql')],
        subject: filename,
        text: 'Ayalkoottam database backup',
      );
    }
    return file.path;
  }

  /// Restore the database from a previously downloaded .sql backup file.
  static Future<Map<String, dynamic>> restoreBackup(String filePath) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/backup/restore');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(await _authHeaders())
      ..fields['confirm'] = 'RESTORE'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      String message = 'Restore failed (${streamed.statusCode})';
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
