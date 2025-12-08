import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service.dart';

/// Service repository interface (domain layer)
abstract class ServiceRepository {
  /// Get paginated list of services with optional filters
  Future<Either<Failure, PaginatedServiceResponse>> getServices({
    bool? featured,
    ServiceSearchFilters? filters,
    int page = 1,
    int limit = 20,
  });

  /// Get service details by ID
  Future<Either<Failure, Service>> getServiceById(String serviceId);

  /// Interact with service (like, save, share)
  Future<Either<Failure, ServiceInteractionResponse>> interactWithService(String serviceId, String interactionType);

  /// Get user's saved services
  Future<Either<Failure, List<ServiceListItem>>> getSavedServices();

  /// Get merchant's services
  Future<Either<Failure, MerchantServicesResponse>> getMerchantServices();

  /// Create a new service
  Future<Either<Failure, Service>> createService({
    required String name,
    required String description,
    required int categoryId,
    required double price,
    required String locationRegion,
    double? latitude,
    double? longitude,
  });

  /// Update a service
  Future<Either<Failure, Service>> updateService({
    required String serviceId,
    String? name,
    String? description,
    int? categoryId,
    double? price,
    String? locationRegion,
    double? latitude,
    double? longitude,
  });

  /// Delete a service
  Future<Either<Failure, void>> deleteService(String serviceId);
}

/// Service interaction response
class ServiceInteractionResponse {
  final bool success;
  final String message;
  final int newCount;

  ServiceInteractionResponse({required this.success, required this.message, required this.newCount});
}
