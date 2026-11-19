import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:toktok/domain/models/ride.dart';

/// Approximate straight-line distance, not a road route. Mirrors firestore.rules.
class FareCalculator {
  static double distance(LatLng from, LatLng to) {
    final north = (to.latitude - from.latitude) * 111;
    final east = (to.longitude - from.longitude) * 96;
    return math.max(
      1,
      (math.sqrt(north * north + east * east) * 10).ceil() / 10,
    );
  }

  static int price(RideType type, double km) => switch (type) {
    RideType.car => (10 + km * 4).ceil(),
    RideType.motorcycle => (5 + km * 2).ceil(),
    RideType.scooter => (6 + km * 2.5).ceil(),
  };
}
