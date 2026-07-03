import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Triggers a browser download of [bytes] as [filename]. The [share] and
/// [shareText] parameters are ignored on web (a download is always performed).
/// Returns null because there is no persistent on-disk path on the web.
Future<String?> saveOrShareBytes(
  Uint8List bytes,
  String filename, {
  String? mimeType,
  bool share = false,
  String? shareText,
}) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType ?? 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
  return null;
}
