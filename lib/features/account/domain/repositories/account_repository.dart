import '../../../auth/domain/entities/user.dart';

abstract interface class AccountRepository {
  Future<User> getProfile();

  Future<User> updateProfile({String? name, String? phone, String? address});

  Future<void> deleteAccount();
}
