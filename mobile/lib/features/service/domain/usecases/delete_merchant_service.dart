import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/service_repository.dart';

/// Use case for deleting a merchant service
class DeleteMerchantService {
  final ServiceRepository repository;

  DeleteMerchantService(this.repository);

  Future<Either<Failure, void>> call(String serviceId) async {
    // Validate service ID
    if (serviceId.trim().isEmpty) {
      return const Left(ValidationFailure('Service ID is required'));
    }

    return await repository.deleteService(serviceId.trim());
  }
}
