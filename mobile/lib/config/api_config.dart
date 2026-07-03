class ApiConfig {
  static const String _production =
      'https://ayalkkoottam-e6adi.ondigitalocean.app/api/v1';

  // Override at build/run time with:
  //   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: _production);
}
