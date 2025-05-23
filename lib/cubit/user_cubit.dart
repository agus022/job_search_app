import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_search_oficial/domain/entities/entities.dart';

abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserSuccess extends UserState {
  final UserEntity? user;
  final List<UserEntity>? users;
  final String? message;
  UserSuccess({this.user, this.users, this.message});
}

class UserError extends UserState {
  final String error;
  UserError(this.error);
}

/// Cubit para gestión de usuarios (login, registro, consultas).
class UserCubit extends Cubit<UserState> {
  final usersCollection = "users";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserCubit() : super(UserInitial());

  /// Client User Login
  Future<void> login(String email, String password) async {
    emit(UserLoading());
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      String uid = cred.user!.uid;

      DocumentSnapshot doc =
          await _firestore.collection(usersCollection).doc(uid).get();
      if (!doc.exists) {
        throw Exception("Perfil de usuario no encontrado.");
      }

      UserEntity user =
          UserEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      emit(UserSuccess(user: user));
    } on FirebaseAuthException catch (e) {
      emit(UserError(e.message ?? "Error de autenticación"));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Client Register User
  Future<void> registerClient(String name, String lastName, String email,
      String password, String phone, String profilePicture, String address,
      {double? lat, double? lon}) async {
    emit(UserLoading());
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      String uid = cred.user!.uid;
      GeoPoint? location =
          (lat != null && lon != null) ? GeoPoint(lat, lon) : null;
      UserEntity newUser = UserEntity(
        id: uid,
        name: name,
        lastName: lastName,
        email: email,
        phone: phone,
        type: UserType.client,
        location: location,
        creationDate: DateTime.now(),
        profilePicture: profilePicture,
        clientProfile: ClientProfile(
          address: address,
          plan: PlanType.free,
        ),
        oficialProfile: null,
      );

      await _firestore
          .collection(usersCollection)
          .doc(uid)
          .set(newUser.toMap());
      emit(UserSuccess(user: newUser));
    } on FirebaseAuthException catch (e) {
      emit(UserError(e.message ?? "Error al registrar cliente"));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Oficial Register User (Cambia los datos del usuario para que tenga info. de un oficial)
  Future<void> registerOfficial({
    required String description,
    required String textualLocation,
    required String certifications,
    required List<String> jobIds,
    required List<String> jobNames,
    required double latitude,
    required double longitude,
  }) async {
    emit(UserLoading());
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No hay usuario autenticado");
      }
      final uid = currentUser.uid;

      final oficialProfileMap = {
        'description': description,
        'location': textualLocation,
        'certifications': certifications,
        'jobIds': jobIds,
        'jobNames': jobNames,
      };

      await _firestore.collection(usersCollection).doc(uid).update({
        'clientProfile': FieldValue.delete(),
        'oficialProfile': oficialProfileMap,
        'jobIds': jobIds,
        'jobNames': jobNames,
        'location': GeoPoint(latitude, longitude),
      });

      final doc = await _firestore.collection(usersCollection).doc(uid).get();
      final updated = UserEntity.fromMap(doc.data()!, doc.id);
      emit(UserSuccess(user: updated));
    } on FirebaseException catch (e) {
      emit(
          UserError(e.message ?? "Error al actualizar user cliente a oficial"));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Get Users Oficial by **categoría de oficio**.
  Future<void> getOfficialsByCategory(String categoryId) async {
    emit(UserLoading());
    try {
      // Get Jobs of categoryId
      QuerySnapshot jobSnap = await _firestore
          .collection('jobs')
          .where('categoryId', isEqualTo: categoryId)
          .get();

      List<String> jobIds = jobSnap.docs.map((doc) => doc.id).toList();
      if (jobIds.isEmpty) {
        emit(UserSuccess(users: []));
        return;
      }
      // 2. Obtener relaciones donde jobId esté en la lista de oficios obtenida
      // Firestore whereIn permite hasta 10 elementos; si hay más, se hacen consultas en lote.
      List<String> jobIdsBatch =
          jobIds.length > 10 ? jobIds.sublist(0, 10) : jobIds;
      QuerySnapshot relSnap = await _firestore
          .collection('official_jobs')
          .where('jobId', whereIn: jobIdsBatch)
          .get();
      // Si hay más de 10 oficios, procesar en lotes adicionales:
      if (jobIds.length > 10) {
        for (int i = 10; i < jobIds.length; i += 10) {
          var subList = jobIds.sublist(
              i, i + 10 > jobIds.length ? jobIds.length : i + 10);
          QuerySnapshot extraRelSnap = await _firestore
              .collection('official_jobs')
              .where('jobId', whereIn: subList)
              .get();
          relSnap.docs.addAll(extraRelSnap.docs);
        }
      }
      // Extraer IDs únicos de oficiales de las relaciones encontradas
      Set<String> officialIds = relSnap.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['officialId'] as String)
          .toSet();
      if (officialIds.isEmpty) {
        emit(UserSuccess(users: []));
        return;
      }
      // 3. Consultar los documentos de usuario correspondientes a esos officialIds
      List<UserEntity> officials = [];
      List<String> idsList = officialIds.toList();
      // Firestore whereIn en FieldPath.documentId para obtener documentos por ID (máx 10 por consulta)
      for (int i = 0; i < idsList.length; i += 10) {
        var batch = idsList.sublist(
            i, i + 10 > idsList.length ? idsList.length : i + 10);
        QuerySnapshot userSnap = await _firestore
            .collection(usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .where('type', isEqualTo: 'official')
            .get();
        for (var doc in userSnap.docs) {
          officials.add(
              UserEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        }
      }
      emit(UserSuccess(users: officials));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Consulta los **5 oficiales más cercanos** a una ubicación dada (lat, lon).
  /// (Para simplificar, filtra dentro de un radio fijo y calcula distancias en el cliente)
  Future<void> getOfficialsByLocation(double latitude, double longitude,
      {double radiusKm = 50.0}) async {
    emit(UserLoading());
    try {
      // Obtener todos los usuarios de tipo "official" (en una app real, usar un enfoque geoespacial más eficiente)
      QuerySnapshot snap = await _firestore
          .collection(usersCollection)
          .where('type', isEqualTo: 'official')
          .get();
      List<UserEntity> allOfficials = snap.docs
          .map((doc) =>
              UserEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      if (allOfficials.isEmpty) {
        emit(UserSuccess(users: []));
        return;
      }
      // Calcular la distancia de cada oficial a la coordenada dada
      List<MapEntry<UserEntity, double>> distances = [];
      for (var off in allOfficials) {
        if (off.location == null) continue;
        double d = _distanceKm(latitude, longitude, off.location!.latitude,
            off.location!.longitude);
        if (d <= radiusKm) {
          distances.add(MapEntry(off, d));
        }
      }
      // Ordenar por distancia ascendente
      distances.sort((a, b) => a.value.compareTo(b.value));
      // Seleccionar los 5 más cercanos
      List<UserEntity> nearest = distances.map((e) => e.key).take(5).toList();
      emit(UserSuccess(users: nearest));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Consulta oficiales filtrando por tipo de plan de suscripción ("free" o "plus").
  Future<void> getOfficialsByPlan(String planType) async {
    emit(UserLoading());
    try {
      QuerySnapshot snap = await _firestore
          .collection(usersCollection)
          .where('type', isEqualTo: 'official')
          .where('plan', isEqualTo: planType)
          .get();
      List<UserEntity> officials = snap.docs
          .map((doc) =>
              UserEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      emit(UserSuccess(users: officials));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  //=== Métodos auxiliares privados ===

  /// Calcula la distancia entre dos coordenadas (lat1, lon1) y (lat2, lon2) en kilómetros.
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0; // Radio de la Tierra en km
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Convierte grados a radianes.
  double _deg2rad(double deg) {
    return deg * pi / 180.0;
  }
}
