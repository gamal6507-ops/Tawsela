import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/domain/models/trip.dart';
import 'package:toktok/domain/repositories/trip_history_repository.dart';

class FirestoreTripHistoryRepository implements TripHistoryRepository {
  static final List<Trip> sessionTrips = [];

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  FirestoreTripHistoryRepository({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  @override
  Future<List<Trip>> getTripHistory() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return List.from(sessionTrips);

    try {
      final snap = await _firestore
          .collection('trips')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));

      final remoteTrips = snap.docs.map((doc) {
        final data = doc.data();
        final rideTypeName = data['rideType'] as String? ?? 'car';
        final rideType = RideType.values.firstWhere(
          (e) => e.name == rideTypeName,
          orElse: () => RideType.car,
        );
        final paymentName = data['paymentMethod'] as String? ?? 'wallet';
        final paymentMethod = PaymentMethod.values.firstWhere(
          (e) => e.name == paymentName,
          orElse: () => PaymentMethod.wallet,
        );
        final rawDate = data['date'];
        final date = rawDate is int
            ? DateTime.fromMillisecondsSinceEpoch(rawDate)
            : DateTime.now();

        return Trip(
          id: doc.id,
          from: (data['from'] as String?) ?? '',
          to: (data['to'] as String?) ?? '',
          rideType: rideType,
          price: (data['price'] as num?)?.toInt() ?? 0,
          driverName: (data['driverName'] as String?) ?? 'كابتن توصيلة',
          driverRating: (data['driverRating'] as num?)?.toDouble() ?? 4.8,
          driverPlate: (data['driverPlate'] as String?) ?? '',
          date: date,
          durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 10,
          distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 3.5,
          paymentMethod: paymentMethod,
          userRating: (data['userRating'] as num?)?.toInt(),
        );
      }).toList();

      return remoteTrips.isNotEmpty ? remoteTrips : List.from(sessionTrips);
    } catch (_) {
      return List.from(sessionTrips);
    }
  }

  @override
  Future<double> getTotalSpent() async {
    final trips = await getTripHistory();
    return trips.fold<double>(0.0, (total, trip) => total + trip.price);
  }
}
