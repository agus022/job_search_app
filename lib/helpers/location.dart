import 'dart:math';

/// Calcula la distancia entre dos coordenadas (lat1, lon1) y (lat2, lon2) en kilómetros.
class LocationHelpers {
  double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0; // Radio de la Tierra en km
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Convierte grados a radianes.
  double _deg2rad(double deg) {
    return deg * pi / 180.0;
  }
}
