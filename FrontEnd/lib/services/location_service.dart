import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';

/// Wraps device GPS. Per the brief's requirement, coordinates are NEVER
/// hardcoded in the actual request logic — this is the single real source
/// of location, with a documented demo-safe fallback only if permission is
/// denied or location services are off (so a panel demo never hard-fails).
class LocationService {
  static Future<({double lat, double lng, bool isRealGps})> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (lat: AppConstants.fallbackLat, lng: AppConstants.fallbackLng, isRealGps: false);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return (lat: AppConstants.fallbackLat, lng: AppConstants.fallbackLng, isRealGps: false);
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return (lat: AppConstants.fallbackLat, lng: AppConstants.fallbackLng, isRealGps: false);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 8));

      return (lat: position.latitude, lng: position.longitude, isRealGps: true);
    } catch (_) {
      // Any GPS failure (timeout, emulator with no location set, etc.) —
      // degrade to the fallback rather than blocking the SOS flow.
      return (lat: AppConstants.fallbackLat, lng: AppConstants.fallbackLng, isRealGps: false);
    }
  }
}
