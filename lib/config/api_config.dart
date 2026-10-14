import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _prefKey = 'sharem_backend_base_url';

  // Wi-Fi Host IP of the development workstation
  static const String wifiHostUrl = 'http://192.168.10.124:8001/api/v1';
  static const String usbHostUrl = 'http://localhost:8001/api/v1';
  static const String emulatorUrl = 'http://10.0.2.2:8001/api/v1';

  static const List<String> candidateUrls = [
    wifiHostUrl,
    usbHostUrl,
    emulatorUrl,
  ];

  static String? _customBaseUrl;

  static String get defaultBaseUrl => wifiHostUrl;

  static String get baseUrl => _customBaseUrl ?? defaultBaseUrl;

  static set baseUrl(String url) {
    _customBaseUrl = _cleanUrl(url);
    _saveToPrefs(_customBaseUrl!);
  }

  static String _cleanUrl(String url) {
    final trimmed = url.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _customBaseUrl = _cleanUrl(saved);
        return;
      }
    } catch (_) {}

    // If no custom URL is saved, auto-detect the fastest responding server
    await autoDetectBaseUrl();
  }

  static Future<void> _saveToPrefs(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, url);
    } catch (_) {}
  }

  static Future<void> reset() async {
    _customBaseUrl = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
  }

  /// Automatically tests connectivity against candidate URLs and picks the first working one.
  static Future<String?> autoDetectBaseUrl() async {
    for (final candidate in candidateUrls) {
      try {
        final uri = Uri.parse('$candidate/settings');
        final res = await http.get(uri).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          _customBaseUrl = candidate;
          await _saveToPrefs(candidate);
          return candidate;
        }
      } catch (_) {
        // Continue to next candidate
      }
    }
    return null;
  }
}
