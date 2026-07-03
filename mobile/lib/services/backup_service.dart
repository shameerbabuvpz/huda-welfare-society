import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/file_download.dart';
import 'storage_service.dart';

class BackupService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Download a full database backup (.sql) and share/save it.
  /// Returns the saved file path.
  static Future<String?> downloadBackup() async {
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

    // Mobile: save to a temp file and open the share sheet.
    // Web: trigger a browser download.
    return saveOrShareBytes(
      response.bodyBytes,
      filename,
      mimeType: 'application/sql',
      share: true,
      shareText: 'Ayalkoottam database backup',
    );
  }

  /// Restore the database from a previously downloaded .sql backup file.
  static Future<Map<String, dynamic>> restoreBackup(
    Uint8List fileBytes, {
    required String filename,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/backup/restore');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(await _authHeaders())
      ..fields['confirm'] = 'RESTORE'
      ..files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: filename));

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
