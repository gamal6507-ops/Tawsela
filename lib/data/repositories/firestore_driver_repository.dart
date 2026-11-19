import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

class FirestoreDriverRepository {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  FirestoreDriverRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : db = firestore ?? FirebaseFirestore.instance,
       auth = firebaseAuth ?? FirebaseAuth.instance;
  String get uid =>
      auth.currentUser?.uid ?? (throw StateError('سجل الدخول أولاً'));
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile() =>
      db.collection('drivers').doc(uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> requests(String type) =>
      db
          .collection('ride_requests')
          .where('status', isEqualTo: 'searching')
          .where('rideType', isEqualTo: type)
          .limit(30)
          .snapshots();

  Future<void> register({
    required String name,
    required String phone,
    required String plate,
    required String type,
  }) async {
    await db.collection('drivers').doc(uid).set({
      'name': name.trim(),
      'phone': phone.trim(),
      'plateNumber': plate.trim(),
      'vehicleType': type,
      'approved': false,
      'isAvailable': false,
      'activeRideId': null,
      'rating': 0.0,
    });
  }

  Future<void> setAvailable(bool available) =>
      db.collection('drivers').doc(uid).update({'isAvailable': available});

  Future<void> accept(String id) async {
    final driverRef = db.collection('drivers').doc(uid);
    final rideRef = db.collection('ride_requests').doc(id);
    await db.runTransaction((tx) async {
      final driver = (await tx.get(driverRef)).data();
      final ride = (await tx.get(rideRef)).data();
      if (driver == null ||
          driver['approved'] != true ||
          driver['isAvailable'] != true ||
          driver['activeRideId'] != null ||
          ride == null ||
          ride['status'] != 'searching' ||
          ride['userId'] == uid ||
          ride['rideType'] != driver['vehicleType']) {
        throw StateError('الطلب لم يعد متاحاً أو لديك رحلة نشطة');
      }
      tx.update(rideRef, {
        'status': 'accepted',
        'driverId': uid,
        'driver': {
          'id': uid,
          'name': driver['name'],
          'phone': driver['phone'],
          'plateNumber': driver['plateNumber'],
          'rating': driver['rating'] ?? 0.0,
          'avatarUrl': null,
        },
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      tx.update(driverRef, {'isAvailable': false, 'activeRideId': id});
    });
  }

  Future<void> advance(String id, String status) async {
    final rideRef = db.collection('ride_requests').doc(id);
    final tripRef = db.collection('trips').doc(id);
    await db.runTransaction((tx) async {
      final data = (await tx.get(rideRef)).data();
      if (data == null || data['driverId'] != uid) {
        throw StateError('الرحلة غير متاحة');
      }
      if (status == 'in_progress' && data['status'] == 'accepted') {
        tx.update(rideRef, {
          'status': status,
          'startedAt': FieldValue.serverTimestamp(),
        });
      } else if (status == 'arrived' && data['status'] == 'in_progress') {
        final started = data['startedAt'] as Timestamp;
        final duration = DateTime.now()
            .difference(started.toDate())
            .inMinutes
            .clamp(0, 1440);
        final driver = Map<String, dynamic>.from(data['driver'] as Map);
        tx.update(rideRef, {
          'status': status,
          'arrivedAt': FieldValue.serverTimestamp(),
          'durationMinutes': duration,
        });
        tx.set(tripRef, {
          'userId': data['userId'],
          'driverId': uid,
          'requestId': id,
          'from': data['from'],
          'to': data['to'],
          'rideType': data['rideType'],
          'price': data['price'],
          'driverName': driver['name'],
          'driverRating': driver['rating'],
          'driverPlate': driver['plateNumber'],
          'date': DateTime.now().millisecondsSinceEpoch,
          'durationMinutes': duration,
          'distanceKm': data['distanceKm'],
          'paymentMethod': 'cash',
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(db.collection('drivers').doc(uid), {
          'isAvailable': true,
          'activeRideId': null,
        });
      } else {
        throw StateError('حالة الرحلة تغيرت. حدّث الصفحة');
      }
    });
  }

  Future<void> shareLocation(String id, LatLng point) =>
      db.collection('ride_requests').doc(id).update({
        'driverLat': point.latitude,
        'driverLng': point.longitude,
        'locationAt': FieldValue.serverTimestamp(),
      });
}
