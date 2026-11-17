import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
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
      await _googleSignIn.initialize(
        serverClientId:
            '788170634537-mnsaclmiseuab4p764ldcunbfsiuj76a.apps.googleusercontent.com',
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
      await _firestore.collection('users').doc(user.uid).set({
        'name': name ?? user.displayName ?? '',
        'email': user.email ?? '',
        'phone': phone ?? user.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
        'totalTrips': 0,
        'totalKm': 0.0,
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 2));
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
    await _ensureGoogleSignInInitialized();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'لم يتم استلام رمز التحقق من Google (تأكد من SHA-1 و google-services.json)',
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

    try {
      await _firestore.collection('users').doc(user.uid).delete();
    } catch (_) {
      // Proceed with account deletion even if Firestore doc does not exist.
    }
    await user.delete();
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
