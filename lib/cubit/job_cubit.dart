import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:job_search_oficial/entities/entities.dart';

class JobState extends Equatable {
  final bool loading;
  final List<Category>? categories;
  final List<Job>? jobs;
  final String? message;
  final String? error;

  const JobState({
    this.loading = false,
    this.categories,
    this.jobs,
    this.message,
    this.error,
  });

  JobState copyWith({
    bool? loading,
    List<Category>? categories,
    List<Job>? jobs,
    String? message,
    String? error,
  }) {
    return JobState(
      loading: loading ?? this.loading,
      categories: categories ?? this.categories,
      jobs: jobs ?? this.jobs,
      message: message,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, categories, jobs, message, error];
}

class JobCubit extends Cubit<JobState> {
  final String collectionCategory = 'categories';
  final String collectionJobs = 'jobs';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  JobCubit() : super(const JobState());

  // Obtener todos los Jobs
  Future<List<Job>> getJobs() async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      final snap = await _firestore.collection(collectionJobs).get();

      final jobs = snap.docs
          .map((job) => Job.fromMap(job.data(), docId: job.id))
          .toList();

      emit(state.copyWith(
        loading: false,
        jobs: jobs,
        message: 'Trabajos cargados',
      ));
      return jobs;
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Error cargando trabajos: $e',
      ));
      return [];
    }
  }

  /// Obtiene los jobs para una categoría dada
  Future<void> getJobsByCategory(String categoryId) async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      // Obtener nombre de la categoría
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

      // Consultar jobs por referencia
      final jobSnap = await _firestore
          .collection(collectionJobs)
          .where('categoryNameRef', isEqualTo: categoryId)
          .get();
      final denormJobs = jobSnap.docs.map((d) {
        final raw = d.data();
        return Job(
          id: d.id,
          name: raw['name'] as String,
          categoryName: categoryName,
          categoryNameRef: raw['categoryNameRef'] as String,
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
      // Filtrar por usuarios de tipo "oficial" cuyo arreglo oficialProfile.jobsIds contenga jobRef
      final snap = await _firestore
          .collection('users')
          .where('type', isEqualTo: UserType.oficial.name)
          .where('oficialProfile.jobsIds', arrayContains: jobRef)
          .get();

      final result =
          snap.docs.map((d) => UserEntity.fromMap(d.data(), d.id)).toList();

      emit(state.copyWith(
        loading: false,
        message: 'Usuarios oficiales cargados',
      ));
      return result;
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Error cargando usuarios por job: $e',
      ));
      return [];
    }
  }
}
