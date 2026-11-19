import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:toktok/domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  AuthCubit(this._authRepository) : super(AuthInitial());

  firebase_auth.User? get currentUser => _authRepository.currentUser;

  /// Listen to auth state changes from Firebase
  void checkAuth() {
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    }, onError: (_) => emit(Unauthenticated()));
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepository.signInWithEmail(email: email, password: password);
      // Auth state change listener will emit Authenticated
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code, e.message)));
    } catch (e) {
      emit(AuthError('حصل خطأ غير متوقع. حاول تاني'));
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepository.signUpWithEmail(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      final user = _authRepository.currentUser;
      if (user != null) {
        emit(Authenticated(user));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code, e.message)));
    } catch (e) {
      emit(AuthError('حصل خطأ غير متوقع. حاول تاني'));
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      await _authRepository.signInWithGoogle();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        emit(Unauthenticated());
      } else {
        emit(AuthError('حصل خطأ في تسجيل الدخول بجوجل (${e.code.name})'));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'sign-in-cancelled') {
        emit(Unauthenticated());
      } else {
        emit(AuthError(_mapFirebaseError(e.code, e.message)));
      }
    } catch (e) {
      emit(AuthError('حصل خطأ في تسجيل الدخول بجوجل'));
    }
  }

  /// Send password reset email
  Future<void> resetPassword({required String email}) async {
    emit(AuthLoading());
    try {
      await _authRepository.resetPassword(email: email);
      emit(AuthPasswordResetSent());
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code, e.message)));
    } catch (e) {
      emit(AuthError('حصل خطأ في إرسال رابط إعادة كلمة السر'));
    }
  }

  /// Send email verification to the current user
  Future<void> sendEmailVerification() async {
    emit(AuthLoading());
    try {
      await _authRepository.sendEmailVerification();
      emit(AuthEmailVerificationSent());
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code, e.message)));
    } catch (e) {
      emit(AuthError('حصل خطأ في إرسال رابط تفعيل الإيميل'));
    }
  }

  /// Reload current user from Firebase
  Future<void> reloadUser() async {
    try {
      final user = await _authRepository.reloadUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code, e.message)));
    } catch (e) {
      emit(AuthError('حصل خطأ في تحديث بيانات الحساب'));
    }
  }

  /// Change password for the current user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(AuthPasswordChanged());
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code, e.message)));
    } catch (e) {
      emit(AuthError('حصل خطأ في تغيير كلمة السر'));
    }
  }

  /// Delete the current user account
  Future<void> deleteAccount() async {
    emit(AuthLoading());
    try {
      await _authRepository.deleteAccount();
      emit(Unauthenticated());
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code, e.message)));
    } catch (e) {
      emit(AuthError('حصل خطأ في حذف الحساب'));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('حصل خطأ في تسجيل الخروج'));
    }
  }

  /// Map Firebase error codes to Arabic user-friendly messages
  String _mapFirebaseError(String code, [String? message]) {
    if (message != null && message.contains('CONFIGURATION_NOT_FOUND')) {
      return 'خدمة تسجيل الدخول غير مفعلة في إعدادات Firebase (CONFIGURATION_NOT_FOUND)';
    }
    switch (code) {
      case 'user-not-found':
        return 'مفيش حساب بالإيميل ده';
      case 'wrong-password':
        return 'كلمة السر غلط';
      case 'invalid-credential':
        return 'بيانات تسجيل الدخول مش صحيحة';
      case 'email-already-in-use':
        return 'الإيميل ده مسجل قبل كده';
      case 'weak-password':
        return 'كلمة السر ضعيفة. لازم تكون ٦ حروف على الأقل';
      case 'invalid-email':
        return 'الإيميل مش صحيح';
      case 'user-disabled':
        return 'تم تعطيل الحساب ده';
      case 'operation-not-allowed':
        return 'طريقة تسجيل الدخول دي غير مفعلة في Firebase';
      case 'too-many-requests':
        return 'محاولات كتير. حاول تاني بعد شوية';
      case 'network-request-failed':
        return 'مفيش اتصال بالإنترنت';
      case 'account-exists-with-different-credential':
        return 'الحساب ده مسجل بطريقة تانية';
      case 'requires-recent-login':
        return 'لازم تسجل دخول تاني قبل تنفيذ العملية دي';
      case 'missing-google-id-token':
        return 'تعذر التحقق من Google (أضف SHA-1 وحدّث google-services.json)';
      case 'internal-error':
        return 'خطأ داخلي في Firebase Auth. تأكد من تفعيل Authentication في Firebase Console';
      default:
        return 'حصل خطأ غير متوقع ($code). حاول تاني';
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
