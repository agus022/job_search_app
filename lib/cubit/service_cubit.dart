import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_search_oficial/entities/entities.dart';

class ServiceState extends Equatable {
  final bool loading;
  final List<Service>? services;
  final String? message;
  final String? error;

  const ServiceState({
    this.loading = false,
    this.services,
    this.message,
    this.error,
  });

  ServiceState copyWith({
    bool? loading,
    List<Service>? services,
    String? message,
    String? error,
  }) {
    return ServiceState(
      loading: loading ?? this.loading,
      services: services ?? this.services,
      message: message,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, services, message, error];
}

class ServiceCubit extends Cubit<ServiceState> {
  final String servicesCollection = "services";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ServiceCubit() : super(const ServiceState());

  /// Solicitar un Servicio (Client y Oficial)
  Future<void> requestService(
      {required description, required oficialRef, required address}) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      final newService = Service(
        clientRef: _auth.currentUser!.uid,
        oficialRef: oficialRef,
        date: DateTime.now(),
        address: address,
        description: description,
        state: ServiceStatus.pendent,
        // Atributos adicionales para el posterior
        price: 0.0,
        paymentMethods: [],
      );

      await _firestore.collection(servicesCollection).add(newService.toMap());
      // TODO: Mandar un pushNotification al oficial

      emit(state.copyWith(
        loading: false,
        message: "Servicio solicitado, esperando respuesta del oficial...",
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
  Future<void> acceptService(
      String serviceId, List<String> paymentMethods) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      await _firestore.collection(servicesCollection).doc(serviceId).update({
        'status': ServiceStatus.accepted.name,
        'paymentMethods': paymentMethods
      });

      // TODO: Mandar un pushNotification al cliente
      emit(state.copyWith(
          loading: false,
          error: null,
          message: 'Servicio aceptado por el oficial'));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString(),
      ));
    }
  }

  // Decline a Service
  Future<void> declineService(
    String serviceId,
  ) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      await _firestore.collection(servicesCollection).doc(serviceId).update({
        'status': ServiceStatus.cancelled.name,
      });

      // TODO: Mandar un pushNotification al cliente
      emit(state.copyWith(
          loading: false,
          error: null,
          message: 'Servicio declinado por el oficial'));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString(),
      ));
    }
  }

  // Get my Services (Client/Oficcial)
  Future<List<Service>> getMyServices(userId, UserType userType) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      String refName = userType == UserType.client ? 'clientRef' : 'oficialRef';

      final snap = await _firestore
          .collection(servicesCollection)
          .where({refName}, isEqualTo: userId).get();

      final services = snap.docs.map((data) {
        final rawData = data.data();
        return Service.fromMap(rawData);
      }).toList();

      return services;
    } catch (e) {
      emit(state.copyWith(
          loading: false,
          error: e.toString(),
          message: 'No se pudieron obtener los servicios.'));
      return [];
    }
  }
}
