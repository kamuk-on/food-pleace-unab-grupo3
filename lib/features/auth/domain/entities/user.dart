/// Usuario autenticado de la aplicacion.
class User {
  const User({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.address,
  });

  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? address;

  User copyWith({String? name, String? phone, String? address}) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}
