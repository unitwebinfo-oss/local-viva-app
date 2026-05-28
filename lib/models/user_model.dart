class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final bool emailVerified;
  final String? cpf;
  final String? cep;
  final String? street;
  final String? city;
  final String? stateUf;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.emailVerified,
    this.cpf,
    this.cep,
    this.street,
    this.city,
    this.stateUf,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      emailVerified: json['email_verified'] ?? false,
      cpf: json['cpf'],
      cep: json['cep'],
      street: json['street'],
      city: json['city'],
      stateUf: json['state_uf'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'email_verified': emailVerified,
      'cpf': cpf,
      'cep': cep,
      'street': street,
      'city': city,
      'state_uf': stateUf,
    };
  }
}
