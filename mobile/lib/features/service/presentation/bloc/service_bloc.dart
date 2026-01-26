import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/usecases/get_services.dart';
import '../../domain/usecases/get_service_by_id.dart';
import '../../domain/usecases/interact_with_service.dart';
import '../../domain/usecases/get_saved_services.dart';
import '../../domain/usecases/get_liked_services.dart';
import '../../domain/entities/service.dart';
import 'service_event.dart';
import 'service_state.dart';

/// Service BLoC for managing service state
///
/// Uses a unified [ServicesLoaded] state that holds all service data,
/// including pagination metadata. This follows BLoC best practices by
/// keeping all state immutable and avoiding mutable private fields.
class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final GetServices _getServicesUseCase;
  final GetServiceById _getServiceByIdUseCase;
  final InteractWithService _interactWithServiceUseCase;
  final GetSavedServices _getSavedServicesUseCase;
  final GetLikedServices _getLikedServicesUseCase;

  // Track current filter settings for pagination
  bool? _currentFeatured;
  ServiceSearchFilters? _currentFilters;

  ServiceBloc({
    required GetServices getServicesUseCase,
    required GetServiceById getServiceByIdUseCase,
    required InteractWithService interactWithServiceUseCase,
    required GetSavedServices getSavedServicesUseCase,
    required GetLikedServices getLikedServicesUseCase,
  })  : _getServicesUseCase = getServicesUseCase,
        _getServiceByIdUseCase = getServiceByIdUseCase,
        _interactWithServiceUseCase = interactWithServiceUseCase,
        _getSavedServicesUseCase = getSavedServicesUseCase,
        _getLikedServicesUseCase = getLikedServicesUseCase,
        super(const ServiceInitial()) {
    on<LoadServicesEvent>(_onLoadServices);
    on<LoadMoreServicesEvent>(_onLoadMoreServices);
    on<LoadServiceByIdEvent>(_onLoadServiceById);
    on<InteractWithServiceEvent>(_onInteractWithService);
    on<RefreshServicesEvent>(_onRefreshServices);
    on<LoadSavedServicesEvent>(_onLoadSavedServices);
    on<LoadLikedServicesEvent>(_onLoadLikedServices);
  }

  /// Get current loaded state or create new one
  ServicesLoaded get _currentState => state is ServicesLoaded ? state as ServicesLoaded : const ServicesLoaded();

  /// Map failure to ServiceErrorType
  ServiceErrorType _mapFailureToErrorType(Failure failure) {
    return switch (failure) {
      NetworkFailure() => ServiceErrorType.network,
      ServerFailure() => ServiceErrorType.server,
      ValidationFailure() => ServiceErrorType.validation,
      AuthFailure() => ServiceErrorType.auth,
      NotFoundFailure() => ServiceErrorType.notFound,
      CacheFailure() => ServiceErrorType.unknown,
    };
  }

  Future<void> _onLoadServices(LoadServicesEvent event, Emitter<ServiceState> emit) async {
    // Determine load type for conditional loading indicator
    final isCategoryLoad =
        event.filters?.categoryId != null && (event.filters?.query == null || event.filters!.query!.isEmpty);
    final isFeaturedLoad = event.featured == true;

    // Only emit loading for general paginated loads (not category or featured)
    // This prevents flickering on home page where featured/category sections load
    if (!isCategoryLoad && !isFeaturedLoad) {
      emit(ServiceLoading(
        type: ServiceLoadingType.list,
        previousState: state is ServicesLoaded ? state as ServicesLoaded : null,
      ));
    }

    // Track current filter settings
    _currentFeatured = event.featured;
    _currentFilters = event.filters;

    final result = await _getServicesUseCase(
      featured: event.featured,
      filters: event.filters,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(ServiceError(
        failure.toUserMessage(entityName: 'Services'),
        type: _mapFailureToErrorType(failure),
        previousState: _currentState,
      )),
      (response) {
        final currentState = _currentState;

        if (isFeaturedLoad) {
          // Featured services load
          emit(currentState.copyWith(
            featuredServices: () => response.services,
          ));
        } else if (isCategoryLoad) {
          // Category-specific load
          final categoryId = event.filters!.categoryId!;
          final updatedCategoryServices = Map<int, List<ServiceListItem>>.from(currentState.categoryServices);
          updatedCategoryServices[categoryId] = response.services;
          emit(currentState.copyWith(categoryServices: updatedCategoryServices));
        } else {
          // General paginated services
          emit(currentState.copyWith(
            currentPaginatedResponse: () => response,
            paginatedServices: () => response.services,
            currentPage: response.page,
            hasMore: response.hasMore,
          ));
        }
      },
    );
  }

  Future<void> _onLoadMoreServices(LoadMoreServicesEvent event, Emitter<ServiceState> emit) async {
    final currentState = _currentState;

    // Guard: Don't load more if no more pages or already loading
    if (!currentState.hasMore) return;
    if (state is ServiceLoading) return;

    final nextPage = currentState.currentPage + 1;

    // Emit loading state while preserving data
    emit(ServiceLoading(
      type: ServiceLoadingType.loadMore,
      previousState: currentState,
    ));

    final result = await _getServicesUseCase(
      featured: _currentFeatured,
      filters: _currentFilters,
      page: nextPage,
      limit: 20,
    );

    result.fold(
      (failure) => emit(ServiceError(
        failure.toUserMessage(entityName: 'Services'),
        type: _mapFailureToErrorType(failure),
        previousState: currentState,
      )),
      (response) {
        final isFeaturedLoad = _currentFeatured == true;
        final isCategoryLoad = _currentFilters?.categoryId != null &&
            (_currentFilters?.query == null || _currentFilters!.query!.isEmpty);

        if (isFeaturedLoad) {
          final existing = currentState.featuredServices ?? [];
          emit(currentState.copyWith(
            featuredServices: () => [...existing, ...response.services],
            currentPage: nextPage,
            hasMore: response.hasMore,
          ));
        } else if (isCategoryLoad) {
          final categoryId = _currentFilters!.categoryId!;
          final updatedCategoryServices = Map<int, List<ServiceListItem>>.from(currentState.categoryServices);
          final existing = updatedCategoryServices[categoryId] ?? [];
          updatedCategoryServices[categoryId] = [...existing, ...response.services];
          emit(currentState.copyWith(
            categoryServices: updatedCategoryServices,
            currentPage: nextPage,
            hasMore: response.hasMore,
          ));
        } else {
          final existing = currentState.paginatedServices ?? [];
          emit(currentState.copyWith(
            currentPaginatedResponse: () => response,
            paginatedServices: () => [...existing, ...response.services],
            currentPage: response.page,
            hasMore: response.hasMore,
          ));
        }
      },
    );
  }

  Future<void> _onLoadServiceById(LoadServiceByIdEvent event, Emitter<ServiceState> emit) async {
    final currentState = _currentState;

    emit(ServiceLoading(
      type: ServiceLoadingType.details,
      previousState: currentState,
    ));

    final result = await _getServiceByIdUseCase(event.serviceId);

    result.fold(
      (failure) => emit(ServiceError(
        failure.toUserMessage(entityName: 'Service'),
        type: _mapFailureToErrorType(failure),
        previousState: currentState,
      )),
      (service) {
        emit(currentState.copyWith(currentServiceDetails: () => service));
      },
    );
  }

  Future<void> _onInteractWithService(InteractWithServiceEvent event, Emitter<ServiceState> emit) async {
    // Validate interaction type
    if (event.interactionType != 'like' && event.interactionType != 'save') {
      emit(ServiceError(
        'Invalid interaction type: ${event.interactionType}',
        type: ServiceErrorType.validation,
        previousState: _currentState,
      ));
      return;
    }

    final currentState = _currentState;

    // Start interaction tracking for optimistic UI
    var updatedState = currentState.copyWith(
      isInteracting: true,
      interactingServiceId: () => event.serviceId,
      interactionType: () => event.interactionType,
    );

    // Optimistic update using entity helpers
    updatedState = _applyOptimisticUpdate(updatedState, event.serviceId, event.interactionType);
    emit(updatedState);

    // API call
    final result = await _interactWithServiceUseCase(event.serviceId, event.interactionType);

    result.fold(
      (failure) {
        // Revert on error - restore previous state and clear interaction
        emit(currentState.clearInteraction());
        emit(ServiceError(
          failure.toUserMessage(entityName: 'Service'),
          type: _mapFailureToErrorType(failure),
          previousState: currentState,
        ));
      },
      (response) {
        // Apply actual API response and clear interaction state
        final finalState = _applyInteractionResponse(
          _currentState,
          event.serviceId,
          event.interactionType,
          response.newCount,
          response.isActive,
        );
        emit(finalState.clearInteraction());
      },
    );
  }

  /// Apply optimistic update for like/save interaction
  ServicesLoaded _applyOptimisticUpdate(ServicesLoaded currentState, String serviceId, String interactionType) {
    // Update lists using updateService helper
    var updated = currentState.updateService(serviceId, (s) {
      return interactionType == 'like' ? s.toggleLike() : s.toggleSave();
    });

    // Update service details if viewing this service
    if (currentState.currentServiceDetails?.id == serviceId) {
      final details = currentState.currentServiceDetails!;
      updated = updated.copyWith(
        currentServiceDetails: () => interactionType == 'like' ? details.toggleLike() : details.toggleSave(),
      );
    }

    // Handle liked/saved lists specially (add/remove from list)
    if (interactionType == 'like' && currentState.likedServices != null) {
      final liked = currentState.likedServices!;
      final index = liked.indexWhere((s) => s.id == serviceId);
      if (index != -1 && liked[index].isLiked) {
        // Currently liked, will be unliked - remove from list
        updated = updated.copyWith(
          likedServices: () => List.from(liked)..removeAt(index),
        );
      }
    }

    if (interactionType == 'save' && currentState.savedServices != null) {
      final saved = currentState.savedServices!;
      final index = saved.indexWhere((s) => s.id == serviceId);
      if (index != -1 && saved[index].isSaved) {
        // Currently saved, will be unsaved - remove from list
        updated = updated.copyWith(
          savedServices: () => List.from(saved)..removeAt(index),
        );
      }
    }

    return updated;
  }

  /// Apply actual API response to update counts
  ServicesLoaded _applyInteractionResponse(
    ServicesLoaded currentState,
    String serviceId,
    String interactionType,
    int newCount,
    bool isActive,
  ) {
    var updated = currentState.updateService(serviceId, (s) {
      return s.withInteractionResponse(interactionType, newCount, isActive);
    });

    // Update service details
    if (currentState.currentServiceDetails?.id == serviceId) {
      final details = currentState.currentServiceDetails!;
      updated = updated.copyWith(
        currentServiceDetails: () => details.copyWith(
          isLiked: interactionType == 'like' ? isActive : null,
          isSaved: interactionType == 'save' ? isActive : null,
          likeCount: interactionType == 'like' ? newCount : null,
          saveCount: interactionType == 'save' ? newCount : null,
        ),
      );
    }

    // Handle liked/saved lists
    if (interactionType == 'like' && currentState.likedServices != null) {
      final liked = currentState.likedServices!;
      final index = liked.indexWhere((s) => s.id == serviceId);
      if (index != -1 && !isActive) {
        updated = updated.copyWith(
          likedServices: () => List.from(liked)..removeAt(index),
        );
      } else if (index != -1) {
        updated = updated.copyWith(
          likedServices: () =>
              liked.map((s) => s.id == serviceId ? s.copyWith(isLiked: isActive, likeCount: newCount) : s).toList(),
        );
      }
    }

    if (interactionType == 'save' && currentState.savedServices != null) {
      final saved = currentState.savedServices!;
      final index = saved.indexWhere((s) => s.id == serviceId);
      if (index != -1 && !isActive) {
        updated = updated.copyWith(
          savedServices: () => List.from(saved)..removeAt(index),
        );
      } else if (index != -1) {
        updated = updated.copyWith(
          savedServices: () =>
              saved.map((s) => s.id == serviceId ? s.copyWith(isSaved: isActive, saveCount: newCount) : s).toList(),
        );
      }
    }

    return updated;
  }

  Future<void> _onRefreshServices(RefreshServicesEvent event, Emitter<ServiceState> emit) async {
    add(LoadServicesEvent(
      featured: event.featured ?? _currentFeatured,
      filters: event.filters ?? _currentFilters,
      page: 1,
      limit: 20,
    ));
  }

  Future<void> _onLoadSavedServices(LoadSavedServicesEvent event, Emitter<ServiceState> emit) async {
    final currentState = _currentState;

    emit(ServiceLoading(
      type: ServiceLoadingType.userServices,
      previousState: currentState,
    ));

    final result = await _getSavedServicesUseCase();

    result.fold(
      (failure) => emit(ServiceError(
        failure.toUserMessage(entityName: 'Saved services'),
        type: _mapFailureToErrorType(failure),
        previousState: currentState,
      )),
      (savedServices) {
        emit(currentState.copyWith(savedServices: () => savedServices));
      },
    );
  }

  Future<void> _onLoadLikedServices(LoadLikedServicesEvent event, Emitter<ServiceState> emit) async {
    final currentState = _currentState;

    emit(ServiceLoading(
      type: ServiceLoadingType.userServices,
      previousState: currentState,
    ));

    final result = await _getLikedServicesUseCase();

    result.fold(
      (failure) => emit(ServiceError(
        failure.toUserMessage(entityName: 'Liked services'),
        type: _mapFailureToErrorType(failure),
        previousState: currentState,
      )),
      (likedServices) {
        emit(currentState.copyWith(likedServices: () => likedServices));
      },
    );
  }
}
