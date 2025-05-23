import 'dart:math';
import 'package:bloc/bloc.dart';            // Cubit is provided by the bloc package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Modelo de usuario con campos correspondientes al documento en Firestore.
class User {
  String id;
  String name;
  String email;
  String type;               // "client" o "official"
  GeoPoint? location;        // Ubicación (GeoPoint de Firestore, puede ser null para clientes)
  String? plan;              // Plan de suscripción ("free", "plus" o null si no aplica)

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    this.location,
    this.plan,
  });

  /// Convierte un Map de Firestore a un objeto User.
  factory User.fromMap(Map<String, dynamic> data, String documentId) {
    return User(
      id: documentId,
      name: data['name'] as String,
      email: data['email'] as String,
      type: data['type'] as String,
      location: data.containsKey('location') ? data['location'] as GeoPoint : null,
      plan: data.containsKey('plan') ? data['plan'] as String? : null,
    );
  }

  /// Convierte este objeto User a Map para almacenarlo en Firestore.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'type': type,
    };
    if (location != null) {
      map['location'] = location;
    }
    if (plan != null) {
      map['plan'] = plan;
    }
    return map;
  }
}

/// Estados para UserCubit
abstract class UserState {}
class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserSuccess extends UserState {
  final User? user;
  final List<User>? users;
  final String? message;
  UserSuccess({this.user, this.users, this.message});
}
class UserError extends UserState {
  final String error;
  UserError(this.error);
}

