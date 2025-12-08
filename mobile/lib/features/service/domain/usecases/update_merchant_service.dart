import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Use case for updating a merchant service
class UpdateMerchantService {
  final ServiceRepository repository;

  UpdateMerchantService(this.repository);

  Future<Either<Failure, Service>> call({
    required String serviceId,
    String? name,
    String? description,
    int? categoryId,
    double? price,
    String? locationRegion,
    double? latitude,
    double? longitude,
  }) async {
    // Validate service ID
    if (serviceId.trim().isEmpty) {
      return const Left(ValidationFailure('Service ID is required'));
    }

    // Validate fields if provided
    if (name != null && name.trim().isEmpty) {
      return const Left(ValidationFailure('Service name cannot be empty'));
    }
    if (description != null && description.trim().isEmpty) {
      return const Left(ValidationFailure('Service description cannot be empty'));
    }
    if (price != null && price < 0) {
      return const Left(ValidationFailure('Price must be non-negative'));
    }
    if (locationRegion != null && locationRegion.trim().isEmpty) {
      return const Left(ValidationFailure('Location region cannot be empty'));
    }

    return await repository.updateService(
      serviceId: serviceId.trim(),
      name: name?.trim(),
      description: description?.trim(),
      categoryId: categoryId,
      price: price,
      locationRegion: locationRegion?.trim(),
      latitude: latitude,
      longitude: longitude,
    );
  }
}
