import 'package:sqflite/sqflite.dart';

import '../../../../core/local/app_database.dart';
import '../dto/auth_session_dto.dart';
import '../dto/user_dto.dart';

class AuthLocalDataSource {
  AuthLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<AuthSessionDto?> readCurrentSession() async {
    final database = await _database.database;
    final List<Map<String, Object?>> sessionRows = await database.query(
      AppDatabaseTables.appSession,
      limit: 1,
    );

    if (sessionRows.isEmpty) {
      return null;
    }

    final Map<String, Object?> session = sessionRows.first;
    final String? accessToken = session['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final String userId = session['user_id']! as String;
    final List<Map<String, Object?>> userRows = await database.query(
      AppDatabaseTables.users,
      where: 'id = ?',
      whereArgs: <Object?>[userId],
      limit: 1,
    );

    final UserDto user = userRows.isNotEmpty
        ? _mapUser(userRows.first)
        : UserDto(id: userId, email: session['email']! as String);
    return AuthSessionDto(token: accessToken, user: user);
  }

  Future<UserDto?> readCurrentUser() async {
    final AuthSessionDto? session = await readCurrentSession();
    return session?.user;
  }

  Future<String?> readAccessToken() async {
    final database = await _database.database;
    final List<Map<String, Object?>> sessionRows = await database.query(
      AppDatabaseTables.appSession,
      columns: <String>['access_token'],
      limit: 1,
    );
    if (sessionRows.isEmpty) {
      return null;
    }

    final String? token = sessionRows.first['access_token'] as String?;
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<void> writeCurrentSession(AuthSessionDto session) async {
    final database = await _database.database;
    final String timestamp = DateTime.now().toIso8601String();

    await database.transaction((transaction) async {
      await transaction.insert(AppDatabaseTables.users, <String, Object?>{
        'id': session.user.id,
        'email': session.user.email,
        'name': session.user.name,
        'phone': session.user.phone,
        'address': session.user.address,
        'updated_at': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await transaction.insert(AppDatabaseTables.appSession, <String, Object?>{
        'id': 1,
        'user_id': session.user.id,
        'email': session.user.email,
        'access_token': session.token,
        'updated_at': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> clearCurrentSession() async {
    final database = await _database.database;
    await database.delete(AppDatabaseTables.appSession);
  }

  Future<void> upsertUser(UserDto user) async {
    final database = await _database.database;
    await database.insert(AppDatabaseTables.users, <String, Object?>{
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'phone': user.phone,
      'address': user.address,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  UserDto _mapUser(Map<String, Object?> row) {
    return UserDto(
      id: row['id']! as String,
      email: row['email']! as String,
      name: row['name'] as String?,
      phone: row['phone'] as String?,
      address: row['address'] as String?,
    );
  }
}
