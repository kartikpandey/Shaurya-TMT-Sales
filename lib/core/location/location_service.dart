import 'package:geolocator/geolocator.dart';

import '../domain/geo_point.dart';

/// Thin wrapper over `geolocator` with graceful degradation: every call
/// returns `null` instead of throwing when permission or the GPS service is
/// unavailable, so the field flow never blocks.
class LocationService {
  const LocationService();

  static const LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 15),
  );

  Future<bool> get isServiceEnabled => Geolocator.isLocationServiceEnabled();

  Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Current position, or `null` when unavailable.
  Future<GeoPoint?> current() async {
    try {
      if (!await ensurePermission()) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      );
      return GeoPoint(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return lastKnown();
    }
  }

  Future<GeoPoint?> lastKnown() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;
      return GeoPoint(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return null;
    }
  }
}
