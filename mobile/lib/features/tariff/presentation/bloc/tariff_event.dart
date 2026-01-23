/// Tariff events using Dart 3 sealed classes for exhaustiveness checking
sealed class TariffEvent {
  const TariffEvent();
}

/// Load tariff plans
final class LoadTariffPlansEvent extends TariffEvent {
  const LoadTariffPlansEvent();
}

/// Load subscription
final class LoadSubscriptionEvent extends TariffEvent {
  const LoadSubscriptionEvent();
}

/// Create tariff payment
final class CreateTariffPaymentEvent extends TariffEvent {
  final String tariffPlanId;
  final int durationMonths;
  final String paymentMethod;

  const CreateTariffPaymentEvent({
    required this.tariffPlanId,
    required this.durationMonths,
    required this.paymentMethod,
  });
}

/// Refresh tariff data
final class RefreshTariffEvent extends TariffEvent {
  const RefreshTariffEvent();
}

/// Activate subscription (free 2-month activation for existing merchants)
final class ActivateSubscriptionEvent extends TariffEvent {
  const ActivateSubscriptionEvent();
}
