import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_search_oficial/entities/entities.dart';
import 'package:job_search_oficial/helpers/location.dart';

enum UserStatus { logged, uncofirmmed, unlogged, unregisterd }

class UserState extends Equatable {
  final bool loading;
  final UserEntity? user;
  final List<UserEntity>? users;
  final String? message;
  final String? error;
  final UserStatus status;

  const UserState({
    this.loading = false,
    this.user,
    this.users,
    this.message,
    this.error,
    this.status = UserStatus.unregisterd,
  });

  UserState copyWith({
    bool? loading,
    UserEntity? user,
    List<UserEntity>? users,
    String? message,
    String? error,
    UserStatus? status,
  }) {
    return UserState(
        loading: loading ?? this.loading,
        user: user ?? this.user,
        users: users ?? this.users,
        message: message,
        error: error,
        status: status ?? this.status);
  }

  @override
  List<Object?> get props => [loading, user, users, message, error, status];
}

class UserCubit extends Cubit<UserState> {
  final String usersCollection = "users";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserCubit() : super(const UserState());

  /// Client User Login
  Future<void> login(String email, String password) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = cred.user!.uid;

      DocumentSnapshot doc =
          await _firestore.collection(usersCollection).doc(uid).get();
      if (!doc.exists) throw Exception("Perfil de usuario no encontrado.");

      final user =
          UserEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      emit(state.copyWith(
        loading: false,
        status: UserStatus.logged,
        user: user,
        message: "Login exitoso",
      ));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        loading: false,
        status: UserStatus.uncofirmmed,
        error: e.message ?? "Error de autenticación",
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString(),
      ));
    }
  }

  /// Client Register User
  Future<void> registerClient({
    required String name,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String profilePicture,
    required String address,
    double? lat,
    double? lon,
  }) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = cred.user!.uid;
      final location = (lat != null && lon != null) ? GeoPoint(lat, lon) : null;

      final newUser = UserEntity(
        id: uid,
        name: name,
        lastName: lastName,
        email: email,
        phone: phone,
        type: UserType.client,
        creationDate: DateTime.now(),
        profilePicture: profilePicture,
        location: location,
        clientProfile: ClientProfile(
          address: address,
          plan: PlanType.free,
        ),
        oficialProfile: null,
      );

      // TODO: Mandar correo de confoirmación antes de registrar
      await _firestore
          .collection(usersCollection)
          .doc(uid)
          .set(newUser.toMap());

      emit(state.copyWith(
        loading: false,
        status: UserStatus.uncofirmmed,
        user: newUser,
        message: "Cliente registrado",
      ));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? "Error al registrar cliente",
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString(),
      ));
    }
  }

  /// Update existing user to Oficial
  Future<void> registerOfficial({
    required String description,
    required String textualLocation,
    required String certifications,
    required List<String> jobsIds,
    required List<String> jobNames,
    required double latitude,
    required double longitude,
  }) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("No hay usuario autenticado");
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
        'location': GeoPoint(latitude, longitude),
      });

      final doc = await _firestore.collection(usersCollection).doc(uid).get();
      final updated = UserEntity.fromMap(doc.data()!, doc.id);

      emit(state.copyWith(
        loading: false,
        user: updated,
        message: "Usuario convertido a oficial",
      ));
    } on FirebaseException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? "Error al actualizar a oficial",
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString(),
      ));
    }
  }

  /// Get Officials by Category
  Future<List<UserEntity>> getOfficialsByCategory(String categoryId) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      final jobSnap = await _firestore
          .collection('jobs')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      final jobIds = jobSnap.docs.map((d) => d.id).toList();

      if (jobIds.isEmpty) {
        emit(state.copyWith(
          loading: false,
          users: [],
          message: 'No hay oficiales en esta categoría',
        ));
        return [];
      }

      final batches = <List<String>>[];
      for (var i = 0; i < jobIds.length; i += 10) {
        batches.add(
            jobIds.sublist(i, i + 10 > jobIds.length ? jobIds.length : i + 10));
      }

      final List<UserEntity> result = [];
      for (final batch in batches) {
        final snap = await _firestore
            .collection(usersCollection)
            .where('type', isEqualTo: UserType.official.name)
            .where('oficialProfile.jobsIds', arrayContainsAny: batch)
            .get();
        result.addAll(
            snap.docs.map((d) => UserEntity.fromMap(d.data(), d.id)).toList());
      }

      emit(state.copyWith(
        loading: false,
        users: result,
        message: 'Oficiales cargados',
      ));
      return result;
    } on FirebaseException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? 'Error al cargar oficiales',
      ));
      return [];
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString(),
      ));
      return [];
    }
  }

  Future<void> getOfficialsByLocation(double latitude, double longitude,
      {double radiusKm = 50.0}) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      final snap = await _firestore
          .collection(usersCollection)
          .where('type', isEqualTo: UserType.official.name)
          .get();
      final all =
          snap.docs.map((d) => UserEntity.fromMap(d.data(), d.id)).toList();

      List<MapEntry<UserEntity, double>> distances = all
          .where((u) => u.location != null)
          .map((u) {
            final d = LocationHelpers().distanceKm(
              latitude,
              longitude,
              u.location!.latitude,
              u.location!.longitude,
            );
            return MapEntry(u, d);
          })
          .where((e) => e.value <= radiusKm)
          .toList();

      distances.sort((a, b) => a.value.compareTo(b.value));
      final nearest = distances.map((e) => e.key).take(5).toList();

      emit(state.copyWith(
        loading: false,
        users: nearest,
        message: 'Oficiales más cercanos',
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString(),
      ));
    }
  }

  // Post a calification of a Official
  Future<void> qualifyOfficialUser() async {}

  // Suscribe to a plan (Client)
  Future<void> suscribePlan(PlanType plan) async {}
}
