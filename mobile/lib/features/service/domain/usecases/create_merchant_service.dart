import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Use case for creating a merchant service
class CreateMerchantService {
  final ServiceRepository repository;

  CreateMerchantService(this.repository);

  Future<Either<Failure, Service>> call({
    required String name,
    required String description,
    required int categoryId,
    required double price,
    required String locationRegion,
    double? latitude,
    double? longitude,
  }) async {
    // Validate required fields
    if (name.trim().isEmpty) {
      return const Left(ValidationFailure('Service name is required'));
    }
    if (description.trim().isEmpty) {
      return const Left(ValidationFailure('Service description is required'));
    }
    if (price < 0) {
      return const Left(ValidationFailure('Price must be non-negative'));
    }
    if (locationRegion.trim().isEmpty) {
      return const Left(ValidationFailure('Location region is required'));
    }

    return await repository.createService(
      name: name.trim(),
      description: description.trim(),
      categoryId: categoryId,
      price: price,
      locationRegion: locationRegion.trim(),
      latitude: latitude,
      longitude: longitude,
    );
  }
}
