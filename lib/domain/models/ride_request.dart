import 'package:latlong2/latlong.dart';
import 'driver.dart';
import 'ride.dart';
import 'trip.dart';

class RideRequest {
  final String id;
  final Map<String, dynamic> data;
  const RideRequest(this.id, this.data);
  String get status => data['status'] as String;
  String get from => data['from'] as String;
  String get to => data['to'] as String;
  RideType get type => RideType.values.byName(data['rideType'] as String);
  int get price => (data['price'] as num).toInt();
  double get distanceKm => (data['distanceKm'] as num).toDouble();
  PaymentMethod get payment => PaymentMethod.cash;
  LatLng get pickup => LatLng(
    (data['pickupLat'] as num).toDouble(),
    (data['pickupLng'] as num).toDouble(),
  );
  LatLng get dropoff => LatLng(
    (data['dropoffLat'] as num).toDouble(),
    (data['dropoffLng'] as num).toDouble(),
  );
  Driver? get driver =>
      data['driver'] is Map
          ? Driver.fromMap(Map<String, dynamic>.from(data['driver'] as Map))
          : null;
}
