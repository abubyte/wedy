import '../../domain/entities/featured_service.dart';

/// Loading type for featured services operations
enum FeaturedServicesLoadingType {
  initial,
  creating,
}

/// Error type for featured services operations
enum FeaturedServicesErrorType {
  network,
  server,
  auth,
  noFreeSlots,
  notFound,
  unknown,
}

/// Featured services states using Dart 3 sealed classes
sealed class FeaturedServicesState {
  const FeaturedServicesState();
}

/// Initial state
final class FeaturedServicesInitial extends FeaturedServicesState {
  const FeaturedServicesInitial();
}

/// Loading state
final class FeaturedServicesLoading extends FeaturedServicesState {
  final FeaturedServicesLoadingType type;
  final MerchantFeaturedServicesInfo? previousData;

  const FeaturedServicesLoading({
    this.type = FeaturedServicesLoadingType.initial,
    this.previousData,
  });
}

/// Featured services loaded successfully
final class FeaturedServicesLoaded extends FeaturedServicesState {
  final MerchantFeaturedServicesInfo data;
  final FeaturedServicesOperation? lastOperation;

  const FeaturedServicesLoaded(this.data, {this.lastOperation});

  List<FeaturedService> get featuredServices => data.featuredServices;
  int get remainingFreeSlots => data.remainingFreeSlots;
  bool get hasFreeSlots => data.remainingFreeSlots > 0;
}

/// Operation tracking
sealed class FeaturedServicesOperation {
  const FeaturedServicesOperation();
}

final class FeaturedServiceCreatedOperation extends FeaturedServicesOperation {
  final FeaturedService featuredService;
  const FeaturedServiceCreatedOperation(this.featuredService);
}

/// Error state
final class FeaturedServicesError extends FeaturedServicesState {
  final String message;
  final FeaturedServicesErrorType type;
  final MerchantFeaturedServicesInfo? previousData;

  const FeaturedServicesError(
    this.message, {
    this.type = FeaturedServicesErrorType.unknown,
    this.previousData,
  });
}
