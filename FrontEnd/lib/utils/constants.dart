import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Central place for config values — change these here, not scattered in screens.
class AppConstants {
  /// Optional compile-time override, e.g. for a physical phone on the same
  /// WiFi as the laptop running the backend:
  ///   flutter run --dart-define=BASE_URL=http://192.168.1.23:8000
  static const String _overrideBaseUrl = String.fromEnvironment('BASE_URL');

  /// Base URL of the FastAPI backend, resolved per platform so the app works
  /// without hand-editing this file for every device:
  ///   Android emulator               -> http://10.0.2.2:8000
  ///     (10.0.2.2 is the emulator's alias for the host machine's localhost)
  ///   iOS simulator / desktop / web  -> http://127.0.0.1:8000
  ///   Physical phone / deployed API  -> pass --dart-define=BASE_URL=...
  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000";
    }
    return "http://127.0.0.1:8000";
  }
  // Demo fallback location — used ONLY if GPS permission is denied or
  // unavailable during a panel demo, so the app never dead-ends. Real builds
  // should always prefer live GPS from LocationService.
  static const double fallbackLat = 18.1124; // Vizianagaram, AP
  static const double fallbackLng = 83.3956;

  static const List<String> emergencyTypes = [
    "Medical Emergency",
    "Accident",
    "Fire",
    "Other",
  ];
}
