import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/featured_service.dart';
import '../repositories/featured_services_repository.dart';

/// Use case to create a monthly featured service (free allocation)
class CreateMonthlyFeaturedService {
  final FeaturedServicesRepository repository;

  CreateMonthlyFeaturedService(this.repository);

  Future<Either<Failure, FeaturedService>> call(String serviceId) {
    if (serviceId.isEmpty) {
      return Future.value(const Left(ValidationFailure('Service ID is required')));
    }
    return repository.createMonthlyFeaturedService(serviceId);
  }
}
