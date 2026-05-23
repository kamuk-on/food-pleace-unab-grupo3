// ignore_for_file: prefer_initializing_formals

import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../dto/auth_session_dto.dart';
import '../session_storage.dart';

class AuthRemoteRepository implements AuthRepository {
  AuthRemoteRepository({
    required ApiClient apiClient,
    required SessionStorage storage,
  }) : _apiClient = apiClient,
       _storage = storage;

  final ApiClient _apiClient;
  final SessionStorage _storage;

  @override
  Future<AuthSession?> restoreSession() {
    return _storage.readSession();
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> payload = await _apiClient.post(
      'auth/login',
      body: <String, dynamic>{'email': email.trim(), 'password': password},
    );
    final AuthSession session = AuthSessionDto.fromJson(payload).toEntity();
    await _storage.writeSession(session);
    return session;
  }

  @override
  Future<void> signOut() {
    return _storage.clear();
  }
}
