import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_search_oficial/entities/entities.dart';

enum UserType { client, official }

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
      id: docId ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Sin nombre',
      lastName: map['lastName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      type: UserType.values.firstWhere(
        (e) => e.name == map['type']?.toString(),
        orElse: () => UserType.client,
      ),
      creationDate:
          (map['creationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profilePicture: map['profilePicture']?.toString() ?? '',
      location: _parseGeoPoint(map['location']),
      clientProfile: map['clientProfile'] != null
          ? ClientProfile.fromMap(map['clientProfile'] as Map<String, dynamic>)
          : null,
      oficialProfile: map['oficialProfile'] != null
          ? OficialProfile.fromMap(
              map['oficialProfile'] as Map<String, dynamic>)
          : null,
    );
  }

// Función auxiliar para manejar distintos formatos de ubicación
  static GeoPoint _parseGeoPoint(dynamic value) {
    if (value is GeoPoint) {
      return value;
    } else if (value is Map<String, dynamic>) {
      return GeoPoint(
        (value['latitude'] ?? 0.0) as double,
        (value['longitude'] ?? 0.0) as double,
      );
    } else {
      return const GeoPoint(0.0, 0.0);
    }
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
      address: map['address']?.toString() ?? '',
      plan: PlanType.values.firstWhere(
        (e) => e.name == (map['plan']?.toString() ?? PlanType.free.name),
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
  final List<DocumentReference> jobIds;
  final List<String> jobNames;
  final List<Calification>? califications;
  final List<String> categoryIds;
  final List<String> categoryNames;

  OficialProfile({
    required this.description,
    required this.location,
    required this.certifications,
    required this.jobIds,
    required this.jobNames,
    this.califications,
    this.categoryIds = const [],
    this.categoryNames = const [],
  });

  factory OficialProfile.fromMap(Map<String, dynamic> map) {
    List<Calification>? parsedCalifications;
    if (map['califications'] != null) {
      parsedCalifications = (map['califications'] as List<dynamic>)
          .map((e) => Calification.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return OficialProfile(
      description: map['description']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      certifications: map['certifications']?.toString() ?? '',
      jobIds: List<DocumentReference>.from(map['jobIds'] ?? []),
      jobNames: (map['jobNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      califications: parsedCalifications,
      categoryIds: List<String>.from(map['categoryIds'] ?? []),
      categoryNames: List<String>.from(map['categoryNames'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'location': location,
      'certifications': certifications,
      'jobsIds': jobIds,
      'jobNames': jobNames,
      // Si califications es null, omitimos el campo; si no, convertimos cada Calification a Map
      if (califications != null)
        'califications': califications!.map((c) => c.toMap()).toList(),
      'categoryIds': categoryIds,
      'categoryNames': categoryNames,
    };
  }
}
