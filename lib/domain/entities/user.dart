enum UserType { client, oficial }

class User {
  final String? id;
  final String name;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String profilePicture;
  final UserType type;
  final DateTime creationDate;
  final ClientProfile? clientProfile;
  final OficialProfile? oficialProfile;

  User({
    this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.profilePicture,
    required this.type,
    required this.creationDate,
    this.clientProfile,
    this.oficialProfile,
  });
}

class ClientProfile {
  final String address;

  ClientProfile({required this.address});
}

class OficialProfile {
  final String description;
  final String location;
  final String certifications;

  OficialProfile({
    required this.description,
    required this.location,
    required this.certifications,
  });
}
