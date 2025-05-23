import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_search_oficial/entities/entities.dart';
import 'package:job_search_oficial/helpers/location.dart';

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
    required List<String> jobsIds,
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
        'jobsIds': jobsIds,
        'jobNames': jobNames,
      };

      await _firestore.collection(usersCollection).doc(uid).update({
        'clientProfile': FieldValue.delete(),
        'oficialProfile': oficialProfileMap,
        'jobsIds': jobsIds,
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
  Future<List<UserEntity>> getOfficialsByCategory(String categoryId) async {
    emit(UserLoading());
    try {
      final jobSnap = await _firestore
          .collection('jobs')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      final jobsIds = jobSnap.docs.map((d) => d.id).toList();

      if (jobsIds.isEmpty) {
        emit(UserSuccess(
            users: [], message: 'No hay oficiales en esta categoría'));
        return [];
      }

      // Firestore limita arrayContainsAny a máximo 10 valores por consulta
      final batches = <List<String>>[];
      for (var i = 0; i < jobsIds.length; i += 10) {
        batches.add(jobsIds.sublist(
            i, i + 10 > jobsIds.length ? jobsIds.length : i + 10));
      }

      final List<UserEntity> result = [];
      for (final batch in batches) {
        final userSnap = await _firestore
            .collection('users')
            .where('type', isEqualTo: UserType.oficial.name)
            .where('oficialProfile.jobsIds', arrayContainsAny: batch)
            .get();
        for (final doc in userSnap.docs) {
          result.add(UserEntity.fromMap(doc.data(), doc.id));
        }
      }

      emit(UserSuccess(users: result));
      return result;
    } on FirebaseException catch (e) {
      emit(UserError(e.message ?? 'Error al cargar oficiales'));
      return [];
    } catch (e) {
      emit(UserError(e.toString()));
      return [];
    }
  }

  /// Consulta los **5 oficiales más cercanos** a una ubicación dada (lat, lon).
  Future<void> getOfficialsByLocation(double latitude, double longitude,
      {double radiusKm = 50.0}) async {
    emit(UserLoading());
    try {
      // Obtener todos los usuarios de tipo "official" (en una app real, usar un enfoque geoespacial más eficiente)
      QuerySnapshot snap = await _firestore
          .collection(usersCollection)
          .where('type', isEqualTo: UserType.oficial.name)
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

        double d = LocationHelpers().distanceKm(latitude, longitude,
            off.location!.latitude, off.location!.longitude);
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
}
