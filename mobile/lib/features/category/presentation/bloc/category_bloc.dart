import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_categories.dart';
import '../../../../core/errors/failures.dart';
import 'category_event.dart';
import 'category_state.dart';

/// BLoC for managing category state
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc({required GetCategories getCategoriesUseCase})
      : _getCategoriesUseCase = getCategoriesUseCase,
        super(const CategoryInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
  }

  final GetCategories _getCategoriesUseCase;

  Future<void> _onLoadCategories(LoadCategoriesEvent event, Emitter<CategoryState> emit) async {
    emit(const CategoryLoading());

    final result = await _getCategoriesUseCase();

    result.fold(
      (failure) => emit(CategoryError(_getErrorMessage(failure))),
      (categories) => emit(CategoriesLoaded(categories)),
    );
  }

  String _getErrorMessage(dynamic failure) {
    if (failure is NetworkFailure) {
      return 'Network error. Please check your internet connection.';
    } else if (failure is ServerFailure) {
      return 'Server error. Please try again later.';
    } else if (failure is NotFoundFailure) {
      return 'Categories not found.';
    } else if (failure is AuthFailure) {
      return 'Authentication failed. Please login again.';
    } else if (failure is ValidationFailure) {
      return failure.message;
    }
    return 'An unexpected error occurred.';
  }
}

