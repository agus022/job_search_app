import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_search_oficial/entities/entities.dart';

class ServiceState extends Equatable {
  final bool loading;
  final UserEntity? user;
  final List<UserEntity>? users;
  final String? message;
  final String? error;

  const ServiceState({
    this.loading = false,
    this.user,
    this.users,
    this.message,
    this.error,
  });

  ServiceState copyWith({
    bool? loading,
    UserEntity? user,
    List<UserEntity>? users,
    String? message,
    String? error,
  }) {
    return ServiceState(
      loading: loading ?? this.loading,
      user: user ?? this.user,
      users: users ?? this.users,
      message: message,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, user, users, message, error];
}

class ServiceCubit extends Cubit<ServiceState> {
  final String servicesCollection = "services";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ServiceCubit() : super(const ServiceState());

  /// Get services
  Future<void> login(String email, String password) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = cred.user!.uid;

      DocumentSnapshot doc =
          await _firestore.collection(servicesCollection).doc(uid).get();
      if (!doc.exists) throw Exception("Perfil de usuario no encontrado.");

      final user =
          UserEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      emit(state.copyWith(
        loading: false,
        user: user,
        message: "Login exitoso",
      ));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? "Error de autenticación",
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString(),
      ));
    }
  }

  /// Crear/Acordar Servicio
  Future<void> registerService({
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

      await _firestore
          .collection(servicesCollection)
          .doc(uid)
          .set(newUser.toMap());

      emit(state.copyWith(
        loading: false,
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

  // Accept a Service
  Future<void> acceptService(String serviceId) async {}

  // Decline a Service
  Future<void> declineService(String serviceId) async {}

  // Get my Services (Client/Oficcial)
  Future<List<Service>> getMyServices(userId) async {
    return [];
  }

  // Get my Services by status (Client/Official)
  Future<List<Service>> getMyServicesByStatus(userId, status) async {
    return [];
  }
}
