import 'package:equatable/equatable.dart';
import 'package:toktok/domain/models/user.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;
  const ProfileLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileSaving extends ProfileState {
  final User user;
  const ProfileSaving(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileSaved extends ProfileState {
  final User user;
  const ProfileSaved(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}
