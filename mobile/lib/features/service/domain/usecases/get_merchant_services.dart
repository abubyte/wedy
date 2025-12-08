import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Use case for getting merchant's services
class GetMerchantServices {
  final ServiceRepository repository;

  GetMerchantServices(this.repository);

  Future<Either<Failure, MerchantServicesResponse>> call() async {
    return await repository.getMerchantServices();
  }
}
