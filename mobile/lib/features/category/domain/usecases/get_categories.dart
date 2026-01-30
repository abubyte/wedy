import 'package:dartz/dartz.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/category/domain/entities/category.dart';
import 'package:wedy/features/category/domain/repositories/category_repository.dart';

/// Use case for retrieving all service categories
class GetCategories {
  const GetCategories(this.repository);

  final CategoryRepository repository;

  Future<Either<Failure, CategoriesResponse>> call() async {
    return await repository.getCategories();
  }
}
