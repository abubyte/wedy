import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../tariff/domain/repositories/tariff_repository.dart';
import '../repositories/featured_services_repository.dart';

/// Use case to create a paid featured service payment
class CreateFeaturedPayment {
  final FeaturedServicesRepository repository;

  CreateFeaturedPayment(this.repository);

  Future<Either<Failure, PaymentResponse>> call({
    required String serviceId,
    required int durationDays,
    required String paymentMethod,
  }) {
    if (serviceId.isEmpty) {
      return Future.value(const Left(ValidationFailure('Service ID is required')));
    }
    if (durationDays < 1) {
      return Future.value(const Left(ValidationFailure('Duration must be at least 1 day')));
    }
    return repository.createFeaturedServicePayment(
      serviceId: serviceId,
      durationDays: durationDays,
      paymentMethod: paymentMethod,
    );
  }
}
