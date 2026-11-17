import 'package:latlong2/latlong.dart';
import 'package:toktok/domain/models/driver.dart';
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/domain/models/trip.dart';
import 'package:toktok/domain/repositories/ride_repository.dart';

class FakeRideRepository implements RideRepository {
  @override
  Future<List<RideOption>> getRideTypes({double? distanceKm}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final km = distanceKm ?? 3.5;
    return [
      RideOption(
        type: RideType.car,
        name: 'عربية',
        price: (10 + km * 4).round(),
        etaMinutes: 4,
        icon: '🚗',
        suffix: 'مكيف',
      ),
      RideOption(
        type: RideType.motorcycle,
        name: 'موتوسيكل',
        price: (5 + km * 2).round(),
        etaMinutes: 2,
        icon: '🏍️',
        suffix: 'سريع',
      ),
      RideOption(
        type: RideType.scooter,
        name: 'اسكوتر',
        price: (6 + km * 2.5).round(),
        etaMinutes: 3,
        icon: '🛵',
        suffix: 'اقتصادي',
      ),
    ];
  }

  @override
  Future<Driver> searchForDriver(
    RideType type, {
    String? requestId,
  }) async {
    await Future.delayed(const Duration(seconds: 3));
    return const Driver(
      id: 'd1',
      name: 'أحمد محمد',
      phone: '01012345678',
      plateNumber: 'س ع د 1234',
      rating: 4.8,
    );
  }

  @override
  Future<String?> createRideRequest({
    required String from,
    required String to,
    required RideType rideType,
    required int price,
    required PaymentMethod paymentMethod,
    LatLng? pickupLatLng,
    LatLng? dropoffLatLng,
    double? distanceKm,
  }) async {
    return 'fake-request-1';
  }

  @override
  Future<void> updateRideStatus(String requestId, String status) async {}

  @override
  Future<void> completeRideAndSaveTrip({
    required String? requestId,
    required String from,
    required String to,
    required RideType rideType,
    required int price,
    required Driver driver,
    required PaymentMethod paymentMethod,
    double distanceKm = 4.0,
  }) async {}

  @override
  Future<void> cancelSearch({String? requestId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
