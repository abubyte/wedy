import '../../domain/entities/service.dart';

/// Loading type for merchant service operations
enum MerchantServiceLoadingType {
  /// Initial load of merchant services
  initial,

  /// Creating a new service
  creating,

  /// Updating an existing service
  updating,

  /// Deleting a service
  deleting,
}

/// Error type for merchant service operations
enum MerchantServiceErrorType {
  network,
  server,
  validation,
  auth,
  notFound,
  unknown,
}

/// Merchant service states using Dart 3 sealed classes for exhaustiveness checking
sealed class MerchantServiceState {
  const MerchantServiceState();
}

/// Initial state
final class MerchantServiceInitial extends MerchantServiceState {
  const MerchantServiceInitial();
}

/// Loading state with operation type
final class MerchantServiceLoading extends MerchantServiceState {
  final MerchantServiceLoadingType type;
  final MerchantServiceData? previousData;

  const MerchantServiceLoading({
    this.type = MerchantServiceLoadingType.initial,
    this.previousData,
  });
}

/// Unified data holder for merchant service state
class MerchantServiceData {
  /// The merchant's services list
  final List<MerchantService> services;

  /// Active services count from response
  final int activeCount;

  /// Inactive services count from response
  final int inactiveCount;

  /// Last successful operation result (for UI feedback)
  final MerchantServiceOperation? lastOperation;

  const MerchantServiceData({
    this.services = const [],
    this.activeCount = 0,
    this.inactiveCount = 0,
    this.lastOperation,
  });

  /// Get first service (for backward compatibility)
  MerchantService? get service => services.isNotEmpty ? services.first : null;

  /// Check if merchant has any services
  bool get hasServices => services.isNotEmpty;

  MerchantServiceData copyWith({
    List<MerchantService>? services,
    int? activeCount,
    int? inactiveCount,
    MerchantServiceOperation? Function()? lastOperation,
  }) {
    return MerchantServiceData(
      services: services ?? this.services,
      activeCount: activeCount ?? this.activeCount,
      inactiveCount: inactiveCount ?? this.inactiveCount,
      lastOperation: lastOperation != null ? lastOperation() : this.lastOperation,
    );
  }

  /// Clear the last operation (after UI has processed it)
  MerchantServiceData clearOperation() {
    return copyWith(lastOperation: () => null);
  }

  /// Add a service to the list
  MerchantServiceData addService(MerchantService service) {
    return copyWith(
      services: [...services, service],
      activeCount: activeCount + 1,
    );
  }

  /// Update a service in the list
  MerchantServiceData updateService(MerchantService updatedService) {
    return copyWith(
      services: services.map((s) => s.id == updatedService.id ? updatedService : s).toList(),
    );
  }

  /// Remove a service from the list
  MerchantServiceData removeService(String serviceId) {
    return copyWith(
      services: services.where((s) => s.id != serviceId).toList(),
      activeCount: activeCount > 0 ? activeCount - 1 : 0,
    );
  }
}

/// Represents a completed operation for UI feedback
sealed class MerchantServiceOperation {
  const MerchantServiceOperation();
}

final class ServiceCreatedOperation extends MerchantServiceOperation {
  final Service service;
  const ServiceCreatedOperation(this.service);
}

final class ServiceUpdatedOperation extends MerchantServiceOperation {
  final Service service;
  const ServiceUpdatedOperation(this.service);
}

final class ServiceDeletedOperation extends MerchantServiceOperation {
  final String serviceId;
  const ServiceDeletedOperation(this.serviceId);
}

/// Services loaded successfully
final class MerchantServiceLoaded extends MerchantServiceState {
  final MerchantServiceData data;

  const MerchantServiceLoaded(this.data);

  /// Convenience getter for the service
  MerchantService? get service => data.service;
}

/// Error state with type information
final class MerchantServiceError extends MerchantServiceState {
  final String message;
  final MerchantServiceErrorType type;
  final MerchantServiceData? previousData;

  const MerchantServiceError(
    this.message, {
    this.type = MerchantServiceErrorType.unknown,
    this.previousData,
  });
}
