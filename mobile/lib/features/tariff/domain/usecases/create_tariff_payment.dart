import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/tariff_repository.dart';

class CreateTariffPayment {
  final TariffRepository repository;

  CreateTariffPayment(this.repository);

  Future<Either<Failure, PaymentResponse>> call({
    required String tariffPlanId,
    required int durationMonths,
    required String paymentMethod,
  }) async {
    return await repository.createTariffPayment(
      tariffPlanId: tariffPlanId,
      durationMonths: durationMonths,
      paymentMethod: paymentMethod,
    );
  }
}
