import 'package:equatable/equatable.dart';
import '../../domain/entities/tariff.dart';
import '../../domain/repositories/tariff_repository.dart';

/// States for tariff management
abstract class TariffState extends Equatable {
  const TariffState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TariffInitial extends TariffState {
  const TariffInitial();
}

/// Loading state
class TariffLoading extends TariffState {
  const TariffLoading();
}

/// Tariff plans loaded
class TariffPlansLoaded extends TariffState {
  final List<TariffPlan> plans;

  const TariffPlansLoaded(this.plans);

  @override
  List<Object?> get props => [plans];
}

/// Subscription loaded
class SubscriptionLoaded extends TariffState {
  final Subscription? subscription;

  const SubscriptionLoaded(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

/// Combined state with both plans and subscription
class TariffDataLoaded extends TariffState {
  final List<TariffPlan> plans;
  final Subscription? subscription;

  const TariffDataLoaded({required this.plans, this.subscription});

  @override
  List<Object?> get props => [plans, subscription];
}

/// Payment created
class PaymentCreated extends TariffState {
  final PaymentResponse payment;

  const PaymentCreated(this.payment);

  @override
  List<Object?> get props => [payment];
}

/// Error state
class TariffError extends TariffState {
  final String message;

  const TariffError(this.message);

  @override
  List<Object?> get props => [message];
}
