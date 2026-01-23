import '../../domain/entities/category.dart';

/// Category states using Dart 3 sealed classes for exhaustiveness checking
sealed class CategoryState {
  const CategoryState();
}

/// Initial state
final class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

/// Loading state
final class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

/// Categories loaded successfully
final class CategoriesLoaded extends CategoryState {
  final CategoriesResponse categories;

  const CategoriesLoaded(this.categories);
}

/// Error state
final class CategoryError extends CategoryState {
  final String message;

  const CategoryError(this.message);
}
