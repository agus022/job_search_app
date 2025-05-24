import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:job_search_oficial/entities/entities.dart';

class JobCategoryState extends Equatable {
  final bool loading;
  final List<Category>? categories;
  final List<Job>? jobs;
  final String? message;
  final String? error;

  const JobCategoryState({
    this.loading = false,
    this.categories,
    this.jobs,
    this.message,
    this.error,
  });

  JobCategoryState copyWith({
    bool? loading,
    List<Category>? categories,
    List<Job>? jobs,
    String? message,
    String? error,
  }) {
    return JobCategoryState(
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

class JobCategoryCubit extends Cubit<JobCategoryState> {
  final String collectionCategory = 'categories';
  final String collectionJobs = 'jobs';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  JobCategoryCubit() : super(const JobCategoryState());

  /// Obtiene todas las categorías
  Future<void> getCategories() async {
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      final snap = await _firestore.collection(collectionCategory).get();
      final cats =
          snap.docs.map((d) => Category.fromMap(d.data(), d.id)).toList();
      emit(state.copyWith(
        loading: false,
        categories: cats,
        message: 'Categorías cargadas',
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Error cargando categorías: $e',
      ));
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
}
