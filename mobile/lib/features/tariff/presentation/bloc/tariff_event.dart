import 'package:equatable/equatable.dart';

/// Events for tariff management
abstract class TariffEvent extends Equatable {
  const TariffEvent();

  @override
  List<Object?> get props => [];
}

/// Load tariff plans
class LoadTariffPlansEvent extends TariffEvent {
  const LoadTariffPlansEvent();
}

/// Load subscription
class LoadSubscriptionEvent extends TariffEvent {
  const LoadSubscriptionEvent();
}

/// Create tariff payment
class CreateTariffPaymentEvent extends TariffEvent {
  final String tariffPlanId;
  final int durationMonths;
  final String paymentMethod;

  const CreateTariffPaymentEvent({
    required this.tariffPlanId,
    required this.durationMonths,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [tariffPlanId, durationMonths, paymentMethod];
}

/// Refresh tariff data
class RefreshTariffEvent extends TariffEvent {
  const RefreshTariffEvent();
}
