import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';

/// Base class for category states
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

/// Loading state
class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

/// Categories loaded successfully
class CategoriesLoaded extends CategoryState {
  const CategoriesLoaded(this.categories);

  final CategoriesResponse categories;

  @override
  List<Object?> get props => [categories];
}

/// Error state
class CategoryError extends CategoryState {
  const CategoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

