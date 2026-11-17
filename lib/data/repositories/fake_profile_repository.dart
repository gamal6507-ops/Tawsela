import 'package:toktok/domain/models/user.dart';
import 'package:toktok/domain/repositories/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  User _user = const User(
    id: 'u1',
    name: 'محمد أحمد',
    phone: '01098765432',
    email: 'mohamed@tawsela.com',
    rating: 4.7,
    totalTrips: 156,
    totalKm: 430.5,
  );

  @override
  Future<User> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _user;
  }

  @override
  Future<User> updateProfile(User user) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _user = user;
    return _user;
  }
}
