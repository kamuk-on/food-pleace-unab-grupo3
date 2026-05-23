import '../../../shared/domain/parsing.dart';
import '../../domain/entities/user.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.address,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: JsonParser.requireString(json, 'id'),
      email: JsonParser.requireString(json, 'email'),
      name: JsonParser.optionalString(json, 'name'),
      phone: JsonParser.optionalString(json, 'phone'),
      address: JsonParser.optionalString(json, 'address'),
    );
  }

  factory UserDto.fromEntity(User user) {
    return UserDto(
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      address: user.address,
    );
  }

  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? address;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      phone: phone,
      address: address,
    );
  }
}
