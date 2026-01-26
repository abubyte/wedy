import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_categories.dart';
import 'category_event.dart';
import 'category_state.dart';

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
      (failure) => emit(CategoryError(failure.toUserMessage(entityName: 'Categories'))),
      (categories) => emit(CategoriesLoaded(categories)),
    );
  }
}
