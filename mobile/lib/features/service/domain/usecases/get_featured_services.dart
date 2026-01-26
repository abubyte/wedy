import 'package:dartz/dartz.dart';
import 'package:wedy/core/errors/failures.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/domain/repositories/service_repository.dart';

class GetFeaturedServices {
  final ServiceRepository repository;

  GetFeaturedServices(this.repository);

  Future<Either<Failure, PaginatedServiceResponse>> call() async {
    return await repository.getServices(featured: true);
  }
}
