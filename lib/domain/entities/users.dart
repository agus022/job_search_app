enum UserType { client, oficial }

class User {
  final String? id;
  final String name;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final UserType type;
  final DateTime creationDate;

  User({
    this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.type,
    required this.creationDate,
  });
}
