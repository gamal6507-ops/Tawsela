import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:toktok/domain/models/user.dart';
import 'package:toktok/domain/repositories/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  final auth.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  FirebaseProfileRepository({
    auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _auth = firebaseAuth ?? auth.FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance;
  @override
  Future<User> getProfile() async {
    final current = _auth.currentUser;
    if (current == null) throw StateError('سجل الدخول أولاً');
    final doc = await _db.collection('users').doc(current.uid).get();
    final d = doc.data() ?? {};
    final trips =
        await _db
            .collection('trips')
            .where('userId', isEqualTo: current.uid)
            .get();
    return User(
      id: current.uid,
      name: d['name'] as String? ?? current.displayName ?? '',
      phone: d['phone'] as String? ?? '',
      email: current.email ?? '',
      avatarUrl: d['avatarUrl'] as String?,
      dateOfBirth:
          d['dateOfBirth'] is int
              ? DateTime.fromMillisecondsSinceEpoch(d['dateOfBirth'] as int)
              : null,
      totalTrips: trips.size,
      totalKm: trips.docs.fold<double>(
        0,
        (total, trip) => total + (trip.data()['distanceKm'] as num).toDouble(),
      ),
    );
  }

  @override
  Future<User> updateProfile(User user) async {
    final current = _auth.currentUser;
    if (current == null || current.uid != user.id) {
      throw StateError('سجل الدخول أولاً');
    }
    await _db.runTransaction((tx) async {
      final ref = _db.collection('users').doc(current.uid);
      final existing = await tx.get(ref);
      tx.set(ref, {
        'name': user.name.trim(),
        'phone': user.phone.trim(),
        'email': current.email ?? '',
        'avatarUrl': user.avatarUrl,
        'dateOfBirth': user.dateOfBirth?.millisecondsSinceEpoch,
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    await current.updateDisplayName(user.name.trim());
    return user.copyWith(email: current.email ?? '');
  }
}
