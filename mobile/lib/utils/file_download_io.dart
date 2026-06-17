import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes [bytes] to a temporary file. When [share] is true the system share
/// sheet is opened so the user can save or send the file. Returns the on-disk
/// path of the written file.
Future<String?> saveOrShareBytes(
  Uint8List bytes,
  String filename, {
  String? mimeType,
  bool share = false,
  String? shareText,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);

  if (share) {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      text: shareText,
    );
  }

  return file.path;
}
