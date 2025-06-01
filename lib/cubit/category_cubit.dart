import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:job_search_oficial/entities/entities.dart';

class CategoryState extends Equatable {
  final bool loading;
  final List<Category>? categories;
  final String? message;
  final String? error;

  const CategoryState({
    this.loading = false,
    this.categories,
    this.message,
    this.error,
  });

  CategoryState copyWith({
    bool? loading,
    List<Category>? categories,
    String? message,
    String? error,
  }) {
    return CategoryState(
        loading: loading ?? this.loading,
        categories: categories ?? this.categories,
        message: message,
        error: error);
  }

  @override
  List<Object?> get props => [
        loading,
        categories,
        message,
        error,
      ];
}

class CategoryCubit extends Cubit<CategoryState> {
  final _firestore = FirebaseFirestore.instance;
  final collectionCategory = 'categories';

  CategoryCubit() : super(CategoryState());

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
}
