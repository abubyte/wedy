import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/featured_service.dart';

/// Featured services repository interface (domain layer)
abstract class FeaturedServicesRepository {
  /// Get merchant featured services tracking
  Future<Either<Failure, MerchantFeaturedServicesInfo>> getFeaturedServicesTracking();

  /// Create monthly featured service (uses free allocation)
  Future<Either<Failure, FeaturedService>> createMonthlyFeaturedService(String serviceId);
}
