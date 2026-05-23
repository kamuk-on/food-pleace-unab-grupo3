import 'user.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final User user;

  String get email => user.email;

  AuthSession copyWith({String? token, User? user}) {
    return AuthSession(token: token ?? this.token, user: user ?? this.user);
  }
}
