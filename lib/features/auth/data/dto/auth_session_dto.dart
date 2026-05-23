import '../../domain/entities/auth_session.dart';
import 'user_dto.dart';

class AuthSessionDto {
  const AuthSessionDto({required this.token, required this.user});

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> userJson =
        json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return AuthSessionDto(
      token: json['token']! as String,
      user: UserDto.fromJson(userJson),
    );
  }

  factory AuthSessionDto.fromEntity(AuthSession session) {
    return AuthSessionDto(
      token: session.token,
      user: UserDto.fromEntity(session.user),
    );
  }

  final String token;
  final UserDto user;

  AuthSession toEntity() {
    return AuthSession(token: token, user: user.toEntity());
  }
}
