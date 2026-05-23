import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn({required String email, required String password});

  Future<AuthSession?> restoreSession();

  Future<void> signOut();
}
