import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/tariff.dart';

/// Tariff repository interface (domain layer)
abstract class TariffRepository {
  /// Get all active tariff plans
  Future<Either<Failure, List<TariffPlan>>> getTariffPlans();

  /// Get merchant's current subscription
  Future<Either<Failure, Subscription?>> getSubscription();

  /// Create tariff payment
  Future<Either<Failure, PaymentResponse>> createTariffPayment({
    required String tariffPlanId,
    required int durationMonths,
    required String paymentMethod,
  });

  /// Activate free subscription for existing merchant (2 months)
  Future<Either<Failure, Subscription?>> activateSubscription();
}

/// Payment response
class PaymentResponse {
  final String id;
  final double amount;
  final String? paymentUrl;
  final String? transactionId;
  final DateTime createdAt;

  PaymentResponse({
    required this.id,
    required this.amount,
    this.paymentUrl,
    this.transactionId,
    required this.createdAt,
  });
}
