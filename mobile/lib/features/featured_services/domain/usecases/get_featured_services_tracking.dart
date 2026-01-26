import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/featured_service.dart';
import '../repositories/featured_services_repository.dart';

/// Use case to get featured services tracking
class GetFeaturedServicesTracking {
  final FeaturedServicesRepository repository;

  GetFeaturedServicesTracking(this.repository);

  Future<Either<Failure, MerchantFeaturedServicesInfo>> call() {
    return repository.getFeaturedServicesTracking();
  }
}
