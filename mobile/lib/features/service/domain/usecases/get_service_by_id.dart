import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Use case for getting service details by ID
class GetServiceById {
  final ServiceRepository repository;

  GetServiceById(this.repository);

  Future<Either<Failure, Service>> call(String serviceId) async {
    if (serviceId.isEmpty) {
      return const Left(ValidationFailure('Service ID cannot be empty'));
    }
    return await repository.getServiceById(serviceId);
  }
}
