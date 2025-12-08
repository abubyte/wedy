import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Use case for getting paginated list of services
class GetServices {
  final ServiceRepository repository;

  GetServices(this.repository);

  Future<Either<Failure, PaginatedServiceResponse>> call({
    bool? featured,
    ServiceSearchFilters? filters,
    int page = 1,
    int limit = 20,
  }) async {
    return await repository.getServices(featured: featured, filters: filters, page: page, limit: limit);
  }
}
