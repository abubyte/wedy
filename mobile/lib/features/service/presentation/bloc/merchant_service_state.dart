import '../../domain/entities/service.dart';

/// Merchant service states using Dart 3 sealed classes for exhaustiveness checking
sealed class MerchantServiceState {
  const MerchantServiceState();
}

/// Initial state
final class MerchantServiceInitial extends MerchantServiceState {
  const MerchantServiceInitial();
}

/// Loading state
final class MerchantServiceLoading extends MerchantServiceState {
  const MerchantServiceLoading();
}

/// Services loaded successfully
final class MerchantServicesLoaded extends MerchantServiceState {
  final MerchantServicesResponse servicesResponse;

  const MerchantServicesLoaded(this.servicesResponse);
}

/// Single merchant service loaded successfully (nullable - null means no service)
final class MerchantServiceLoaded extends MerchantServiceState {
  final MerchantService? service;

  const MerchantServiceLoaded(this.service);
}

/// Service created successfully
final class ServiceCreated extends MerchantServiceState {
  final Service service;

  const ServiceCreated(this.service);
}

/// Service updated successfully
final class ServiceUpdated extends MerchantServiceState {
  final Service service;

  const ServiceUpdated(this.service);
}

/// Service deleted successfully
final class ServiceDeleted extends MerchantServiceState {
  final String serviceId;

  const ServiceDeleted(this.serviceId);
}

/// Error state
final class MerchantServiceError extends MerchantServiceState {
  final String message;

  const MerchantServiceError(this.message);
}
