import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wedy/core/constants/uzbekistan_data.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/service.dart';
import '../../domain/usecases/create_merchant_service.dart';
import '../../domain/usecases/delete_merchant_service.dart';
import '../../domain/usecases/get_merchant_services.dart';
import '../../domain/usecases/update_merchant_service.dart';
import 'merchant_service_event.dart';
import 'merchant_service_state.dart';

/// BLoC for managing merchant services
///
/// Improvements over previous implementation:
/// 1. Direct state updates - no reload after create/update/delete
/// 2. Better error handling with types
/// 3. Operation tracking for UI feedback
/// 4. Proper pattern matching for failures
class MerchantServiceBloc extends Bloc<MerchantServiceEvent, MerchantServiceState> {
  final GetMerchantServices _getMerchantServices;
  final CreateMerchantService _createMerchantService;
  final UpdateMerchantService _updateMerchantService;
  final DeleteMerchantService _deleteMerchantService;

  MerchantServiceBloc({
    required GetMerchantServices getMerchantServices,
    required CreateMerchantService createMerchantService,
    required UpdateMerchantService updateMerchantService,
    required DeleteMerchantService deleteMerchantService,
  }) : _getMerchantServices = getMerchantServices,
       _createMerchantService = createMerchantService,
       _updateMerchantService = updateMerchantService,
       _deleteMerchantService = deleteMerchantService,
       super(const MerchantServiceInitial()) {
    on<LoadMerchantServicesEvent>(_onLoadMerchantServices);
    on<CreateServiceEvent>(_onCreateService);
    on<UpdateServiceEvent>(_onUpdateService);
    on<DeleteServiceEvent>(_onDeleteService);
    on<RefreshMerchantServicesEvent>(_onRefreshMerchantServices);
  }

  /// Get current data from state if available
  MerchantServiceData? get _currentData {
    final currentState = state;
    if (currentState is MerchantServiceLoaded) {
      return currentState.data;
    }
    if (currentState is MerchantServiceLoading) {
      return currentState.previousData;
    }
    if (currentState is MerchantServiceError) {
      return currentState.previousData;
    }
    return null;
  }

  /// Map failure to error type
  MerchantServiceErrorType _mapFailureToErrorType(Failure failure) {
    return switch (failure) {
      NetworkFailure() => MerchantServiceErrorType.network,
      ServerFailure() => MerchantServiceErrorType.server,
      ValidationFailure() => MerchantServiceErrorType.validation,
      AuthFailure() => MerchantServiceErrorType.auth,
      NotFoundFailure() => MerchantServiceErrorType.notFound,
      CacheFailure() => MerchantServiceErrorType.unknown,
    };
  }

  Future<void> _onLoadMerchantServices(LoadMerchantServicesEvent event, Emitter<MerchantServiceState> emit) async {
    emit(MerchantServiceLoading(type: MerchantServiceLoadingType.initial, previousData: _currentData));

    final result = await _getMerchantServices();

    result.fold(
      (failure) => emit(
        MerchantServiceError(
          failure.toUserMessage(entityName: 'Merchant services'),
          type: _mapFailureToErrorType(failure),
          previousData: _currentData,
        ),
      ),
      (servicesResponse) {
        emit(
          MerchantServiceLoaded(
            MerchantServiceData(
              services: servicesResponse.services,
              activeCount: servicesResponse.activeCount,
              inactiveCount: servicesResponse.inactiveCount,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onCreateService(CreateServiceEvent event, Emitter<MerchantServiceState> emit) async {
    final previousData = _currentData;

    emit(MerchantServiceLoading(type: MerchantServiceLoadingType.creating, previousData: previousData));

    final result = await _createMerchantService(
      name: event.name,
      description: event.description,
      categoryId: event.categoryId,
      price: event.price,
      locationRegion: UzbekistanData.regionValues[event.locationRegion] ?? event.locationRegion,
      latitude: event.latitude,
      longitude: event.longitude,
    );

    result.fold(
      (failure) => emit(
        MerchantServiceError(
          failure.toUserMessage(entityName: 'Service'),
          type: _mapFailureToErrorType(failure),
          previousData: previousData,
        ),
      ),
      (createdService) {
        // Convert Service to MerchantService for direct state update
        final merchantService = _serviceToMerchantService(createdService);

        // Directly update state by adding new service to list (no reload needed)
        final newData = (previousData ?? const MerchantServiceData())
            .addService(merchantService)
            .copyWith(lastOperation: () => ServiceCreatedOperation(createdService));
        emit(MerchantServiceLoaded(newData));
      },
    );
  }

  Future<void> _onUpdateService(UpdateServiceEvent event, Emitter<MerchantServiceState> emit) async {
    final previousData = _currentData;

    emit(MerchantServiceLoading(type: MerchantServiceLoadingType.updating, previousData: previousData));

    final result = await _updateMerchantService(
      serviceId: event.serviceId,
      name: event.name,
      description: event.description,
      categoryId: event.categoryId,
      price: event.price,
      locationRegion: event.locationRegion,
      latitude: event.latitude,
      longitude: event.longitude,
    );

    result.fold(
      (failure) => emit(
        MerchantServiceError(
          failure.toUserMessage(entityName: 'Service'),
          type: _mapFailureToErrorType(failure),
          previousData: previousData,
        ),
      ),
      (updatedService) {
        // Convert Service to MerchantService for direct state update
        final merchantService = _serviceToMerchantService(updatedService);

        // Directly update state by updating service in list (no reload needed)
        final newData = (previousData ?? const MerchantServiceData())
            .updateService(merchantService)
            .copyWith(lastOperation: () => ServiceUpdatedOperation(updatedService));
        emit(MerchantServiceLoaded(newData));
      },
    );
  }

  Future<void> _onDeleteService(DeleteServiceEvent event, Emitter<MerchantServiceState> emit) async {
    final previousData = _currentData;

    emit(MerchantServiceLoading(type: MerchantServiceLoadingType.deleting, previousData: previousData));

    final result = await _deleteMerchantService(event.serviceId);

    result.fold(
      (failure) => emit(
        MerchantServiceError(
          failure.toUserMessage(entityName: 'Service'),
          type: _mapFailureToErrorType(failure),
          previousData: previousData,
        ),
      ),
      (_) {
        // Directly update state - remove the service from list (no reload needed)
        final newData = (previousData ?? const MerchantServiceData())
            .removeService(event.serviceId)
            .copyWith(lastOperation: () => ServiceDeletedOperation(event.serviceId));
        emit(MerchantServiceLoaded(newData));
      },
    );
  }

  Future<void> _onRefreshMerchantServices(
    RefreshMerchantServicesEvent event,
    Emitter<MerchantServiceState> emit,
  ) async {
    // Simply reload - this is for pull-to-refresh or explicit refresh
    add(const LoadMerchantServicesEvent());
  }

  /// Convert Service entity to MerchantService
  /// This handles the case where API returns full Service after create/update
  MerchantService _serviceToMerchantService(Service service) {
    return MerchantService(
      id: service.id,
      name: service.name,
      description: service.description,
      categoryId: service.categoryId,
      categoryName: service.categoryName,
      price: service.price,
      locationRegion: service.locationRegion,
      latitude: service.latitude,
      longitude: service.longitude,
      isActive: service.isActive,
      viewCount: service.viewCount,
      likeCount: service.likeCount,
      saveCount: service.saveCount,
      overallRating: service.overallRating,
      totalReviews: service.totalReviews,
      mainImageUrl: service.images.isNotEmpty ? service.images.first.s3Url : null,
      createdAt: service.createdAt,
      updatedAt: service.updatedAt,
    );
  }
}
