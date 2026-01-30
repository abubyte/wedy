import 'package:dartz/dartz.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/category/domain/entities/category.dart';

/// Abstract repository interface for categories
abstract class CategoryRepository {
  /// Get all active service categories with service counts
  Future<Either<Failure, CategoriesResponse>> getCategories();
}
