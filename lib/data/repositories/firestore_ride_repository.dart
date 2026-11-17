import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:latlong2/latlong.dart';
import 'package:toktok/data/repositories/firestore_trip_history_repository.dart';
import 'package:toktok/domain/models/driver.dart';
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/domain/models/trip.dart';
import 'package:toktok/domain/repositories/ride_repository.dart';

class FirestoreRideRepository implements RideRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  FirestoreRideRepository({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  @override
  Future<List<RideOption>> getRideTypes({double? distanceKm}) async {
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
    final user = _firebaseAuth.currentUser;
    try {
      final docRef = await _firestore.collection('ride_requests').add({
        'userId': user?.uid ?? 'guest',
        'userName': user?.displayName ?? 'عميل توصيلة',
        'from': from,
        'to': to,
        'pickupLat': pickupLatLng?.latitude ?? 30.0444,
        'pickupLng': pickupLatLng?.longitude ?? 31.2357,
        'dropoffLat': dropoffLatLng?.latitude ?? 30.0561,
        'dropoffLng': dropoffLatLng?.longitude ?? 31.2394,
        'rideType': rideType.name,
        'price': price,
        'distanceKm': distanceKm ?? 3.5,
        'paymentMethod': paymentMethod.name,
        'status': 'searching',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 2));
      return docRef.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Driver> searchForDriver(
    RideType type, {
    String? requestId,
  }) async {
    if (requestId != null) {
      final completer = Completer<Driver>();
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;

      sub = _firestore
          .collection('ride_requests')
          .doc(requestId)
          .snapshots()
          .listen((snapshot) {
            final data = snapshot.data();
            if (data != null &&
                data['status'] == 'accepted' &&
                data['driver'] is Map<String, dynamic> &&
                !completer.isCompleted) {
              final d = data['driver'] as Map<String, dynamic>;
              completer.complete(
                Driver(
                  id: (d['id'] as String?) ?? 'd1',
                  name: (d['name'] as String?) ?? 'أحمد محمد',
                  phone: (d['phone'] as String?) ?? '01012345678',
                  plateNumber: (d['plateNumber'] as String?) ?? 'س ع د 1234',
                  rating: (d['rating'] as num?)?.toDouble() ?? 4.8,
                  avatarUrl: d['avatarUrl'] as String?,
                ),
              );
            }
          });

      try {
        return await completer.future.timeout(
          const Duration(seconds: 4),
          onTimeout: () async {
            final driver = await _findOrDefaultDriver(type);
            try {
              await _firestore.collection('ride_requests').doc(requestId).update({
                'status': 'accepted',
                'driver': driver.toMap(),
                'acceptedAt': FieldValue.serverTimestamp(),
              });
            } catch (_) {}
            return driver;
          },
        );
      } finally {
        await sub.cancel();
      }
    }

    await Future.delayed(const Duration(seconds: 3));
    return _findOrDefaultDriver(type);
  }

  Future<Driver> _findOrDefaultDriver(RideType type) async {
    try {
      final driversSnap = await _firestore
          .collection('drivers')
          .where('vehicleType', isEqualTo: type.name)
          .where('isAvailable', isEqualTo: true)
          .limit(1)
          .get();

      if (driversSnap.docs.isNotEmpty) {
        final doc = driversSnap.docs.first;
        final d = doc.data();
        return Driver(
          id: doc.id,
          name: (d['name'] as String?) ?? 'أحمد محمد',
          phone: (d['phone'] as String?) ?? '01012345678',
          plateNumber: (d['plateNumber'] as String?) ?? 'س ع د 1234',
          rating: (d['rating'] as num?)?.toDouble() ?? 4.8,
          avatarUrl: d['avatarUrl'] as String?,
        );
      }
    } catch (_) {}

    switch (type) {
      case RideType.car:
        return const Driver(
          id: 'd_car_1',
          name: 'أحمد محمد',
          phone: '01012345678',
          plateNumber: 'س ع د 1234',
          rating: 4.8,
        );
      case RideType.motorcycle:
        return const Driver(
          id: 'd_moto_1',
          name: 'كريم حسن',
          phone: '01123456789',
          plateNumber: 'م ط ص 5678',
          rating: 4.7,
        );
      case RideType.scooter:
        return const Driver(
          id: 'd_scoot_1',
          name: 'محمود علي',
          phone: '01234567890',
          plateNumber: 'أ س ك 9012',
          rating: 4.9,
        );
    }
  }

  @override
  Future<void> updateRideStatus(String requestId, String status) async {
    try {
      await _firestore
          .collection('ride_requests')
          .doc(requestId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

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
  }) async {
    final now = DateTime.now();
    final durationMinutes = (distanceKm * 3).round();
    FirestoreTripHistoryRepository.sessionTrips.insert(
      0,
      Trip(
        id: requestId ?? 'trip_${now.millisecondsSinceEpoch}',
        from: from,
        to: to,
        rideType: rideType,
        price: price,
        driverName: driver.name,
        driverRating: driver.rating,
        driverPlate: driver.plateNumber,
        date: now,
        durationMinutes: durationMinutes,
        distanceKm: distanceKm,
        paymentMethod: paymentMethod,
      ),
    );

    final user = _firebaseAuth.currentUser;
    try {
      if (requestId != null) {
        await _firestore
            .collection('ride_requests')
            .doc(requestId)
            .update({
              'status': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 2));
      }

      if (user != null) {
        await _firestore
            .collection('trips')
            .add({
              'userId': user.uid,
              'requestId': requestId,
              'from': from,
              'to': to,
              'rideType': rideType.name,
              'price': price,
              'driverName': driver.name,
              'driverRating': driver.rating,
              'driverPlate': driver.plateNumber,
              'date': now.millisecondsSinceEpoch,
              'durationMinutes': durationMinutes,
              'distanceKm': distanceKm,
              'paymentMethod': paymentMethod.name,
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 2));

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({
              'totalTrips': FieldValue.increment(1),
              'totalKm': FieldValue.increment(distanceKm),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 2));
      }
    } catch (_) {}
  }

  @override
  Future<void> cancelSearch({String? requestId}) async {
    if (requestId != null) {
      await updateRideStatus(requestId, 'cancelled');
    }
  }
}
