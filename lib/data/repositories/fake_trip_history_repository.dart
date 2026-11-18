import 'package:toktok/domain/models/trip.dart';
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/domain/repositories/trip_history_repository.dart';

class FakeTripHistoryRepository implements TripHistoryRepository {
  final List<Trip> _trips = [
    Trip(
      id: 'tr1',
      from: 'المول',
      to: 'البيت',
      rideType: RideType.motorcycle,
      price: 12,
      driverName: 'أحمد محمد',
      driverRating: 4.8,
      driverPlate: 'س ع د 1234',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      durationMinutes: 15,
      distanceKm: 4.2,
      paymentMethod: PaymentMethod.wallet,
      userRating: 5,
    ),
    Trip(
      id: 'tr2',
      from: 'البيت',
      to: 'الشغل',
      rideType: RideType.car,
      price: 25,
      driverName: 'علي حسن',
      driverRating: 4.5,
      driverPlate: 'ع ب ج 5678',
      date: DateTime.now().subtract(const Duration(days: 1)),
      durationMinutes: 20,
      distanceKm: 6.1,
      paymentMethod: PaymentMethod.card,
      userRating: 4,
    ),
    Trip(
      id: 'tr3',
      from: 'الشغل',
      to: 'المستشفى',
      rideType: RideType.scooter,
      price: 15,
      driverName: 'حسين أحمد',
      driverRating: 4.9,
      driverPlate: 'د ه و 9012',
      date: DateTime.now().subtract(const Duration(days: 3)),
      durationMinutes: 18,
      distanceKm: 5.0,
      paymentMethod: PaymentMethod.wallet,
      userRating: 5,
    ),
    Trip(
      id: 'tr4',
      from: 'المستشفى',
      to: 'البيت',
      rideType: RideType.car,
      price: 25,
      driverName: 'أحمد محمد',
      driverRating: 4.8,
      driverPlate: 'س ع د 1234',
      date: DateTime.now().subtract(const Duration(days: 5)),
      durationMinutes: 10,
      distanceKm: 3.8,
      paymentMethod: PaymentMethod.wallet,
    ),
    Trip(
      id: 'tr5',
      from: 'المول',
      to: 'البيت',
      rideType: RideType.motorcycle,
      price: 12,
      driverName: 'خالد محمود',
      driverRating: 4.6,
      driverPlate: 'ز ح ط 3456',
      date: DateTime.now().subtract(const Duration(days: 7)),
      durationMinutes: 22,
      distanceKm: 7.3,
      paymentMethod: PaymentMethod.card,
      userRating: 4,
    ),
  ];

  @override
  Future<List<Trip>> getTripHistory() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_trips);
  }

  @override
  Future<double> getTotalSpent() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _trips.fold<double>(0.0, (sum, t) => sum + t.price);
  }
}