/// Cubit para gestión de usuarios (login, registro, consultas).
class UserCubit extends Cubit<UserState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserCubit() : super(UserInitial());

  /// Inicia sesión con email y contraseña. Obtiene el perfil de Firestore.
  Future<void> login(String email, String password) async {
    emit(UserLoading());
    try {
      // Autenticación con FirebaseAuth
      UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      String uid = cred.user!.uid;
      // Obtiene el documento de usuario desde Firestore
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        // Si no existe el perfil en Firestore, lanzamos error
        throw Exception("Perfil de usuario no encontrado.");
      }
      // Mapea el documento a objeto User
      User user = User.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      emit(UserSuccess(user: user));
    } on FirebaseAuthException catch (e) {
      emit(UserError(e.message ?? "Error de autenticación"));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Registra un nuevo usuario de tipo Cliente (por defecto). 
  /// Crea credenciales de autenticación y documento en Firestore.
  Future<void> registerClient(String name, String email, String password, {double? lat, double? lon}) async {
    emit(UserLoading());
    try {
      // Crear usuario en FirebaseAuth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      String uid = cred.user!.uid;
      // Construir objeto User con tipo "client"
      GeoPoint? location = (lat != null && lon != null) ? GeoPoint(lat, lon) : null;
      User newUser = User(
        id: uid,
        name: name,
        email: email,
        type: "client",
        location: location,
        plan: null,
      );
      // Almacenar en Firestore (colección "users" con ID = uid)
      await _firestore.collection('users').doc(uid).set(newUser.toMap());
      emit(UserSuccess(user: newUser));
    } on FirebaseAuthException catch (e) {
      emit(UserError(e.message ?? "Error al registrar cliente"));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Registra un nuevo usuario de tipo Oficial. 
  /// Acepta lista de oficios (jobIds) asociados, ubicación y plan (por defecto "free").
  Future<void> registerOfficial(String name, String email, String password, List<String> jobIds, double lat, double lon, {String plan = "free"}) async {
    emit(UserLoading());
    try {
      // Crear credenciales de usuario en FirebaseAuth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      String uid = cred.user!.uid;
      // Construir objeto User para el oficial
      GeoPoint location = GeoPoint(lat, lon);
      User newUser = User(
        id: uid,
        name: name,
        email: email,
        type: "official",
        location: location,
        plan: plan,
      );
      // Guardar documento de usuario en Firestore
      await _firestore.collection('users').doc(uid).set(newUser.toMap());
      // Guardar relaciones oficial-oficio en colección "official_jobs" (uno por cada oficio)
      for (String jobId in jobIds) {
        // Usamos como ID de documento la combinación "officialId_jobId" para evitar duplicados
        String relationId = "${uid}_$jobId";
        await _firestore.collection('official_jobs').doc(relationId).set({
          'officialId': uid,
          'jobId': jobId,
        });
      }
      emit(UserSuccess(user: newUser));
    } on FirebaseAuthException catch (e) {
      emit(UserError(e.message ?? "Error al registrar oficial"));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Obtiene un usuario por su ID (desde Firestore).
  Future<void> getUserById(String userId) async {
    emit(UserLoading());
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        emit(UserError("Usuario no encontrado"));
      } else {
        User user = User.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        emit(UserSuccess(user: user));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Consulta oficiales por **categoría de oficio**. 
  /// Retorna la lista de usuarios de tipo "official" que tienen oficios en la categoría dada.
  Future<void> getOfficialsByCategory(String categoryId) async {
    emit(UserLoading());
    try {
      // 1. Obtener los oficios (jobs) que pertenecen a la categoría indicada
      QuerySnapshot jobSnap = await _firestore.collection('jobs')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      List<String> jobIds = jobSnap.docs.map((doc) => doc.id).toList();
      if (jobIds.isEmpty) {
        emit(UserSuccess(users: [])); // No hay oficios en esta categoría
        return;
      }
      // 2. Obtener relaciones donde jobId esté en la lista de oficios obtenida
      // Firestore whereIn permite hasta 10 elementos; si hay más, se hacen consultas en lote.
      List<String> jobIdsBatch = jobIds.length > 10 ? jobIds.sublist(0, 10) : jobIds;
      QuerySnapshot relSnap = await _firestore.collection('official_jobs')
          .where('jobId', whereIn: jobIdsBatch)
          .get();
      // Si hay más de 10 oficios, procesar en lotes adicionales:
      if (jobIds.length > 10) {
        for (int i = 10; i < jobIds.length; i += 10) {
          var subList = jobIds.sublist(i, i + 10 > jobIds.length ? jobIds.length : i + 10);
          QuerySnapshot extraRelSnap = await _firestore.collection('official_jobs')
              .where('jobId', whereIn: subList)
              .get();
          relSnap.docs.addAll(extraRelSnap.docs);
        }
      }
      // Extraer IDs únicos de oficiales de las relaciones encontradas
      Set<String> officialIds = relSnap.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['officialId'] as String)
          .toSet();
      if (officialIds.isEmpty) {
        emit(UserSuccess(users: []));
        return;
      }
      // 3. Consultar los documentos de usuario correspondientes a esos officialIds
      List<User> officials = [];
      List<String> idsList = officialIds.toList();
      // Firestore whereIn en FieldPath.documentId para obtener documentos por ID (máx 10 por consulta)
      for (int i = 0; i < idsList.length; i += 10) {
        var batch = idsList.sublist(i, i + 10 > idsList.length ? idsList.length : i + 10);
        QuerySnapshot userSnap = await _firestore.collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .where('type', isEqualTo: 'official')
            .get();
        for (var doc in userSnap.docs) {
          officials.add(User.fromMap(doc.data() as Map<String, dynamic>, doc.id));
        }
      }
      emit(UserSuccess(users: officials));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Consulta los **5 oficiales más cercanos** a una ubicación dada (lat, lon).
  /// (Para simplificar, filtra dentro de un radio fijo y calcula distancias en el cliente)
  Future<void> getOfficialsByLocation(double latitude, double longitude, {double radiusKm = 50.0}) async {
    emit(UserLoading());
    try {
      // Obtener todos los usuarios de tipo "official" (en una app real, usar un enfoque geoespacial más eficiente)
      QuerySnapshot snap = await _firestore.collection('users')
          .where('type', isEqualTo: 'official')
          .get();
      List<User> allOfficials = snap.docs.map((doc) => User.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      if (allOfficials.isEmpty) {
        emit(UserSuccess(users: []));
        return;
      }
      // Calcular la distancia de cada oficial a la coordenada dada
      List<MapEntry<User, double>> distances = [];
      for (var off in allOfficials) {
        if (off.location == null) continue;
        double d = _distanceKm(latitude, longitude, off.location!.latitude, off.location!.longitude);
        if (d <= radiusKm) {
          distances.add(MapEntry(off, d));
        }
      }
      // Ordenar por distancia ascendente
      distances.sort((a, b) => a.value.compareTo(b.value));
      // Seleccionar los 5 más cercanos
      List<User> nearest = distances.map((e) => e.key).take(5).toList();
      emit(UserSuccess(users: nearest));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  /// Consulta oficiales filtrando por tipo de plan de suscripción ("free" o "plus").
  Future<void> getOfficialsByPlan(String planType) async {
    emit(UserLoading());
    try {
      QuerySnapshot snap = await _firestore.collection('users')
          .where('type', isEqualTo: 'official')
          .where('plan', isEqualTo: planType)
          .get();
      List<User> officials = snap.docs.map((doc) => User.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
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
    double a = sin(dLat/2) * sin(dLat/2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
        sin(dLon/2) * sin(dLon/2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Convierte grados a radianes.
  double _deg2rad(double deg) {
    return deg * pi / 180.0;
  }
}
