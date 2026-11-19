import 'package:latlong2/latlong.dart';
import '../models/driver.dart';
import '../models/ride.dart';
import '../models/trip.dart';
import '../models/ride_request.dart';

abstract class RideRepository {
  Stream<RideRequest?> watchRide(String id) => const Stream.empty();
  Future<RideRequest?> getActiveRide() async => null;
  Future<List<RideOption>> getRideTypes({double? distanceKm});

  Future<Driver> searchForDriver(RideType type, {String? requestId});

  Future<String?> createRideRequest({
    required String from,
    required String to,
    required RideType rideType,
    required int price,
    required PaymentMethod paymentMethod,
    LatLng? pickupLatLng,
    LatLng? dropoffLatLng,
    double? distanceKm,
  });

  Future<void> updateRideStatus(String requestId, String status);

  Future<void> completeRideAndSaveTrip({
    required String? requestId,
    required String from,
    required String to,
    required RideType rideType,
    required int price,
    required Driver driver,
    required PaymentMethod paymentMethod,
    double distanceKm = 4.0,
  });

  Future<void> cancelSearch({String? requestId});
}
