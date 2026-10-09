import 'dart:math' as math;

class GeoPoint {
  final double lat;
  final double lng;

  const GeoPoint({required this.lat, required this.lng});

  const GeoPoint.zero() : lat = 0, lng = 0;

  bool get isZero => lat == 0 && lng == 0;

  /// Rough great-circle distance in metres.
  double distanceKmTo(GeoPoint other) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(other.lat - lat);
    final dLng = _degToRad(other.lng - lng);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat)) *
            math.cos(_degToRad(other.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
  );

  @override
  String toString() =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}
