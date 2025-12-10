import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tariff.dart';
import '../repositories/tariff_repository.dart';

class GetTariffPlans {
  final TariffRepository repository;

  GetTariffPlans(this.repository);

  Future<Either<Failure, List<TariffPlan>>> call() async {
    return await repository.getTariffPlans();
  }
}
