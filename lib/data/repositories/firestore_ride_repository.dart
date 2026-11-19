import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:latlong2/latlong.dart';
import 'package:toktok/core/services/fare_calculator.dart';
import 'package:toktok/domain/models/driver.dart';
import 'package:toktok/domain/models/ride.dart';
import 'package:toktok/domain/models/ride_request.dart';
import 'package:toktok/domain/models/trip.dart';
import 'package:toktok/domain/repositories/ride_repository.dart';

class FirestoreRideRepository extends RideRepository {
  final FirebaseFirestore _db;
  final auth.FirebaseAuth _auth;
  FirestoreRideRepository({
    FirebaseFirestore? firestore,
    auth.FirebaseAuth? firebaseAuth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = firebaseAuth ?? auth.FirebaseAuth.instance;
  String get _uid =>
      _auth.currentUser?.uid ?? (throw StateError('سجل الدخول أولاً'));

  @override
  Future<List<RideOption>> getRideTypes({double? distanceKm}) async {
    final km = distanceKm ?? 3.5;
    return RideType.values
        .map(
          (type) => RideOption(
            type: type,
            name: type.displayName,
            price: FareCalculator.price(type, km),
            etaMinutes: 0,
            icon: type.icon,
            suffix: 'دفع كاش • مسافة تقريبية',
          ),
        )
        .toList();
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
    final uid = _uid;
    if (pickupLatLng == null ||
        dropoffLatLng == null ||
        from.trim().isEmpty ||
        to.trim().isEmpty) {
      throw ArgumentError('حدد نقطة الانطلاق والوجهة على الخريطة');
    }
    if (paymentMethod != PaymentMethod.cash) {
      throw StateError('المتاح حالياً الدفع كاش فقط');
    }
    final km = FareCalculator.distance(pickupLatLng, dropoffLatLng);
    if (km > 200 || price != FareCalculator.price(rideType, km)) {
      throw ArgumentError('عرض السعر غير صالح');
    }
    final pointer = _db.collection('active_rides').doc(uid);
    final request = _db.collection('ride_requests').doc();
    return _db.runTransaction((tx) async {
      final active = await tx.get(pointer);
      if (active.exists) return active.data()!['requestId'] as String;
      tx.set(request, {
        'userId': uid,
        'userName': _auth.currentUser?.displayName ?? 'راكب',
        'from': from.trim(),
        'to': to.trim(),
        'pickupLat': pickupLatLng.latitude,
        'pickupLng': pickupLatLng.longitude,
        'dropoffLat': dropoffLatLng.latitude,
        'dropoffLng': dropoffLatLng.longitude,
        'rideType': rideType.name,
        'price': price,
        'distanceKm': km,
        'paymentMethod': 'cash',
        'status': 'searching',
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(pointer, {'requestId': request.id});
      return request.id;
    });
  }

  @override
  Stream<RideRequest?> watchRide(String id) => _db
      .collection('ride_requests')
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? RideRequest(doc.id, doc.data()!) : null);

  @override
  Future<RideRequest?> getActiveRide() async {
    final pointer = await _db
        .collection('active_rides')
        .doc(_uid)
        .get(const GetOptions(source: Source.server));
    if (!pointer.exists) return null;
    final doc = await _db
        .collection('ride_requests')
        .doc(pointer.data()!['requestId'] as String)
        .get(const GetOptions(source: Source.server));
    return doc.exists ? RideRequest(doc.id, doc.data()!) : null;
  }

  @override
  Future<Driver> searchForDriver(RideType type, {String? requestId}) async {
    if (requestId == null) throw ArgumentError('الطلب غير موجود');
    final r = await watchRide(requestId)
        .firstWhere((r) => r != null && r.status != 'searching')
        .timeout(const Duration(seconds: 90));
    if (r?.driver == null || r!.status == 'cancelled') {
      throw StateError('تم إلغاء الطلب');
    }
    return r.driver!;
  }

  @override
  Future<void> updateRideStatus(String requestId, String status) async {
    throw UnsupportedError('حالة الرحلة تتغير من واجهة السائق المعتمد');
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
    double distanceKm = 4,
  }) async {
    if (requestId == null) throw ArgumentError('الطلب غير موجود');
    final uid = _uid;
    final ref = _db.collection('ride_requests').doc(requestId);
    final tripRef = _db.collection('trips').doc(requestId);
    await _db.runTransaction((tx) async {
      final ride = await tx.get(ref);
      final trip = await tx.get(tripRef);
      final data = ride.data();
      if (data == null || data['userId'] != uid || !trip.exists) {
        throw StateError('الرحلة لم تكتمل بعد');
      }
      if (data['status'] == 'completed') return;
      if (data['status'] != 'arrived') throw StateError('الرحلة لم تصل بعد');
      tx.update(ref, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      tx.delete(_db.collection('active_rides').doc(uid));
    });
  }

  @override
  Future<void> cancelSearch({String? requestId}) async {
    if (requestId == null) return;
    final uid = _uid;
    final ref = _db.collection('ride_requests').doc(requestId);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final data = doc.data();
      if (data == null || data['userId'] != uid) {
        throw StateError('الطلب غير موجود');
      }
      if (data['status'] == 'cancelled') return;
      if (!['searching', 'accepted'].contains(data['status'])) {
        throw StateError('بدأت الرحلة ولا يمكن إلغاؤها');
      }
      tx.update(ref, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.delete(_db.collection('active_rides').doc(uid));
      if (data['driverId'] is String) {
        tx.update(_db.collection('drivers').doc(data['driverId'] as String), {
          'isAvailable': true,
          'activeRideId': null,
        });
      }
    });
  }
}
