/**
 * Geospatial utility functions for field service geofencing.
 * Coordinates are formatted as GeoJSON: [longitude, latitude]
 */

export function calculateDistanceMeters(
  coord1: [number, number],
  coord2: [number, number]
): number {
  const [lon1, lat1] = coord1;
  const [lon2, lat2] = coord2;

  const R = 6371000; // Radius of the earth in meters
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) *
      Math.cos(deg2rad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c; // Distance in meters
  return Math.round(distance * 100) / 100;
}

function deg2rad(deg: number): number {
  return deg * (Math.PI / 180);
}

export function isWithinGeofence(
  currentCoord: [number, number],
  targetCoord: [number, number],
  radiusMeters: number = 200
): { isWithin: boolean; distanceMeters: number } {
  const distanceMeters = calculateDistanceMeters(currentCoord, targetCoord);
  return {
    isWithin: distanceMeters <= radiusMeters,
    distanceMeters
  };
}
