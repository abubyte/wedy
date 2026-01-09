import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:wedy/apps/client/layouts/main_layout.dart';
import 'package:wedy/core/di/injection_container.dart';
import 'package:wedy/core/theme/app_colors.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/theme/app_text_styles.dart';
import 'package:wedy/features/category/domain/entities/category.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_event.dart';
import 'package:wedy/features/service/presentation/bloc/service_state.dart';
import 'package:wedy/features/category/presentation/bloc/category_bloc.dart';
import 'package:wedy/features/category/presentation/bloc/category_event.dart';
import 'package:wedy/features/category/presentation/bloc/category_state.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/circular_button.dart';
import 'package:wedy/apps/client/widgets/service_card.dart';
import 'package:wedy/apps/client/widgets/search_field.dart';

part 'widgets/search_filters_sheet.dart';
part 'widgets/search_empty_state.dart';
part 'widgets/search_initial_state.dart';
part 'widgets/category_meta_card.dart';
part 'widgets/hot_offers_meta_card.dart';

class ClientSearchPage extends StatefulWidget {
  const ClientSearchPage({super.key, this.initialQuery, this.category, this.hotOffers = false});

  final String? initialQuery;
  final ServiceCategory? category;
  final bool hotOffers;

  @override
  State<ClientSearchPage> createState() => _ClientSearchPageState();
}

