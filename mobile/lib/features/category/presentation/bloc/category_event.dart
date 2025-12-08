import 'package:equatable/equatable.dart';

/// Base class for category events
abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all categories
class LoadCategoriesEvent extends CategoryEvent {
  const LoadCategoriesEvent();
}

