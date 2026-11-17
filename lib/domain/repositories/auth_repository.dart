import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

abstract class AuthRepository {
  /// Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges;

  /// Get the currently signed-in user (null if not signed in)
  firebase_auth.User? get currentUser;

  /// Sign in with email and password
  Future<firebase_auth.UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create a new account with email and password
  Future<firebase_auth.UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  /// Sign in with Google
  Future<firebase_auth.UserCredential> signInWithGoogle();

  /// Send password reset email
  Future<void> resetPassword({required String email});

  /// Send email verification to the current user
  Future<void> sendEmailVerification();

  /// Reload the current user from Firebase
  Future<firebase_auth.User?> reloadUser();

  /// Change password for the current email/password user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Delete the current user account and profile data
  Future<void> deleteAccount();

  /// Sign out
  Future<void> signOut();
}
