import '../../domain/entities/tariff.dart';
import '../../domain/repositories/tariff_repository.dart';

/// Tariff states using Dart 3 sealed classes for exhaustiveness checking
sealed class TariffState {
  const TariffState();
}

/// Initial state
final class TariffInitial extends TariffState {
  const TariffInitial();
}

/// Loading state
final class TariffLoading extends TariffState {
  const TariffLoading();
}

/// Tariff plans loaded
final class TariffPlansLoaded extends TariffState {
  final List<TariffPlan> plans;

  const TariffPlansLoaded(this.plans);
}

/// Subscription loaded
final class SubscriptionLoaded extends TariffState {
  final Subscription? subscription;

  const SubscriptionLoaded(this.subscription);
}

/// Combined state with both plans and subscription
final class TariffDataLoaded extends TariffState {
  final List<TariffPlan> plans;
  final Subscription? subscription;

  const TariffDataLoaded({required this.plans, this.subscription});

  TariffDataLoaded copyWith({
    List<TariffPlan>? plans,
    Subscription? Function()? subscription,
  }) {
    return TariffDataLoaded(
      plans: plans ?? this.plans,
      subscription: subscription != null ? subscription() : this.subscription,
    );
  }
}

/// Payment created
final class PaymentCreated extends TariffState {
  final PaymentResponse payment;

  const PaymentCreated(this.payment);
}

/// Error state
final class TariffError extends TariffState {
  final String message;

  const TariffError(this.message);
}
