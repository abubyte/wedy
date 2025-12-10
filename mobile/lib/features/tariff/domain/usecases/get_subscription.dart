import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tariff.dart';
import '../repositories/tariff_repository.dart';

class GetSubscription {
  final TariffRepository repository;

  GetSubscription(this.repository);

  Future<Either<Failure, Subscription?>> call() async {
    return await repository.getSubscription();
  }
}
