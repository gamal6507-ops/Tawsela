import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:toktok/domain/models/trip.dart';
import 'package:toktok/domain/repositories/trip_history_repository.dart';

class FirestoreTripHistoryRepository implements TripHistoryRepository {
  final FirebaseFirestore _db;
  final auth.FirebaseAuth _auth;
  FirestoreTripHistoryRepository({
    FirebaseFirestore? firestore,
    auth.FirebaseAuth? firebaseAuth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = firebaseAuth ?? auth.FirebaseAuth.instance;
  @override
  Future<List<Trip>> getTripHistory() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final snapshot = await _db
        .collection('trips')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(100)
        .get(const GetOptions(source: Source.server));
    if (_auth.currentUser?.uid != uid) return [];
    return snapshot.docs
        .map((doc) => Trip.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<double> getTotalSpent() async =>
      (await getTripHistory()).fold<double>(0, (total, t) => total + t.price);
}
