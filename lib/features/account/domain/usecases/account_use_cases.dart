import '../../../auth/domain/entities/user.dart';
import '../repositories/account_repository.dart';

class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final AccountRepository _repository;

  Future<User> call() {
    return _repository.getProfile();
  }
}

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final AccountRepository _repository;

  Future<User> call({String? name, String? phone, String? address}) {
    return _repository.updateProfile(
      name: name,
      phone: phone,
      address: address,
    );
  }
}

class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<void> call() {
    return _repository.deleteAccount();
  }
}
