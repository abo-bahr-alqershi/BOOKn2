import 'dart:math';

// This utility might interact with location services or perform map-related calculations.
// For now, it will be a placeholder.

class LocationUtils {
  LocationUtils._();

  // Example: Calculate distance between two points (using Haversine formula)
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371; // Kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
                   cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
                   sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance; // Distance in kilometers
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // Add other location utility functions as needed
}