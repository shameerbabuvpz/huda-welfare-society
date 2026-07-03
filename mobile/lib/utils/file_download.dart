/// Cross-platform file save / share helper.
///
/// On mobile/desktop this writes the bytes to a temporary file and, when
/// [share] is true, opens the system share sheet (via share_plus).
/// On web it triggers a browser download of the file.
///
/// The correct implementation is selected at compile time so that `dart:io`
/// is never imported into the web build.
export 'file_download_io.dart' if (dart.library.html) 'file_download_web.dart';
