import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toktok/domain/repositories/auth_repository.dart';
import 'package:toktok/presentation/blocs/auth/auth_cubit.dart';
import 'package:toktok/presentation/blocs/auth/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements firebase_auth.User {}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
    when(() => mockUser.uid).thenReturn('uid-123');
    when(
      () => mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => const Stream<firebase_auth.User?>.empty());
  });

  group('AuthCubit', () {
    test('initial state is AuthInitial', () {
      final cubit = AuthCubit(mockAuthRepository);
      expect(cubit.state, isA<AuthInitial>());
      cubit.close();
    });

    blocTest<AuthCubit, AuthState>(
      'emits [Authenticated] when authStateChanges emits a user',
      build: () {
        when(
          () => mockAuthRepository.authStateChanges,
        ).thenAnswer((_) => Stream.value(mockUser));
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.checkAuth(),
      expect: () => [Authenticated(mockUser)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Unauthenticated] when authStateChanges emits null',
      build: () {
        when(
          () => mockAuthRepository.authStateChanges,
        ).thenAnswer((_) => Stream.value(null));
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.checkAuth(),
      expect: () => [Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when signInWithEmail throws FirebaseAuthException',
      build: () {
        when(
          () => mockAuthRepository.signInWithEmail(
            email: 'test@example.com',
            password: 'wrong',
          ),
        ).thenThrow(
          firebase_auth.FirebaseAuthException(code: 'wrong-password'),
        );
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.signInWithEmail(
        email: 'test@example.com',
        password: 'wrong',
      ),
      expect: () => [
        AuthLoading(),
        const AuthError('كلمة السر غلط'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] with CONFIGURATION_NOT_FOUND message',
      build: () {
        when(
          () => mockAuthRepository.signUpWithEmail(
            name: 'Seif',
            email: 'seif@gmail.com',
            phone: '01012345678',
            password: 'password123',
          ),
        ).thenThrow(
          firebase_auth.FirebaseAuthException(
            code: 'internal-error',
            message: 'An internal error has occurred. [ CONFIGURATION_NOT_FOUND ]',
          ),
        );
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.signUpWithEmail(
        name: 'Seif',
        email: 'seif@gmail.com',
        phone: '01012345678',
        password: 'password123',
      ),
      expect: () => [
        AuthLoading(),
        const AuthError(
          'خدمة تسجيل الدخول غير مفعلة في إعدادات Firebase (CONFIGURATION_NOT_FOUND)',
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthPasswordResetSent] when resetPassword succeeds',
      build: () {
        when(
          () => mockAuthRepository.resetPassword(email: 'test@example.com'),
        ).thenAnswer((_) async {});
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.resetPassword(email: 'test@example.com'),
      expect: () => [AuthLoading(), AuthPasswordResetSent()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthEmailVerificationSent] when sendEmailVerification succeeds',
      build: () {
        when(
          () => mockAuthRepository.sendEmailVerification(),
        ).thenAnswer((_) async {});
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.sendEmailVerification(),
      expect: () => [AuthLoading(), AuthEmailVerificationSent()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthPasswordChanged] when changePassword succeeds',
      build: () {
        when(
          () => mockAuthRepository.changePassword(
            currentPassword: 'oldPassword',
            newPassword: 'newPassword123',
          ),
        ).thenAnswer((_) async {});
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.changePassword(
        currentPassword: 'oldPassword',
        newPassword: 'newPassword123',
      ),
      expect: () => [AuthLoading(), AuthPasswordChanged()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, Unauthenticated] when deleteAccount succeeds',
      build: () {
        when(() => mockAuthRepository.deleteAccount()).thenAnswer((_) async {});
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.deleteAccount(),
      expect: () => [AuthLoading(), Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Unauthenticated] when signOut succeeds',
      build: () {
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.signOut(),
      expect: () => [Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading] and calls signInWithGoogle',
      build: () {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => mockUserCredential);
        return AuthCubit(mockAuthRepository);
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [AuthLoading()],
      verify: (_) {
        verify(() => mockAuthRepository.signInWithGoogle()).called(1);
      },
    );
  });
}
