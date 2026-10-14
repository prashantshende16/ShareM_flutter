class ApiConfig {
  static String? _customBaseUrl;

  static String get defaultBaseUrl {
    // When adb reverse tcp:8001 tcp:8001 is run, localhost:8001 connects directly via USB
    return 'http://localhost:8001/api/v1';
  }

  static String get baseUrl => _customBaseUrl ?? defaultBaseUrl;

  static set baseUrl(String url) {
    _customBaseUrl = url.trim().endsWith('/')
        ? url.trim().substring(0, url.trim().length - 1)
        : url.trim();
  }

  static void reset() {
    _customBaseUrl = null;
  }
}

