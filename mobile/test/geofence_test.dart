import 'package:test/test.dart';
import 'package:field_service_mobile/core/utils/geofence_util.dart';

void main() {
  group('GeofenceUtil Haversine Tests', () {
    const ticketLat = 13.7563;
    const ticketLon = 100.5018;

    test('Identical coordinates should yield distance 0', () {
      final distance = GeofenceUtil.calculateDistanceMeters(ticketLat, ticketLon, ticketLat, ticketLon);
      expect(distance, closeTo(0.0, 0.001));
      expect(GeofenceUtil.isWithinGeofence(ticketLat, ticketLon, ticketLat, ticketLon), isTrue);
    });

    test('Coordinates within ~50 meters should be within geofence', () {
      const techLat = ticketLat + 0.0003;
      const techLon = ticketLon;

      final distance = GeofenceUtil.calculateDistanceMeters(techLat, techLon, ticketLat, ticketLon);
      expect(distance, lessThan(200.0));
      expect(GeofenceUtil.isWithinGeofence(techLat, techLon, ticketLat, ticketLon, thresholdMeters: 200.0), isTrue);
    });

    test('Coordinates ~850 meters away should be outside geofence', () {
      const techLat = ticketLat + 0.0075;
      const techLon = ticketLon + 0.0055;

      final distance = GeofenceUtil.calculateDistanceMeters(techLat, techLon, ticketLat, ticketLon);
      expect(distance, greaterThan(200.0));
      expect(GeofenceUtil.isWithinGeofence(techLat, techLon, ticketLat, ticketLon, thresholdMeters: 200.0), isFalse);
    });

    test('formatDistance should format meters and kilometers correctly', () {
      expect(GeofenceUtil.formatDistance(45.2), '45 m');
      expect(GeofenceUtil.formatDistance(1250.0), '1.25 km');
    });
  });
}
