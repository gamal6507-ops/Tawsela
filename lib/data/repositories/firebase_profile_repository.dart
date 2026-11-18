import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:toktok/domain/models/user.dart';
import 'package:toktok/domain/repositories/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseProfileRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<User> getProfile() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    try {
      final doc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final rawDob = data['dateOfBirth'];
        DateTime? dateOfBirth;
        if (rawDob is Timestamp) {
          dateOfBirth = rawDob.toDate();
        } else if (rawDob is int) {
          dateOfBirth = DateTime.fromMillisecondsSinceEpoch(rawDob);
        }

        return User(
          id: currentUser.uid,
          name: (data['name'] as String?)?.isNotEmpty == true
              ? data['name'] as String
              : (currentUser.displayName ?? ''),
          phone: (data['phone'] as String?) ?? (currentUser.phoneNumber ?? ''),
          email: (data['email'] as String?) ?? (currentUser.email ?? ''),
          avatarUrl: data['avatarUrl'] as String? ?? currentUser.photoURL,
          dateOfBirth: dateOfBirth,
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          totalTrips: (data['totalTrips'] as num?)?.toInt() ?? 0,
          totalKm: (data['totalKm'] as num?)?.toDouble() ?? 0.0,
        );
      }
    } catch (_) {
      // Fall back to FirebaseAuth user info if Firestore is unreachable.
    }

    return User(
      id: currentUser.uid,
      name: currentUser.displayName ?? '',
      phone: currentUser.phoneNumber ?? '',
      email: currentUser.email ?? '',
      avatarUrl: currentUser.photoURL,
    );
  }

  @override
  Future<User> updateProfile(User user) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    if (user.name.isNotEmpty && user.name != currentUser.displayName) {
      await currentUser.updateDisplayName(user.name);
    }

    await _firestore.collection('users').doc(currentUser.uid).set({
      'name': user.name,
      'phone': user.phone,
      'email': user.email,
      'avatarUrl': user.avatarUrl,
      'dateOfBirth': user.dateOfBirth?.millisecondsSinceEpoch,
    }, SetOptions(merge: true));

    return user;
  }
}
