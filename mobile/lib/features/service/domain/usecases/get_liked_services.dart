import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/service_repository.dart';
import '../entities/service.dart';

/// Use case for getting user's liked services
class GetLikedServices {
  final ServiceRepository repository;

  GetLikedServices(this.repository);

  Future<Either<Failure, List<ServiceListItem>>> call() async {
    return await repository.getLikedServices();
  }
}
