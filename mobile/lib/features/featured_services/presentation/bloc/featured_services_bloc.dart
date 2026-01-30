import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/featured_service.dart';
import '../../domain/usecases/get_featured_services_tracking.dart';
import '../../domain/usecases/create_monthly_featured_service.dart';
import '../../domain/usecases/create_featured_payment.dart';
import 'featured_services_event.dart';
import 'featured_services_state.dart';

/// BLoC for managing featured services
class FeaturedServicesBloc extends Bloc<FeaturedServicesEvent, FeaturedServicesState> {
  final GetFeaturedServicesTracking _getFeaturedServicesTracking;
  final CreateMonthlyFeaturedService _createMonthlyFeaturedService;
  final CreateFeaturedPayment _createFeaturedPayment;

  FeaturedServicesBloc({
    required GetFeaturedServicesTracking getFeaturedServicesTracking,
    required CreateMonthlyFeaturedService createMonthlyFeaturedService,
    required CreateFeaturedPayment createFeaturedPayment,
  }) : _getFeaturedServicesTracking = getFeaturedServicesTracking,
       _createMonthlyFeaturedService = createMonthlyFeaturedService,
       _createFeaturedPayment = createFeaturedPayment,
       super(const FeaturedServicesInitial()) {
    on<LoadFeaturedServicesEvent>(_onLoadFeaturedServices);
    on<CreateMonthlyFeaturedServiceEvent>(_onCreateMonthlyFeaturedService);
    on<CreatePaidFeaturedServiceEvent>(_onCreatePaidFeaturedService);
    on<RefreshFeaturedServicesEvent>(_onRefreshFeaturedServices);
  }

  /// Get current data from state if available
  MerchantFeaturedServicesInfo? get _currentData {
    final currentState = state;
    if (currentState is FeaturedServicesLoaded) {
      return currentState.data;
    }
    if (currentState is FeaturedServicesLoading) {
      return currentState.previousData;
    }
    if (currentState is FeaturedServicesError) {
      return currentState.previousData;
    }
    if (currentState is FeaturedPaymentCreated) {
      return currentState.previousData;
    }
    return null;
  }

  /// Map failure to error type
  FeaturedServicesErrorType _mapFailureToErrorType(Failure failure) {
    return switch (failure) {
      NetworkFailure() => FeaturedServicesErrorType.network,
      ServerFailure() => FeaturedServicesErrorType.server,
      AuthFailure() => FeaturedServicesErrorType.auth,
      NotFoundFailure() => FeaturedServicesErrorType.notFound,
      ValidationFailure() => FeaturedServicesErrorType.noFreeSlots,
      CacheFailure() => FeaturedServicesErrorType.unknown,
    };
  }

  Future<void> _onLoadFeaturedServices(LoadFeaturedServicesEvent event, Emitter<FeaturedServicesState> emit) async {
    emit(FeaturedServicesLoading(type: FeaturedServicesLoadingType.initial, previousData: _currentData));

    final result = await _getFeaturedServicesTracking();

    result.fold(
      (failure) => emit(
        FeaturedServicesError(
          failure.toUserMessage(entityName: 'Featured services'),
          type: _mapFailureToErrorType(failure),
          previousData: _currentData,
        ),
      ),
      (data) => emit(FeaturedServicesLoaded(data)),
    );
  }

  Future<void> _onCreateMonthlyFeaturedService(
    CreateMonthlyFeaturedServiceEvent event,
    Emitter<FeaturedServicesState> emit,
  ) async {
    final previousData = _currentData;

    emit(FeaturedServicesLoading(type: FeaturedServicesLoadingType.creating, previousData: previousData));

    final result = await _createMonthlyFeaturedService(event.serviceId);

    result.fold(
      (failure) => emit(
        FeaturedServicesError(
          failure.toUserMessage(entityName: 'Featured service'),
          type: _mapFailureToErrorType(failure),
          previousData: previousData,
        ),
      ),
      (featuredService) {
        // Update state with new featured service
        final updatedFeaturedServices = [...?previousData?.featuredServices, featuredService];
        final updatedData = MerchantFeaturedServicesInfo(
          featuredServices: updatedFeaturedServices,
          total: (previousData?.total ?? 0) + 1,
          activeCount: (previousData?.activeCount ?? 0) + 1,
          remainingFreeSlots: (previousData?.remainingFreeSlots ?? 1) - 1,
        );
        emit(FeaturedServicesLoaded(updatedData, lastOperation: FeaturedServiceCreatedOperation(featuredService)));
      },
    );
  }

  Future<void> _onCreatePaidFeaturedService(
    CreatePaidFeaturedServiceEvent event,
    Emitter<FeaturedServicesState> emit,
  ) async {
    final previousData = _currentData;

    emit(FeaturedServicesLoading(type: FeaturedServicesLoadingType.creatingPayment, previousData: previousData));

    final result = await _createFeaturedPayment(
      serviceId: event.serviceId,
      durationDays: event.durationDays,
      paymentMethod: event.paymentMethod,
    );

    result.fold(
      (failure) => emit(
        FeaturedServicesError(
          failure.toUserMessage(entityName: 'Featured service payment'),
          type: _mapFailureToErrorType(failure),
          previousData: previousData,
        ),
      ),
      (payment) => emit(FeaturedPaymentCreated(payment, previousData: previousData)),
    );
  }

  Future<void> _onRefreshFeaturedServices(
    RefreshFeaturedServicesEvent event,
    Emitter<FeaturedServicesState> emit,
  ) async {
    add(const LoadFeaturedServicesEvent());
  }
}
