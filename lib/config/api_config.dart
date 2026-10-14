import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String? _customBaseUrl;

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8001/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        // 10.0.2.2 is default for Android emulator, LAN IP for physical device
        return 'http://10.0.2.2:8001/api/v1';
      }
    } catch (_) {}
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
