import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/file_download.dart';
import 'storage_service.dart';

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

    // Mobile: save to a temp file and open the share sheet.
    // Web: trigger a browser download.
    await saveOrShareBytes(
      response.bodyBytes,
      filename,
      mimeType: _mimeForFilename(filename),
      share: true,
    );
  }

  static String _mimeForFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.csv')) return 'text/csv';
    return 'application/octet-stream';
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
