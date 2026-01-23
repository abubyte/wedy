/// Category events using Dart 3 sealed classes for exhaustiveness checking
sealed class CategoryEvent {
  const CategoryEvent();
}

/// Event to load all categories
final class LoadCategoriesEvent extends CategoryEvent {
  const LoadCategoriesEvent();
}
