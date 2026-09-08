import 'dart:math' as math;

class GeofenceUtil {
  static const double earthRadiusMeters = 6371000.0;

  /// Calculate great-circle distance between two points in meters using Haversine formula
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final rLat1 = _degreesToRadians(lat1);
    final rLat2 = _degreesToRadians(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rLat1) * math.cos(rLat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Determines whether the distance is strictly within the geofence threshold (default 200m)
  static bool isWithinGeofence(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    double thresholdMeters = 200.0,
  }) {
    final distance = calculateDistanceMeters(lat1, lon1, lat2, lon2);
    return distance <= thresholdMeters;
  }

  /// Format distance into user-friendly localized text
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
