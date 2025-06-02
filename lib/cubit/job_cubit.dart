import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:job_search_oficial/entities/entities.dart';

class JobState extends Equatable {
  final bool loading;
  final List<Category>? categories;
  final List<Job>? jobs;
  final String? message;
  final String? error;
  final List<UserEntity>? users;

  const JobState({
    this.loading = false,
    this.categories,
    this.jobs,
    this.message,
    this.error,
    this.users,
  });

  JobState copyWith({
    bool? loading,
    List<Category>? categories,
    List<Job>? jobs,
    String? message,
    String? error,
    List<UserEntity>? users,
  }) {
    return JobState(
      loading: loading ?? this.loading,
      categories: categories ?? this.categories,
      jobs: jobs ?? this.jobs,
      message: message,
      error: error,
      users: users ?? this.users,
    );
  }

  @override
  List<Object?> get props => [loading, categories, jobs, message, error, users];
}

class JobCubit extends Cubit<JobState> {
  final String collectionCategory = 'categories';
  final String collectionJobs = 'jobs';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  JobCubit() : super(const JobState());

  void setUsers(List<UserEntity> users) {
    emit(state.copyWith(users: users));
  }

  // Obtener todos los Jobs

  Future<List<Job>> getAllJobs() async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      final snap = await _firestore.collection('jobs').get();

      final jobs = snap.docs
          .map((doc) => Job.fromMap(doc.data(), doc.id, docId: ''))
          .toList();

      emit(state.copyWith(jobs: jobs, loading: false));

      return jobs;
    } catch (e) {
      emit(
          state.copyWith(loading: false, error: 'Error cargando trabajos: $e'));
      return [];
    }
  }

  Future<void> getJobsByCategory(String categoryId) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      // Obtener el nombre de la categoría
      final catDoc =
          await _firestore.collection(collectionCategory).doc(categoryId).get();
      if (!catDoc.exists) {
        emit(state.copyWith(
          loading: false,
          error: 'Categoría no encontrada',
        ));
        return;
      }
      final categoryName = catDoc.data()!['name'] as String;

      // Obtener los trabajos de esa categoría
      final jobSnap = await _firestore
          .collection(collectionJobs)
          .where('categoryNameRef',
              isEqualTo: _firestore.doc('categories/$categoryId'))
          .get();

      // Convertimos los documentos en objetos Job
      final denormJobs = jobSnap.docs.map((d) {
        final raw = d.data();
        return Job(
          id: d.id,
          name: raw['name'] as String,
          categoryName: categoryName,
          categoryNameRef: raw['categoryNameRef'] as DocumentReference, //
        );
      }).toList();

      emit(state.copyWith(
        loading: false,
        jobs: denormJobs,
        message: 'Trabajos cargados',
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Error cargando trabajos: $e',
      ));
    }
  }

  // Get users by a Job
  Future<List<UserEntity>> getUsersByJob(String jobRef) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      final ref = _firestore.doc('jobs/$jobRef');

      final snap = await _firestore
          .collection('users')
          .where('type', isEqualTo: UserType.official.name)
          .where('oficialProfile.jobIds', arrayContains: ref)
          .get();

      final result =
          snap.docs.map((d) => UserEntity.fromMap(d.data(), d.id)).toList();

      emit(state.copyWith(
        loading: false,
        message: 'Usuarios oficiales cargados',
      ));
      return result;
    } catch (e) {
      print('[ERROR] $e');
      emit(state.copyWith(
        loading: false,
        error: 'Error cargando usuarios por job: $e',
      ));
      return [];
    }
  }

  getMultipleJobsByCategories(List<String> selectedCategoryIds) {}
}
