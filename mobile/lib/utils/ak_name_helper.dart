/// Strip common "HUDA AYALKOOTAM" prefix to show only the distinguishing part.
/// Handles variant spellings (AYAKOOTAM, AYALKOOTAM) and separator styles (–, -).
String shortAkName(String name) {
  final stripped = name.replaceFirst(
    RegExp(r'^HUDA\s+AYA?LKOOTAM\s*[–\-]?\s*', caseSensitive: false),
    '',
  );
  return stripped.isEmpty ? name : stripped;
}
