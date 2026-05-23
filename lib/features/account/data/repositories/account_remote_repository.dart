// ignore_for_file: prefer_initializing_formals

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/data/dto/user_dto.dart';
import '../../../auth/data/local/auth_local_data_source.dart';
import '../../../auth/data/session_storage.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRemoteRepository implements AccountRepository {
  AccountRemoteRepository({
    required ApiClient apiClient,
    required AuthLocalDataSource authLocalDataSource,
    required SessionStorage sessionStorage,
  }) : _apiClient = apiClient,
       _authLocalDataSource = authLocalDataSource,
       _sessionStorage = sessionStorage;

  final ApiClient _apiClient;
  final AuthLocalDataSource _authLocalDataSource;
  final SessionStorage _sessionStorage;

  @override
  Future<void> deleteAccount() async {
    await _apiClient.delete('account/profile', authenticated: true);
    await _sessionStorage.clear();
  }

  @override
  Future<User> getProfile() async {
    try {
      final Map<String, dynamic> payload = await _apiClient.get(
        'account/profile',
        authenticated: true,
      );
      final UserDto user = UserDto.fromJson(payload);
      await _authLocalDataSource.upsertUser(user);
      return user.toEntity();
    } on ApiException {
      final UserDto? cached = await _authLocalDataSource.readCurrentUser();
      if (cached != null) {
        return cached.toEntity();
      }
      rethrow;
    }
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    final Map<String, dynamic> payload = await _apiClient.put(
      'account/profile',
      authenticated: true,
      body: <String, dynamic>{'name': name, 'phone': phone, 'address': address},
    );
    final UserDto user = UserDto.fromJson(payload);
    await _authLocalDataSource.upsertUser(user);
    return user.toEntity();
  }
}
