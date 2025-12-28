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
class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final GetServices getServicesUseCase;
  final GetServiceById getServiceByIdUseCase;
  final InteractWithService interactWithServiceUseCase;
  final GetSavedServices getSavedServicesUseCase;
  final GetLikedServices getLikedServicesUseCase;

  // Store accumulated services for pagination
  List<ServiceListItem> _accumulatedServices = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool? _currentFeatured;
  ServiceSearchFilters? _currentFilters;

  // Cache of services by ID for syncing liked/saved state across all pages
  final Map<String, ServiceListItem> _serviceCache = {};

  // Universal state that holds all service types
  UniversalServicesState _universalState = const UniversalServicesState();

  ServiceBloc({
    required this.getServicesUseCase,
    required this.getServiceByIdUseCase,
    required this.interactWithServiceUseCase,
    required this.getSavedServicesUseCase,
    required this.getLikedServicesUseCase,
  }) : super(const UniversalServicesState()) {
    on<LoadServicesEvent>(_onLoadServices);
    on<LoadMoreServicesEvent>(_onLoadMoreServices);
    on<LoadServiceByIdEvent>(_onLoadServiceById);
    on<InteractWithServiceEvent>(_onInteractWithService);
    on<RefreshServicesEvent>(_onRefreshServices);
    on<LoadSavedServicesEvent>(_onLoadSavedServices);
    on<LoadLikedServicesEvent>(_onLoadLikedServices);
  }

  Future<void> _onLoadServices(LoadServicesEvent event, Emitter<ServiceState> emit) async {
    emit(const ServiceLoading());

    // Reset accumulated services for new load
    _accumulatedServices = [];
    _currentPage = 1;
    _hasMore = true;
    _currentFeatured = event.featured;
    _currentFilters = event.filters;

    final result = await getServicesUseCase(
      featured: event.featured,
      filters: event.filters,
      page: event.page,
      limit: event.limit,
    );

    result.fold((failure) => emit(ServiceError(_getErrorMessage(failure))), (response) {
      _accumulatedServices = List.from(response.services);
      _currentPage = response.page;
      _hasMore = response.hasMore;

      // Update service cache
      for (final service in response.services) {
        _serviceCache[service.id] = service;
      }

      // Update universal state based on what was loaded
      if (event.featured == true) {
        // Featured services
        _universalState = _universalState.copyWith(featuredServices: _accumulatedServices);
      } else if (event.filters?.categoryId != null) {
        // Category services
        final categoryId = event.filters!.categoryId!;
        final updatedCategoryServices = Map<int, List<ServiceListItem>>.from(_universalState.categoryServices);
        updatedCategoryServices[categoryId] = _accumulatedServices;
        _universalState = _universalState.copyWith(categoryServices: updatedCategoryServices);
      } else {
        // General paginated services (for items/search pages)
        _universalState = _universalState.copyWith(
          currentPaginatedResponse: () => response,
          currentPaginatedServices: () => _accumulatedServices,
        );
      }

      emit(_universalState);
    });
  }

  Future<void> _onLoadMoreServices(LoadMoreServicesEvent event, Emitter<ServiceState> emit) async {
    if (!_hasMore || state is ServiceLoading) return;

    final nextPage = _currentPage + 1;

    final result = await getServicesUseCase(
      featured: _currentFeatured,
      filters: _currentFilters,
      page: nextPage,
      limit: 20,
    );

    result.fold((failure) => emit(ServiceError(_getErrorMessage(failure))), (response) {
      _accumulatedServices.addAll(response.services);
      _currentPage = response.page;
      _hasMore = response.hasMore;

      // Update service cache
      for (final service in response.services) {
        _serviceCache[service.id] = service;
      }

      emit(ServicesLoaded(response: response, allServices: _accumulatedServices));
    });
  }

  Future<void> _onLoadServiceById(LoadServiceByIdEvent event, Emitter<ServiceState> emit) async {
    emit(const ServiceLoading());

    final result = await getServiceByIdUseCase(event.serviceId);

    result.fold((failure) => emit(ServiceError(_getErrorMessage(failure))), (service) {
      // Update service cache with full service details
      // Convert Service to ServiceListItem for cache
      final serviceListItem = ServiceListItem(
        id: service.id,
        name: service.name,
        description: service.description,
        price: service.price,
        locationRegion: service.locationRegion,
        overallRating: service.overallRating,
        totalReviews: service.totalReviews,
        viewCount: service.viewCount,
        likeCount: service.likeCount,
        saveCount: service.saveCount,
        createdAt: service.createdAt,
        merchant: service.merchant,
        categoryId: service.categoryId,
        categoryName: service.categoryName,
        mainImageUrl: service.images.isNotEmpty ? service.images[0].s3Url : null,
        isFeatured: service.isFeatured,
        isLiked: service.isLiked,
        isSaved: service.isSaved,
      );
      _serviceCache[service.id] = serviceListItem;

      // Update universal state with service details
      _universalState = _universalState.copyWith(currentServiceDetails: () => service);
      emit(_universalState);
    });
  }

  Future<void> _onInteractWithService(InteractWithServiceEvent event, Emitter<ServiceState> emit) async {
    // Store current state before optimistic update
    final previousState = state;

    // Optimistic update: Update local state immediately for better UX
    _updateLocalState(event.serviceId, event.interactionType, emit);

    // Then make API call
    final result = await interactWithServiceUseCase(event.serviceId, event.interactionType);

    result.fold(
      (failure) {
        // Revert optimistic update on error - restore previous state
        emit(previousState);
        emit(ServiceError(_getErrorMessage(failure)));
      },
      (response) {
        // Update with actual response (in case counts differ)
        _updateLocalStateWithResponse(event.serviceId, event.interactionType, response, emit);

        // Note: We don't emit ServiceInteractionSuccess here because it would replace
        // the ServicesLoaded state and cause services to disappear from UI.
        // The state remains ServicesLoaded/ServiceDetailsLoaded/SavedServicesLoaded
        // with updated favorite status. If you need to show a success message,
        // you can listen to the state changes in BlocListener.
      },
    );
  }

  /// Update universal state with optimistic interaction
  void _updateUniversalState(
    String serviceId,
    String interactionType,
    UniversalServicesState currentState,
    Emitter<ServiceState> emit,
  ) {
    // Helper to update a service in a list
    List<ServiceListItem> _updateServiceInList(
      List<ServiceListItem> services,
      String serviceId,
      String interactionType,
    ) {
      return services.map((service) {
        if (service.id == serviceId) {
          return ServiceListItem(
            id: service.id,
            name: service.name,
            description: service.description,
            price: service.price,
            locationRegion: service.locationRegion,
            overallRating: service.overallRating,
            totalReviews: service.totalReviews,
            viewCount: service.viewCount,
            likeCount: interactionType == 'like'
                ? (service.isLiked ? service.likeCount - 1 : service.likeCount + 1)
                : service.likeCount,
            saveCount: interactionType == 'save'
                ? (service.isSaved ? service.saveCount - 1 : service.saveCount + 1)
                : service.saveCount,
            createdAt: service.createdAt,
            merchant: service.merchant,
            categoryId: service.categoryId,
            categoryName: service.categoryName,
            mainImageUrl: service.mainImageUrl,
            isFeatured: service.isFeatured,
            isLiked: interactionType == 'like' ? !service.isLiked : service.isLiked,
            isSaved: interactionType == 'save' ? !service.isSaved : service.isSaved,
          );
        }
        return service;
      }).toList();
    }

    // Update featured services
    List<ServiceListItem>? updatedFeatured = currentState.featuredServices;
    if (updatedFeatured != null) {
      updatedFeatured = _updateServiceInList(updatedFeatured, serviceId, interactionType);
    }

    // Update category services
    Map<int, List<ServiceListItem>> updatedCategoryServices = {};
    currentState.categoryServices.forEach((categoryId, services) {
      updatedCategoryServices[categoryId] = _updateServiceInList(services, serviceId, interactionType);
    });

    // Update liked services
    List<ServiceListItem>? updatedLiked = currentState.likedServices;
    if (interactionType == 'like') {
      // Get the updated service from cache (it was already updated optimistically)
      ServiceListItem? updatedService = _serviceCache[serviceId];

      // If not in cache, try to find it from other lists and update cache
      if (updatedService == null) {
        // Try featured services
        if (currentState.featuredServices != null) {
          try {
            final service = currentState.featuredServices!.firstWhere((s) => s.id == serviceId);
            // Update it with new liked state
            updatedService = ServiceListItem(
              id: service.id,
              name: service.name,
              description: service.description,
              price: service.price,
              locationRegion: service.locationRegion,
              overallRating: service.overallRating,
              totalReviews: service.totalReviews,
              viewCount: service.viewCount,
              likeCount: service.isLiked ? service.likeCount - 1 : service.likeCount + 1,
              saveCount: service.saveCount,
              createdAt: service.createdAt,
              merchant: service.merchant,
              categoryId: service.categoryId,
              categoryName: service.categoryName,
              mainImageUrl: service.mainImageUrl,
              isFeatured: service.isFeatured,
              isLiked: !service.isLiked,
              isSaved: service.isSaved,
            );
            _serviceCache[serviceId] = updatedService;
          } catch (_) {
            // Not found in featured
          }
        }

        // Try category services
        if (updatedService == null) {
          for (final services in currentState.categoryServices.values) {
            try {
              final service = services.firstWhere((s) => s.id == serviceId);
              // Update it with new liked state
              updatedService = ServiceListItem(
                id: service.id,
                name: service.name,
                description: service.description,
                price: service.price,
                locationRegion: service.locationRegion,
                overallRating: service.overallRating,
                totalReviews: service.totalReviews,
                viewCount: service.viewCount,
                likeCount: service.isLiked ? service.likeCount - 1 : service.likeCount + 1,
                saveCount: service.saveCount,
                createdAt: service.createdAt,
                merchant: service.merchant,
                categoryId: service.categoryId,
                categoryName: service.categoryName,
                mainImageUrl: service.mainImageUrl,
                isFeatured: service.isFeatured,
                isLiked: !service.isLiked,
                isSaved: service.isSaved,
              );
              _serviceCache[serviceId] = updatedService;
              break;
            } catch (_) {
              // Not found in this category, continue
            }
          }
        }

        // Try paginated services
        if (updatedService == null && currentState.currentPaginatedServices != null) {
          try {
            final service = currentState.currentPaginatedServices!.firstWhere((s) => s.id == serviceId);
            // Update it with new liked state
            updatedService = ServiceListItem(
              id: service.id,
              name: service.name,
              description: service.description,
              price: service.price,
              locationRegion: service.locationRegion,
              overallRating: service.overallRating,
              totalReviews: service.totalReviews,
              viewCount: service.viewCount,
              likeCount: service.isLiked ? service.likeCount - 1 : service.likeCount + 1,
              saveCount: service.saveCount,
              createdAt: service.createdAt,
              merchant: service.merchant,
              categoryId: service.categoryId,
              categoryName: service.categoryName,
              mainImageUrl: service.mainImageUrl,
              isFeatured: service.isFeatured,
              isLiked: !service.isLiked,
              isSaved: service.isSaved,
            );
            _serviceCache[serviceId] = updatedService;
          } catch (_) {
            // Not found
          }
        }
      }

      // Now update the liked services list based on the updated service
      if (updatedService != null) {
        if (updatedLiked != null) {
          final serviceIndex = updatedLiked.indexWhere((s) => s.id == serviceId);
          if (serviceIndex != -1) {
            // Service is already in liked list
            if (updatedService.isLiked) {
              // Update existing entry with new liked state
              updatedLiked = updatedLiked.map((s) => s.id == serviceId ? updatedService! : s).toList();
            } else {
              // Remove from liked list (unlike)
              updatedLiked = List<ServiceListItem>.from(updatedLiked)..removeAt(serviceIndex);
            }
          } else if (updatedService.isLiked) {
            // Service is not in liked list but is now liked - add it
            updatedLiked = List<ServiceListItem>.from(updatedLiked)..add(updatedService);
          }
        } else if (updatedService.isLiked) {
          // Liked services list doesn't exist yet, create it with this service
          updatedLiked = [updatedService];
        }
      }
    }

    // Update saved services
    List<ServiceListItem>? updatedSaved = currentState.savedServices;
    if (updatedSaved != null && interactionType == 'save') {
      final serviceIndex = updatedSaved.indexWhere((s) => s.id == serviceId);
      if (serviceIndex != -1) {
        final service = updatedSaved[serviceIndex];
        if (service.isSaved) {
          // Remove from saved list
          updatedSaved = List<ServiceListItem>.from(updatedSaved)..removeAt(serviceIndex);
        } else {
          // Add to saved list (shouldn't happen often)
          final newService = ServiceListItem(
            id: service.id,
            name: service.name,
            description: service.description,
            price: service.price,
            locationRegion: service.locationRegion,
            overallRating: service.overallRating,
            totalReviews: service.totalReviews,
            viewCount: service.viewCount,
            likeCount: service.likeCount,
            saveCount: service.saveCount + 1,
            createdAt: service.createdAt,
            merchant: service.merchant,
            categoryId: service.categoryId,
            categoryName: service.categoryName,
            mainImageUrl: service.mainImageUrl,
            isFeatured: service.isFeatured,
            isLiked: service.isLiked,
            isSaved: true,
          );
          updatedSaved = List<ServiceListItem>.from(updatedSaved)..add(newService);
        }
      }
    }

    // Update current service details
    Service? updatedServiceDetails = currentState.currentServiceDetails;
    if (updatedServiceDetails != null && updatedServiceDetails.id == serviceId) {
      updatedServiceDetails = Service(
        id: updatedServiceDetails.id,
        name: updatedServiceDetails.name,
        description: updatedServiceDetails.description,
        price: updatedServiceDetails.price,
        locationRegion: updatedServiceDetails.locationRegion,
        latitude: updatedServiceDetails.latitude,
        longitude: updatedServiceDetails.longitude,
        viewCount: updatedServiceDetails.viewCount,
        likeCount: interactionType == 'like'
            ? (updatedServiceDetails.isLiked
                  ? updatedServiceDetails.likeCount - 1
                  : updatedServiceDetails.likeCount + 1)
            : updatedServiceDetails.likeCount,
        saveCount: interactionType == 'save'
            ? (updatedServiceDetails.isSaved
                  ? updatedServiceDetails.saveCount - 1
                  : updatedServiceDetails.saveCount + 1)
            : updatedServiceDetails.saveCount,
        shareCount: updatedServiceDetails.shareCount,
        overallRating: updatedServiceDetails.overallRating,
        totalReviews: updatedServiceDetails.totalReviews,
        isActive: updatedServiceDetails.isActive,
        createdAt: updatedServiceDetails.createdAt,
        updatedAt: updatedServiceDetails.updatedAt,
        merchant: updatedServiceDetails.merchant,
        categoryId: updatedServiceDetails.categoryId,
        categoryName: updatedServiceDetails.categoryName,
        images: updatedServiceDetails.images,
        isFeatured: updatedServiceDetails.isFeatured,
        featuredUntil: updatedServiceDetails.featuredUntil,
        isLiked: interactionType == 'like' ? !updatedServiceDetails.isLiked : updatedServiceDetails.isLiked,
        isSaved: interactionType == 'save' ? !updatedServiceDetails.isSaved : updatedServiceDetails.isSaved,
      );
    }

    // Update current paginated services
    List<ServiceListItem>? updatedPaginated = currentState.currentPaginatedServices;
    if (updatedPaginated != null) {
      updatedPaginated = _updateServiceInList(updatedPaginated, serviceId, interactionType);
    }

    // Emit updated universal state
    _universalState = UniversalServicesState(
      featuredServices: updatedFeatured,
      categoryServices: updatedCategoryServices,
      likedServices: updatedLiked,
      savedServices: updatedSaved,
      currentServiceDetails: updatedServiceDetails,
      currentPaginatedResponse: currentState.currentPaginatedResponse,
      currentPaginatedServices: updatedPaginated,
    );
    emit(_universalState);
  }

  /// Update universal state with actual API response
  void _updateUniversalStateWithResponse(
    String serviceId,
    String interactionType,
    dynamic response,
    UniversalServicesState currentState,
    Emitter<ServiceState> emit,
  ) {
    // Helper to update a service in a list with actual response
    List<ServiceListItem> _updateServiceInListWithResponse(
      List<ServiceListItem> services,
      String serviceId,
      String interactionType,
      dynamic response,
    ) {
      return services.map((service) {
        if (service.id == serviceId) {
          return ServiceListItem(
            id: service.id,
            name: service.name,
            description: service.description,
            price: service.price,
            locationRegion: service.locationRegion,
            overallRating: service.overallRating,
            totalReviews: service.totalReviews,
            viewCount: service.viewCount,
            likeCount: interactionType == 'like' ? response.newCount : service.likeCount,
            saveCount: interactionType == 'save' ? response.newCount : service.saveCount,
            createdAt: service.createdAt,
            merchant: service.merchant,
            categoryId: service.categoryId,
            categoryName: service.categoryName,
            mainImageUrl: service.mainImageUrl,
            isFeatured: service.isFeatured,
            isLiked: interactionType == 'like' ? response.isActive : service.isLiked,
            isSaved: interactionType == 'save' ? response.isActive : service.isSaved,
          );
        }
        return service;
      }).toList();
    }

    // Update featured services
    List<ServiceListItem>? updatedFeatured = currentState.featuredServices;
    if (updatedFeatured != null) {
      updatedFeatured = _updateServiceInListWithResponse(updatedFeatured, serviceId, interactionType, response);
    }

    // Update category services
    Map<int, List<ServiceListItem>> updatedCategoryServices = {};
    currentState.categoryServices.forEach((categoryId, services) {
      updatedCategoryServices[categoryId] = _updateServiceInListWithResponse(
        services,
        serviceId,
        interactionType,
        response,
      );
    });

    // Update liked services
    List<ServiceListItem>? updatedLiked = currentState.likedServices;
    if (updatedLiked != null && interactionType == 'like') {
      final serviceIndex = updatedLiked.indexWhere((s) => s.id == serviceId);
      if (serviceIndex != -1) {
        final service = updatedLiked[serviceIndex];
        if (!response.isActive) {
          // Remove from liked list if no longer liked
          updatedLiked = List<ServiceListItem>.from(updatedLiked)..removeAt(serviceIndex);
        } else {
          // Update with actual counts
          updatedLiked = updatedLiked.map((s) {
            if (s.id == serviceId) {
              return ServiceListItem(
                id: s.id,
                name: s.name,
                description: s.description,
                price: s.price,
                locationRegion: s.locationRegion,
                overallRating: s.overallRating,
                totalReviews: s.totalReviews,
                viewCount: s.viewCount,
                likeCount: response.newCount,
                saveCount: s.saveCount,
                createdAt: s.createdAt,
                merchant: s.merchant,
                categoryId: s.categoryId,
                categoryName: s.categoryName,
                mainImageUrl: s.mainImageUrl,
                isFeatured: s.isFeatured,
                isLiked: response.isActive,
                isSaved: s.isSaved,
              );
            }
            return s;
          }).toList();
        }
      }
    }

    // Update saved services
    List<ServiceListItem>? updatedSaved = currentState.savedServices;
    if (updatedSaved != null && interactionType == 'save') {
      final serviceIndex = updatedSaved.indexWhere((s) => s.id == serviceId);
      if (serviceIndex != -1) {
        final service = updatedSaved[serviceIndex];
        if (!response.isActive) {
          // Remove from saved list if no longer saved
          updatedSaved = List<ServiceListItem>.from(updatedSaved)..removeAt(serviceIndex);
        } else {
          // Update with actual counts
          updatedSaved = updatedSaved.map((s) {
            if (s.id == serviceId) {
              return ServiceListItem(
                id: s.id,
                name: s.name,
                description: s.description,
                price: s.price,
                locationRegion: s.locationRegion,
                overallRating: s.overallRating,
                totalReviews: s.totalReviews,
                viewCount: s.viewCount,
                likeCount: s.likeCount,
                saveCount: response.newCount,
                createdAt: s.createdAt,
                merchant: s.merchant,
                categoryId: s.categoryId,
                categoryName: s.categoryName,
                mainImageUrl: s.mainImageUrl,
                isFeatured: s.isFeatured,
                isLiked: s.isLiked,
                isSaved: response.isActive,
              );
            }
            return s;
          }).toList();
        }
      }
    }

    // Update current service details
    Service? updatedServiceDetails = currentState.currentServiceDetails;
    if (updatedServiceDetails != null && updatedServiceDetails.id == serviceId) {
      updatedServiceDetails = Service(
        id: updatedServiceDetails.id,
        name: updatedServiceDetails.name,
        description: updatedServiceDetails.description,
        price: updatedServiceDetails.price,
        locationRegion: updatedServiceDetails.locationRegion,
        latitude: updatedServiceDetails.latitude,
        longitude: updatedServiceDetails.longitude,
        viewCount: updatedServiceDetails.viewCount,
        likeCount: interactionType == 'like' ? response.newCount : updatedServiceDetails.likeCount,
        saveCount: interactionType == 'save' ? response.newCount : updatedServiceDetails.saveCount,
        shareCount: updatedServiceDetails.shareCount,
        overallRating: updatedServiceDetails.overallRating,
        totalReviews: updatedServiceDetails.totalReviews,
        isActive: updatedServiceDetails.isActive,
        createdAt: updatedServiceDetails.createdAt,
        updatedAt: updatedServiceDetails.updatedAt,
        merchant: updatedServiceDetails.merchant,
        categoryId: updatedServiceDetails.categoryId,
        categoryName: updatedServiceDetails.categoryName,
        images: updatedServiceDetails.images,
        isFeatured: updatedServiceDetails.isFeatured,
        featuredUntil: updatedServiceDetails.featuredUntil,
        isLiked: interactionType == 'like' ? response.isActive : updatedServiceDetails.isLiked,
        isSaved: interactionType == 'save' ? response.isActive : updatedServiceDetails.isSaved,
      );
    }

    // Update current paginated services
    List<ServiceListItem>? updatedPaginated = currentState.currentPaginatedServices;
    if (updatedPaginated != null) {
      updatedPaginated = _updateServiceInListWithResponse(updatedPaginated, serviceId, interactionType, response);
    }

    // Emit updated universal state
    _universalState = UniversalServicesState(
      featuredServices: updatedFeatured,
      categoryServices: updatedCategoryServices,
      likedServices: updatedLiked,
      savedServices: updatedSaved,
      currentServiceDetails: updatedServiceDetails,
      currentPaginatedResponse: currentState.currentPaginatedResponse,
      currentPaginatedServices: updatedPaginated,
    );
    emit(_universalState);
  }

  /// Helper method to update a service in the cache
  ServiceListItem? _updateServiceInCache(String serviceId, String interactionType) {
    final cachedService = _serviceCache[serviceId];
    if (cachedService == null) return null;

    return ServiceListItem(
      id: cachedService.id,
      name: cachedService.name,
      description: cachedService.description,
      price: cachedService.price,
      locationRegion: cachedService.locationRegion,
      overallRating: cachedService.overallRating,
      totalReviews: cachedService.totalReviews,
      viewCount: cachedService.viewCount,
      likeCount: interactionType == 'like'
          ? (cachedService.isLiked ? cachedService.likeCount - 1 : cachedService.likeCount + 1)
          : cachedService.likeCount,
      saveCount: interactionType == 'save'
          ? (cachedService.isSaved ? cachedService.saveCount - 1 : cachedService.saveCount + 1)
          : cachedService.saveCount,
      createdAt: cachedService.createdAt,
      merchant: cachedService.merchant,
      categoryId: cachedService.categoryId,
      categoryName: cachedService.categoryName,
      mainImageUrl: cachedService.mainImageUrl,
      isFeatured: cachedService.isFeatured,
      isLiked: interactionType == 'like' ? !cachedService.isLiked : cachedService.isLiked,
      isSaved: interactionType == 'save' ? !cachedService.isSaved : cachedService.isSaved,
    );
  }

  /// Optimistically update local state before API call
  void _updateLocalState(String serviceId, String interactionType, Emitter<ServiceState> emit) {
    if (interactionType != 'save' && interactionType != 'like') return;

    // Update service in cache first
    final updatedCachedService = _updateServiceInCache(serviceId, interactionType);
    if (updatedCachedService != null) {
      _serviceCache[serviceId] = updatedCachedService;
    }

    final currentState = state;

    // Update UniversalServicesState
    if (currentState is UniversalServicesState) {
      _updateUniversalState(serviceId, interactionType, currentState, emit);
      return;
    }

    // Legacy support for old states (for backward compatibility during migration)
    if (currentState is ServicesLoaded) {
      final updatedServices = currentState.allServices.map((service) {
        if (service.id == serviceId) {
          return ServiceListItem(
            id: service.id,
            name: service.name,
            description: service.description,
            price: service.price,
            locationRegion: service.locationRegion,
            overallRating: service.overallRating,
            totalReviews: service.totalReviews,
            viewCount: service.viewCount,
            likeCount: interactionType == 'like'
                ? (service.isLiked ? service.likeCount - 1 : service.likeCount + 1)
                : service.likeCount,
            saveCount: interactionType == 'save'
                ? (service.isSaved ? service.saveCount - 1 : service.saveCount + 1)
                : service.saveCount,
            createdAt: service.createdAt,
            merchant: service.merchant,
            categoryId: service.categoryId,
            categoryName: service.categoryName,
            mainImageUrl: service.mainImageUrl,
            isFeatured: service.isFeatured,
            isLiked: interactionType == 'like' ? !service.isLiked : service.isLiked,
            isSaved: interactionType == 'save' ? !service.isSaved : service.isSaved,
          );
        }
        return service;
      }).toList();

      _accumulatedServices = updatedServices;
      emit(ServicesLoaded(response: currentState.response, allServices: updatedServices));
    }

    // Update ServiceDetailsLoaded state
    if (currentState is ServiceDetailsLoaded) {
      final service = currentState.service;
      if (service.id == serviceId) {
        final updatedService = Service(
          id: service.id,
          name: service.name,
          description: service.description,
          price: service.price,
          locationRegion: service.locationRegion,
          latitude: service.latitude,
          longitude: service.longitude,
          viewCount: service.viewCount,
          likeCount: interactionType == 'like'
              ? (service.isLiked ? service.likeCount - 1 : service.likeCount + 1)
              : service.likeCount,
          saveCount: interactionType == 'save'
              ? (service.isSaved ? service.saveCount - 1 : service.saveCount + 1)
              : service.saveCount,
          shareCount: service.shareCount,
          overallRating: service.overallRating,
          totalReviews: service.totalReviews,
          isActive: service.isActive,
          createdAt: service.createdAt,
          updatedAt: service.updatedAt,
          merchant: service.merchant,
          categoryId: service.categoryId,
          categoryName: service.categoryName,
          images: service.images,
          isFeatured: service.isFeatured,
          featuredUntil: service.featuredUntil,
          isLiked: interactionType == 'like' ? !service.isLiked : service.isLiked,
          isSaved: interactionType == 'save' ? !service.isSaved : service.isSaved,
        );
        emit(ServiceDetailsLoaded(updatedService));
      }
    }

    // Update SavedServicesLoaded state (for save interactions)
    if (currentState is SavedServicesLoaded && interactionType == 'save') {
      final savedServices = currentState.savedServices;
      final serviceIndex = savedServices.indexWhere((s) => s.id == serviceId);

      if (serviceIndex != -1) {
        final service = savedServices[serviceIndex];
        // If service is currently saved, remove it from list
        if (service.isSaved) {
          final updatedServices = List<ServiceListItem>.from(savedServices)..removeAt(serviceIndex);
          emit(SavedServicesLoaded(updatedServices));
        } else {
          // If service is not saved, add it to list (shouldn't happen often)
          final updatedService = ServiceListItem(
            id: service.id,
            name: service.name,
            description: service.description,
            price: service.price,
            locationRegion: service.locationRegion,
            overallRating: service.overallRating,
            totalReviews: service.totalReviews,
            viewCount: service.viewCount,
            likeCount: service.likeCount,
            saveCount: service.saveCount + 1,
            createdAt: service.createdAt,
            merchant: service.merchant,
            categoryId: service.categoryId,
            categoryName: service.categoryName,
            mainImageUrl: service.mainImageUrl,
            isFeatured: service.isFeatured,
            isLiked: service.isLiked,
            isSaved: true,
          );
          final updatedServices = List<ServiceListItem>.from(savedServices)..add(updatedService);
          emit(SavedServicesLoaded(updatedServices));
        }
      }
    }

    // Update LikedServicesLoaded state (for like interactions)
    if (currentState is LikedServicesLoaded && interactionType == 'like') {
      final likedServices = currentState.likedServices;
      final serviceIndex = likedServices.indexWhere((s) => s.id == serviceId);

      if (serviceIndex != -1) {
        final service = likedServices[serviceIndex];
        // If service is currently liked, remove it from list
        if (service.isLiked) {
          final updatedServices = List<ServiceListItem>.from(likedServices)..removeAt(serviceIndex);
          emit(LikedServicesLoaded(updatedServices));
        } else {
          // If service is not liked, add it to list (shouldn't happen often)
          final updatedService = ServiceListItem(
            id: service.id,
            name: service.name,
            description: service.description,
            price: service.price,
            locationRegion: service.locationRegion,
            overallRating: service.overallRating,
            totalReviews: service.totalReviews,
            viewCount: service.viewCount,
            likeCount: service.likeCount + 1,
            saveCount: service.saveCount,
            createdAt: service.createdAt,
            merchant: service.merchant,
            categoryId: service.categoryId,
            categoryName: service.categoryName,
            mainImageUrl: service.mainImageUrl,
            isFeatured: service.isFeatured,
            isLiked: true,
            isSaved: service.isSaved,
          );
          final updatedServices = List<ServiceListItem>.from(likedServices)..add(updatedService);
          emit(LikedServicesLoaded(updatedServices));
        }
      }
    }
  }

  /// Revert optimistic update on error
  // ignore: unused_element
  void _revertLocalState(String serviceId, String interactionType, Emitter<ServiceState> emit) {
    // Simply reload the current state to revert
    final currentState = state;
    if (currentState is ServicesLoaded) {
      // Reload services to get correct state
      add(LoadServicesEvent(featured: _currentFeatured, filters: _currentFilters, page: _currentPage, limit: 20));
    } else if (currentState is ServiceDetailsLoaded) {
      add(LoadServiceByIdEvent(serviceId));
    } else if (currentState is SavedServicesLoaded) {
      add(const LoadSavedServicesEvent());
    }
  }

  /// Update local state with actual API response
  void _updateLocalStateWithResponse(
    String serviceId,
    String interactionType,
    dynamic response,
    Emitter<ServiceState> emit,
  ) {
    // Update service in cache with actual response
    final cachedService = _serviceCache[serviceId];
    if (cachedService != null) {
      final updatedService = ServiceListItem(
        id: cachedService.id,
        name: cachedService.name,
        description: cachedService.description,
        price: cachedService.price,
        locationRegion: cachedService.locationRegion,
        overallRating: cachedService.overallRating,
        totalReviews: cachedService.totalReviews,
        viewCount: cachedService.viewCount,
        likeCount: interactionType == 'like' ? response.newCount : cachedService.likeCount,
        saveCount: interactionType == 'save' ? response.newCount : cachedService.saveCount,
        createdAt: cachedService.createdAt,
        merchant: cachedService.merchant,
        categoryId: cachedService.categoryId,
        categoryName: cachedService.categoryName,
        mainImageUrl: cachedService.mainImageUrl,
        isFeatured: cachedService.isFeatured,
        isLiked: interactionType == 'like' ? response.isActive : cachedService.isLiked,
        isSaved: interactionType == 'save' ? response.isActive : cachedService.isSaved,
      );
      _serviceCache[serviceId] = updatedService;
    }

    final currentState = state;

    // Update UniversalServicesState with actual response
    if (currentState is UniversalServicesState) {
      _updateUniversalStateWithResponse(serviceId, interactionType, response, currentState, emit);
      return;
    }

    // Update ServicesLoaded state with actual counts
    if (currentState is ServicesLoaded) {
      final updatedServices = currentState.allServices.map((service) {
        if (service.id == serviceId) {
          return ServiceListItem(
            id: service.id,
            name: service.name,
            description: service.description,
            price: service.price,
            locationRegion: service.locationRegion,
            overallRating: service.overallRating,
            totalReviews: service.totalReviews,
            viewCount: service.viewCount,
            likeCount: interactionType == 'like' ? response.newCount : service.likeCount,
            saveCount: interactionType == 'save' ? response.newCount : service.saveCount,
            createdAt: service.createdAt,
            merchant: service.merchant,
            categoryId: service.categoryId,
            categoryName: service.categoryName,
            mainImageUrl: service.mainImageUrl,
            isFeatured: service.isFeatured,
            isLiked: interactionType == 'like' ? response.isActive : service.isLiked,
            isSaved: interactionType == 'save' ? response.isActive : service.isSaved,
          );
        }
        return service;
      }).toList();

      _accumulatedServices = updatedServices;
      emit(ServicesLoaded(response: currentState.response, allServices: updatedServices));
    }

    // Update ServiceDetailsLoaded state with actual counts
    if (currentState is ServiceDetailsLoaded) {
      final service = currentState.service;
      if (service.id == serviceId) {
        final updatedService = Service(
          id: service.id,
          name: service.name,
          description: service.description,
          price: service.price,
          locationRegion: service.locationRegion,
          latitude: service.latitude,
          longitude: service.longitude,
          viewCount: service.viewCount,
          likeCount: interactionType == 'like' ? response.newCount : service.likeCount,
          saveCount: interactionType == 'save' ? response.newCount : service.saveCount,
          shareCount: service.shareCount,
          overallRating: service.overallRating,
          totalReviews: service.totalReviews,
          isActive: service.isActive,
          createdAt: service.createdAt,
          updatedAt: service.updatedAt,
          merchant: service.merchant,
          categoryId: service.categoryId,
          categoryName: service.categoryName,
          images: service.images,
          isFeatured: service.isFeatured,
          featuredUntil: service.featuredUntil,
          isLiked: interactionType == 'like' ? response.isActive : service.isLiked,
          isSaved: interactionType == 'save' ? response.isActive : service.isSaved,
        );
        emit(ServiceDetailsLoaded(updatedService));
      }
    }
  }

  Future<void> _onRefreshServices(RefreshServicesEvent event, Emitter<ServiceState> emit) async {
    // Reset and reload
    add(
      LoadServicesEvent(
        featured: event.featured ?? _currentFeatured,
        filters: event.filters ?? _currentFilters,
        page: 1,
        limit: 20,
      ),
    );
  }

  Future<void> _onLoadSavedServices(LoadSavedServicesEvent event, Emitter<ServiceState> emit) async {
    emit(const ServiceLoading());

    final result = await getSavedServicesUseCase();

    result.fold((failure) => emit(ServiceError(_getErrorMessage(failure))), (savedServices) {
      // Update service cache
      for (final service in savedServices) {
        _serviceCache[service.id] = service;
      }
      // Update universal state
      _universalState = _universalState.copyWith(savedServices: () => savedServices);
      emit(_universalState);
    });
  }

  Future<void> _onLoadLikedServices(LoadLikedServicesEvent event, Emitter<ServiceState> emit) async {
    emit(const ServiceLoading());

    final result = await getLikedServicesUseCase();

    result.fold((failure) => emit(ServiceError(_getErrorMessage(failure))), (likedServices) {
      // Update service cache
      for (final service in likedServices) {
        _serviceCache[service.id] = service;
      }
      // Update universal state
      _universalState = _universalState.copyWith(likedServices: () => likedServices);
      emit(_universalState);
    });
  }

  String _getErrorMessage(dynamic failure) {
    if (failure is NetworkFailure) {
      return 'Network error. Please check your internet connection.';
    } else if (failure is ServerFailure) {
      return 'Server error. Please try again later.';
    } else if (failure is NotFoundFailure) {
      return 'Service not found.';
    } else if (failure is AuthFailure) {
      return 'Authentication failed. Please login again.';
    } else if (failure is ValidationFailure) {
      return failure.message;
    }
    return 'An unexpected error occurred.';
  }
}
