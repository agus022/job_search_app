// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:job_search_oficial/domain/entities/entities.dart';

// class UserMapper {
//   static User fromJson(String id, Map<String, dynamic> json) {
//     return User(
//       id: id,
//       name: json['nombre'],
//       lastName: json['apellido'],
//       email: json['email'],
//       phone: json['telefono'],
//       password: json['password_hash'],
//       profilePicture: json['foto_perfil'],
//       type: json['tipo'],
//       creationDate: (json['fecha_creacion'] as Timestamp).toDate(),
//       clientProfile: json['perfil_cliente'] != null
//           ? ClientProfile(
//               address: json['perfil_cliente']['direccion'],
//             )
//           : null,
//       oficialProfile: json['perfil_oficial'] != null
//           ? OficialProfile(
//               description: json['perfil_oficial']['descripcion'],
//               location: json['perfil_oficial']['ubicacion'],
//               certifications: json['perfil_oficial']['certificaciones'],
//             )
//           : null,
//     );
//   }

//   static Map<String, dynamic> toJson(User user) {
//     final data = {
//       'nombre': user.name,
//       'apellido': user.lastName,
//       'email': user.email,
//       'telefono': user.phone,
//       'password_hash': user.password,
//       'tipo': user.type,
//       'fecha_creacion': Timestamp.fromDate(user.creationDate),
//     };

//     if (user.clientProfile != null) {
//       data['perfil_cliente'] = {
//         'direccion': user.clientProfile!.address,
//       };
//     }

//     if (user.oficialProfile != null) {
//       data['perfil_oficial'] = {
//         'descripcion': user.oficialProfile!.description,
//         'ubicacion': user.oficialProfile!.location,
//         'certificaciones': user.oficialProfile!.certifications,
//       };
//     }

//     return data;
//   }
// }
