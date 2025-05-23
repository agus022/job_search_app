import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { client, oficial }

enum PlanType { free, plus }

class UserEntity {
  final String? id;
  final String name;
  final String lastName;
  final String email;
  final String phone;
  final UserType type;
  final DateTime creationDate;
  final String profilePicture;
  GeoPoint? location;
  final ClientProfile? clientProfile;
  final OficialProfile? oficialProfile;

  UserEntity({
    this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.type,
    required this.creationDate,
    required this.profilePicture,
    this.location,
    this.clientProfile,
    this.oficialProfile,
  });

  factory UserEntity.fromMap(Map<String, dynamic> map, String? docId) {
    return UserEntity(
      id: docId ?? map['id'] as String?,
      name: map['name'] as String,
      lastName: map['lastName'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      type: UserType.values.firstWhere(
        (e) => e.name == map['type'] as String,
        orElse: () => UserType.client,
      ),
      creationDate: (map['creationDate'] as Timestamp).toDate(),
      profilePicture: map['profilePicture'] as String,
      location: map['location'] as GeoPoint?,
      clientProfile: map['clientProfile'] != null
          ? ClientProfile.fromMap(map['clientProfile'] as Map<String, dynamic>)
          : null,
      oficialProfile: map['oficialProfile'] != null
          ? OficialProfile.fromMap(
              map['oficialProfile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'type': type.name,
      'creationDate': Timestamp.fromDate(creationDate),
      'profilePicture': profilePicture,
      if (location != null) 'location': location,
      if (clientProfile != null) 'clientProfile': clientProfile!.toMap(),
      if (oficialProfile != null) 'oficialProfile': oficialProfile!.toMap(),
    };
    return map;
  }
}

class ClientProfile {
  final String address;
  final PlanType plan;

  ClientProfile({
    required this.address,
    required this.plan,
  });

  factory ClientProfile.fromMap(Map<String, dynamic> map) {
    return ClientProfile(
      address: map['address'] as String,
      plan: PlanType.values.firstWhere(
        (e) => e.name == (map['plan'] as String? ?? PlanType.free.name),
        orElse: () => PlanType.free,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'plan': plan.name,
    };
  }
}

class OficialProfile {
  final String description;
  final String location;
  final String certifications;
  final List<String> jobsIds;
  final List<String> jobNames;

  OficialProfile({
    required this.description,
    required this.location,
    required this.certifications,
    required this.jobsIds,
    required this.jobNames,
  });

  factory OficialProfile.fromMap(Map<String, dynamic> map) {
    return OficialProfile(
      description: map['description'] as String,
      location: map['location'] as String,
      certifications: map['certifications'] as String,
      jobsIds: map['jobsIds'] != null
          ? List<String>.from(map['jobsIds'] as List<dynamic>)
          : <String>[],
      jobNames: map['jobNames'] != null
          ? List<String>.from(map['jobNames'] as List<dynamic>)
          : <String>[],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'location': location,
      'certifications': certifications,
      'jobsIds': jobsIds,
      'jobNames': jobNames,
    };
  }
}
