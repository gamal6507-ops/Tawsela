import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:toktok/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  bool _isGoogleSignInInitialized = false;

  FirebaseAuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      const clientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
      await _googleSignIn.initialize(
        serverClientId: clientId.isEmpty ? null : clientId,
      );
      _isGoogleSignInInitialized = true;
    }
  }

  Future<void> _saveUserProfileIfNeeded({
    required firebase_auth.User user,
    String? name,
    String? phone,
  }) async {
    try {
      await _firestore.runTransaction((tx) async {
        final ref = _firestore.collection('users').doc(user.uid);
        final profile = await tx.get(ref);
        if (!profile.exists) {
          tx.set(ref, {
            'name': name ?? user.displayName ?? '',
            'email': user.email ?? '',
            'phone': phone ?? user.phoneNumber ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (_) {
      // Do not fail authentication if Firestore profile write is unavailable.
    }
  }

  @override
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  @override
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<firebase_auth.UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<firebase_auth.UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name
    try {
      await credential.user
          ?.updateDisplayName(name)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Do not fail registration if display name update times out.
    }

    // Save user profile to Firestore
    if (credential.user != null) {
      await _saveUserProfileIfNeeded(
        user: credential.user!,
        name: name,
        phone: phone,
      );
    }

    return credential;
  }

  @override
  Future<firebase_auth.UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final result = await _firebaseAuth.signInWithPopup(
        firebase_auth.GoogleAuthProvider(),
      );
      if (result.user != null) {
        await _saveUserProfileIfNeeded(user: result.user!);
      }
      return result;
    }
    await _ensureGoogleSignInInitialized();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'missing-google-id-token',
        message:
            'لم يتم استلام رمز التحقق من Google (تأكد من SHA-1 و google-services.json)',
      );
    }

    final credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);

    // Save/update user profile in Firestore for new users
    if (userCredential.additionalUserInfo?.isNewUser == true &&
        userCredential.user != null) {
      await _saveUserProfileIfNeeded(user: userCredential.user!);
    }

    return userCredential;
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'المستخدم غير مسجل الدخول',
      );
    }
    await user.sendEmailVerification();
  }

  @override
  Future<firebase_auth.User?> reloadUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _firebaseAuth.currentUser;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'المستخدم غير مسجل الدخول',
      );
    }

    final credential = firebase_auth.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'المستخدم غير مسجل الدخول',
      );
    }

    final active = await _firestore
        .collection('active_rides')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));
    final driverRef = _firestore.collection('drivers').doc(user.uid);
    final driver = await driverRef.get(const GetOptions(source: Source.server));
    if (active.exists || driver.data()?['activeRideId'] != null) {
      throw StateError('أكمل أو الغِ الرحلة النشطة أولاً');
    }
    final markers =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notification_states')
            .get();
    for (var start = 0; start < markers.docs.length; start += 400) {
      final batch = _firestore.batch();
      for (final marker in markers.docs.skip(start).take(400)) {
        batch.delete(marker.reference);
      }
      await batch.commit();
    }
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('users').doc(user.uid));
    if (driver.exists) batch.delete(driverRef);
    await batch.commit();
    await user.delete();
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      if (kIsWeb) return;
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
