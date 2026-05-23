import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/local/app_database.dart';
import '../domain/entities/auth_session.dart';
import 'dto/auth_session_dto.dart';
import 'local/auth_local_data_source.dart';

/// Persistencia local de la sesion del usuario.
class SessionStorage {
  SessionStorage({AuthLocalDataSource? localDataSource})
    : _localDataSource =
          localDataSource ??
          AuthLocalDataSource(database: AppDatabase.instance);

  static const String _emailKey = 'auth.session.email';

  final AuthLocalDataSource _localDataSource;

  Future<AuthSession?> readSession() async {
    final AuthSessionDto? session = await _localDataSource.readCurrentSession();
    if (session != null) {
      return session.toEntity();
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? legacyEmail = prefs.getString(_emailKey);
    if (legacyEmail == null || legacyEmail.isEmpty) {
      return null;
    }

    await clear();
    await prefs.remove(_emailKey);
    return null;
  }

  Future<String?> readAccessToken() {
    return _localDataSource.readAccessToken();
  }

  Future<void> writeSession(AuthSession session) async {
    await _localDataSource.writeCurrentSession(
      AuthSessionDto.fromEntity(session),
    );
  }

  Future<void> clear() async {
    await _localDataSource.clearCurrentSession();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
  }
}
