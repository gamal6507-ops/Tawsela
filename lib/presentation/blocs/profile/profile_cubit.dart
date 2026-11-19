import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktok/domain/models/user.dart';
import 'package:toktok/domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit(this._profileRepository) : super(ProfileInitial());

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    try {
      final user = await _profileRepository.getProfile();
      if (isClosed) return;
      emit(ProfileLoaded(user));
    } catch (e) {
      if (isClosed) return;
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile(User user) async {
    final current =
        state is ProfileLoaded ? (state as ProfileLoaded).user : null;
    if (current != null) emit(ProfileSaving(current));
    try {
      final updated = await _profileRepository.updateProfile(user);
      if (isClosed) return;
      emit(ProfileSaved(updated));
    } catch (e) {
      if (isClosed) return;
      emit(ProfileError(e.toString()));
    }
  }
}
