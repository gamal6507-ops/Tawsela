import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Initial state before auth check
class AuthInitial extends AuthState {}

/// Auth check/operation in progress
class AuthLoading extends AuthState {}

/// User is authenticated
class Authenticated extends AuthState {
  final firebase_auth.User user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user.uid];
}

/// User is not authenticated
class Unauthenticated extends AuthState {}

/// Auth error occurred
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Password reset email sent
class AuthPasswordResetSent extends AuthState {}

/// Email verification sent
class AuthEmailVerificationSent extends AuthState {}

/// Password changed successfully
class AuthPasswordChanged extends AuthState {}
