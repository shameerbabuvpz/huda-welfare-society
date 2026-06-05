import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config/api_config.dart';
import 'storage_service.dart';
// ignore_for_file: deprecated_member_use

class ExportService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Download file from export endpoint and trigger share
  static Future<void> exportAndShare(
    String path, {
    required String filename,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/export$path')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _authHeaders());

    if (response.statusCode != 200) {
      throw Exception('Export failed: ${response.statusCode}');
    }

    if (kIsWeb) {
      // Web: trigger browser download
      _downloadWeb(response.bodyBytes, filename);
    } else {
      // Mobile: save to temp and share
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  static void _downloadWeb(Uint8List bytes, String filename) {
    // For web platform - handled via dart:html (not available on mobile)
    // This is a no-op fallback; the share dialog handles most cases
  }

  // ── Convenience methods ──

  static Future<void> membersExcel({int? ayalkoottamId}) async {
    final params = <String, String>{};
    if (ayalkoottamId != null) params['ayalkoottam_id'] = ayalkoottamId.toString();
    await exportAndShare('/members/excel', filename: 'members.xlsx', queryParams: params.isNotEmpty ? params : null);
  }

  static Future<void> membersPdf({int? ayalkoottamId}) async {
    final params = <String, String>{};
    if (ayalkoottamId != null) params['ayalkoottam_id'] = ayalkoottamId.toString();
    await exportAndShare('/members/pdf', filename: 'members.pdf', queryParams: params.isNotEmpty ? params : null);
  }

  static Future<void> kuriExcel(int groupId) async {
    await exportAndShare('/kuri/$groupId/excel', filename: 'kuri-report.xlsx');
  }

  static Future<void> kuriPdf(int groupId) async {
    await exportAndShare('/kuri/$groupId/pdf', filename: 'kuri-report.pdf');
  }

  static Future<void> kaneevExcel() async {
    await exportAndShare('/kaneev/excel', filename: 'kaneev-report.xlsx');
  }

  static Future<void> kaneevPdf() async {
    await exportAndShare('/kaneev/pdf', filename: 'kaneev-report.pdf');
  }

  static Future<void> financeExcel({String? fromDate, String? toDate}) async {
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    await exportAndShare('/finance/excel', filename: 'finance-report.xlsx', queryParams: params.isNotEmpty ? params : null);
  }

  static Future<void> financePdf({String? fromDate, String? toDate}) async {
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    await exportAndShare('/finance/pdf', filename: 'finance-report.pdf', queryParams: params.isNotEmpty ? params : null);
  }

  static Future<void> leadersExcel() async {
    await exportAndShare('/leaders/excel', filename: 'office-bearers.xlsx');
  }

  static Future<void> leadersPdf() async {
    await exportAndShare('/leaders/pdf', filename: 'office-bearers.pdf');
  }
}
