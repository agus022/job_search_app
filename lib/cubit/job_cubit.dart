import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:job_search_oficial/entities/entities.dart';

abstract class JobCategoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Cubit states
class JCInitial extends JobCategoryState {}

class JCLoading extends JobCategoryState {}

class JCCategoriesLoaded extends JobCategoryState {
  final List<Category> categories;
  JCCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class JCJobsLoaded extends JobCategoryState {
  final List<Job> jobs;
  JCJobsLoaded(this.jobs);

  @override
  List<Object?> get props => [jobs];
}

class JCError extends JobCategoryState {
  final String message;
  JCError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Cubit
class JobCategoryCubit extends Cubit<JobCategoryState> {
  final collectionCategory = 'categories';
  final collectionJobs = 'jobs';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  JobCategoryCubit() : super(JCInitial());

  /// Get de todas las categorías
  Future<void> getCategories() async {
    emit(JCLoading());
    try {
      final snap = await _firestore.collection(collectionCategory).get();
      final cats =
          snap.docs.map((d) => Category.fromMap(d.data(), d.id)).toList();
      emit(JCCategoriesLoaded(cats));
    } catch (e) {
      emit(JCError('Error cargando categorías: $e'));
    }
  }

  /// Get de jobs para una categoría dada
  Future<void> getJobsByCategory(String categoryId) async {
    emit(JCLoading());
    try {
      // Primero carga el nombre de la categoría (opcional, para denormalizar)
      final catDoc =
          await _firestore.collection(collectionCategory).doc(categoryId).get();
      if (!catDoc.exists) {
        emit(JCError('Categoría no encontrada'));
        return;
      }
      final categoryName = (catDoc.data()!['name'] as String);

      // Luego obtiene los jobs referenciando categoryId
      final jobSnap = await _firestore
          .collection(collectionJobs)
          .where('categoryNameRef', isEqualTo: categoryId)
          .get();
      final jobs =
          jobSnap.docs.map((d) => Job.fromMap(d.data(), docId: d.id)).toList();

      // Aseguramos que cada Job tenga consistente categoryName
      final denormJobs = jobs.map((j) {
        return Job(
          id: j.id,
          name: j.name,
          categoryName: categoryName,
          categoryNameRef: j.categoryNameRef,
        );
      }).toList();

      emit(JCJobsLoaded(denormJobs));
    } catch (e) {
      emit(JCError('Error cargando trabajos: $e'));
    }
  }
}