class _ClientSearchPageState extends State<ClientSearchPage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();
  bool _isInitial = true;
  bool _isLoadingMore = false;
  ServiceSearchFilters _filters = ServiceSearchFilters();

  @override
  void initState() {
    super.initState();
    // Initialize filters based on widget parameters
    if (widget.hotOffers) {
      // For hot offers, we'll load featured services initially
      _filters = ServiceSearchFilters();
    } else if (widget.category != null) {
      // For category, set category filter
      _filters = ServiceSearchFilters(categoryId: widget.category!.id);
    } else if (widget.initialQuery != null) {
      // For search, set query
      _searchController.text = widget.initialQuery!;
      _filters = ServiceSearchFilters(query: widget.initialQuery);
    }

    // Load categories for filter dropdown
    context.read<CategoryBloc>().add(const LoadCategoriesEvent());

    // Perform initial load/search
    if (widget.hotOffers) {
      // Load featured services
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ServiceBloc>().add(const LoadServicesEvent(featured: true, page: 1, limit: 20));
        }
      });
    } else if (widget.category != null) {
      // Load category services
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ServiceBloc>().add(
            LoadServicesEvent(filters: ServiceSearchFilters(categoryId: widget.category!.id), page: 1, limit: 20),
          );
        }
      });
    } else if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      // Perform search if query is provided
      _performSearch();
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _isInitial = false;
    });
    // Use search controller text if available, otherwise use existing query from filters
    final searchText = _searchController.text.trim();
    final query = searchText.isNotEmpty ? searchText : _filters.query;

    // Check if any filters are applied (excluding category/hotOffers context)
    final hasActiveFilters =
        _filters.locationRegion != null ||
        _filters.minPrice != null ||
        _filters.maxPrice != null ||
        _filters.minRating != null ||
        _filters.isVerifiedMerchant != null ||
        (_filters.sortBy != null && _filters.sortBy != 'created_at') ||
        (_filters.sortOrder != null && _filters.sortOrder != 'desc');

    // If query is empty and we're in hotOffers/category mode, check if filters are applied
    if (query == null || query.isEmpty) {
      if (widget.hotOffers) {
        // If filters are applied, use them; otherwise load featured services
        if (hasActiveFilters) {
          final filters = ServiceSearchFilters(
            query: null,
            categoryId: null,
            locationRegion: _filters.locationRegion,
            minPrice: _filters.minPrice,
            maxPrice: _filters.maxPrice,
            minRating: _filters.minRating,
            isVerifiedMerchant: _filters.isVerifiedMerchant,
            sortBy: _filters.sortBy,
            sortOrder: _filters.sortOrder,
          );
          context.read<ServiceBloc>().add(LoadServicesEvent(filters: filters, page: 1, limit: 20));
        } else {
          context.read<ServiceBloc>().add(const LoadServicesEvent(featured: true, page: 1, limit: 20));
        }
        return;
      } else if (widget.category != null) {
        // If filters are applied, use them with category; otherwise load category services
        if (hasActiveFilters) {
          final filters = ServiceSearchFilters(
            query: null,
            categoryId: widget.category!.id,
            locationRegion: _filters.locationRegion,
            minPrice: _filters.minPrice,
            maxPrice: _filters.maxPrice,
            minRating: _filters.minRating,
            isVerifiedMerchant: _filters.isVerifiedMerchant,
            sortBy: _filters.sortBy,
            sortOrder: _filters.sortOrder,
          );
          context.read<ServiceBloc>().add(LoadServicesEvent(filters: filters, page: 1, limit: 20));
        } else {
          context.read<ServiceBloc>().add(
            LoadServicesEvent(filters: ServiceSearchFilters(categoryId: widget.category!.id), page: 1, limit: 20),
          );
        }
        return;
      }
    }

    // Build filters - preserve category context (but not hotOffers when searching)
    // Always prioritize widget.category.id if it exists (for category pages)
    final filters = ServiceSearchFilters(
      query: query?.isNotEmpty == true ? query : null,
      categoryId: widget.hotOffers ? null : (widget.category?.id ?? _filters.categoryId),
      locationRegion: _filters.locationRegion,
      minPrice: _filters.minPrice,
      maxPrice: _filters.maxPrice,
      minRating: _filters.minRating,
      isVerifiedMerchant: _filters.isVerifiedMerchant,
      sortBy: _filters.sortBy,
      sortOrder: _filters.sortOrder,
    );
    // Update _filters to preserve category ID for future searches
    _filters = filters;

    // Always use filters for search (even if hotOffers, search should be general)
    context.read<ServiceBloc>().add(LoadServicesEvent(filters: filters, page: 1, limit: 20));
  }

  void _onRefresh() {
    if (widget.hotOffers) {
      context.read<ServiceBloc>().add(const RefreshServicesEvent(featured: true));
    } else if (widget.category != null) {
      context.read<ServiceBloc>().add(
        RefreshServicesEvent(filters: ServiceSearchFilters(categoryId: widget.category!.id)),
      );
    } else {
      _performSearch();
    }
  }

  bool _hasActiveFilters() {
    // Check if any filters are applied (excluding default category/hotOffers context)
    // Don't count widget.category.id as a filter since it's the page context
    return _filters.locationRegion != null ||
        _filters.minPrice != null ||
        _filters.maxPrice != null ||
        _filters.minRating != null ||
        _filters.isVerifiedMerchant != null ||
        (_filters.sortBy != null && _filters.sortBy != 'created_at') ||
        (_filters.sortOrder != null && _filters.sortOrder != 'desc');
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    final state = context.read<ServiceBloc>().state;
    if (state is UniversalServicesState && state.currentPaginatedResponse?.hasMore == true) {
      _isLoadingMore = true;
      context.read<ServiceBloc>().add(const LoadMoreServicesEvent());
      // Reset flag after a delay to allow the bloc to process
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isLoadingMore = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the global ServiceBloc instance to sync state across pages
    final globalServiceBloc = context.read<ServiceBloc>();

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: globalServiceBloc),
        BlocProvider(create: (context) => getIt<CategoryBloc>()..add(const LoadCategoriesEvent())),
      ],
      child: BlocListener<ServiceBloc, ServiceState>(
        listener: (context, state) {
          // Reset loading more flag when state changes
          if (_isLoadingMore && (state is UniversalServicesState || state is ServiceError)) {
            _isLoadingMore = false;
          }

          if (!_refreshController.isRefresh) return;

          bool shouldComplete = false;
          if (state is UniversalServicesState) {
            if (widget.hotOffers) {
              shouldComplete = state.featuredServices != null;
            } else if (widget.category != null) {
              shouldComplete = state.categoryServices[widget.category!.id] != null;
            } else {
              shouldComplete = state.currentPaginatedServices != null;
            }
          }

          if (shouldComplete) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _refreshController.isRefresh) {
                _refreshController.refreshCompleted();
              }
            });
          } else if (state is ServiceError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _refreshController.isRefresh) {
                _refreshController.refreshFailed();
              }
            });
          }
        },
        child: BlocBuilder<ServiceBloc, ServiceState>(
          builder: (context, serviceState) {
            final isInitial = _isInitial && !widget.hotOffers && widget.category == null;
            // Read from UniversalServicesState based on context
            final universalState = serviceState is UniversalServicesState ? serviceState : null;

            // Get services based on context
            // If searching (query exists) or filters are applied, use currentPaginatedServices (search results)
            // Otherwise use featured/category services
            final hasSearchQuery = _searchController.text.trim().isNotEmpty;
            final hasActiveFilters = _hasActiveFilters();
            final shouldUsePaginatedServices = hasSearchQuery || hasActiveFilters;

            final services = shouldUsePaginatedServices
                ? (universalState?.currentPaginatedServices ?? <ServiceListItem>[])
                : (widget.hotOffers
                      ? (universalState?.featuredServices ?? <ServiceListItem>[])
                      : (widget.category != null
                            ? (universalState?.categoryServices[widget.category!.id] ?? <ServiceListItem>[])
                            : (universalState?.currentPaginatedServices ?? <ServiceListItem>[])));

            final paginatedResponse = universalState?.currentPaginatedResponse;
            final isLoading = serviceState is ServiceLoading || serviceState is ServiceInitial;
            final hasError = serviceState is ServiceError;
            final isEmpty = !isLoading && !hasError && services.isEmpty;

            return ClientMainLayout(
              height: services.length < 5 ? MediaQuery.of(context).size.height : null,
              refreshController: _refreshController,
              onRefresh: _onRefresh,
              refreshHeader: const ClassicHeader(
                refreshingText: 'Yangilanmoqda...',
                completeText: 'Yangilandi!',
                idleText: 'Yangilash uchun torting',
                releaseText: 'Yangilash uchun qo\'yib yuboring',
                textStyle: TextStyle(color: AppColors.primary),
              ),
              expandedHeight: 90,
              collapsedHeight: 90,
              headerContent: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const WedyCircularButton(),
                        const SizedBox(width: AppDimensions.spacingS),
                        Expanded(
                          child: ClientSearchField(
                            controller: _searchController,
                            hintText: 'Qidirish',

                            onSubmitted: (value) {
                              if (value.isNotEmpty) _performSearch();
                            },
                            trailing: _searchController.text.isEmpty
                                ? null
                                : GestureDetector(
                                    onTap: () => setState(() {
                                      _searchController.clear();
                                      // Clear query from filters when search field is cleared
                                      // Preserve category ID from widget if it exists
                                      _filters = ServiceSearchFilters(
                                        query: null,
                                        categoryId: widget.hotOffers
                                            ? null
                                            : (widget.category?.id ?? _filters.categoryId),
                                        locationRegion: _filters.locationRegion,
                                        minPrice: _filters.minPrice,
                                        maxPrice: _filters.maxPrice,
                                        minRating: _filters.minRating,
                                        isVerifiedMerchant: _filters.isVerifiedMerchant,
                                        sortBy: _filters.sortBy,
                                        sortOrder: _filters.sortOrder,
                                      );
                                      // Reload original services
                                      _onRefresh();
                                    }),
                                    child: const Icon(Icons.close, color: Colors.black, size: 20),
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        _hasActiveFilters()
                            ? WedyCircularButton(
                                icon: IconsaxPlusLinear.filter,
                                isPrimary: true,
                                onTap: () => _showFiltersBottomSheet(context),
                              )
                            : WedyCircularButton(
                                icon: IconsaxPlusLinear.filter,
                                onTap: () => _showFiltersBottomSheet(context),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
              bodyChildren: [
                // Page Title (only show when not searching and not initial)
                if (!isInitial &&
                    !isLoading &&
                    !isEmpty &&
                    serviceState is! ServiceError &&
                    _searchController.text.trim().isEmpty) ...[
                  if (widget.hotOffers)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                      child: _HotOffersMetaCard(),
                    )
                  else if (widget.category != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                      child: _CategoryMetaCard(category: widget.category),
                    ),
                  const SizedBox(height: AppDimensions.spacingM),
                ] else if (!(isInitial || isLoading || isEmpty || serviceState is ServiceError) &&
                    _searchController.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: AppDimensions.spacingL),
                    child: Text(
                      'Qidiruv natijalari:',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),

                if (isLoading)
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 300,
                    width: double.infinity,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else if (isInitial)
                  const _SearchInitialState()
                else if (serviceState is ServiceError)
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            serviceState.message,
                            style: AppTextStyles.bodyRegular.copyWith(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                          ElevatedButton(onPressed: _performSearch, child: const Text('Qayta urinish')),
                        ],
                      ),
                    ),
                  )
                else if (isEmpty)
                  const _SearchEmptyState()
                else
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        final metrics = notification.metrics;
                        if (metrics.pixels >= metrics.maxScrollExtent * 0.8) {
                          _loadMore();
                        }
                      }
                      return false;
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(AppDimensions.spacingL),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppDimensions.spacingS,
                        mainAxisSpacing: AppDimensions.spacingS,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: services.length + (paginatedResponse?.hasMore == true ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == services.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppDimensions.spacingM),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final service = services[index];
                        return SizedBox(
                          width:
                              ((MediaQuery.of(context).size.width - AppDimensions.spacingL * 2) / 2) -
                              AppDimensions.spacingL -
                              AppDimensions.spacingS,
                          child: ClientServiceCard(
                            imageUrl: service.mainImageUrl ?? '',
                            title: service.name,
                            price: service.price.toStringAsFixed(0),
                            location: service.locationRegion,
                            category: service.categoryName,
                            rating: service.overallRating,
                            onTap: () => context.push('${RouteNames.serviceDetails}?id=${service.id}'),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchFiltersSheet(
        filters: _filters,
        category: widget.category,
        hotOffers: widget.hotOffers,
        onApply: (filters) {
          setState(() {
            _filters = filters;
          });
          _performSearch();
        },
      ),
    );
  }
}
