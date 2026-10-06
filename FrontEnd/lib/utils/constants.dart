/// Central place for config values — change these here, not scattered in screens.
class AppConstants {
  // IMPORTANT — set this based on how you're running the app:
  //   Android emulator talking to your laptop's FastAPI server -> http://10.0.2.2:8000
  //   Physical Android phone on same WiFi as your laptop       -> http://<laptop-LAN-IP>:8000
  //   iOS simulator                                             -> http://127.0.0.1:8000
  //   Deployed backend later                                    -> https://your-deployed-url
  static const String baseUrl = "http://127.0.0.1:8000";
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
