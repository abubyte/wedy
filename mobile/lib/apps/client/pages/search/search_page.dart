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

class ClientSearchPage extends StatefulWidget {
  const ClientSearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<ClientSearchPage> createState() => _ClientSearchPageState();
}

class _ClientSearchPageState extends State<ClientSearchPage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ServiceSearchFilters _filters = ServiceSearchFilters();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _filters = ServiceSearchFilters(query: widget.initialQuery);
    }
    // Load categories for filter dropdown
    context.read<CategoryBloc>().add(const LoadCategoriesEvent());
    // Perform initial search if query is provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    final filters = ServiceSearchFilters(
      query: query.isNotEmpty ? query : null,
      categoryId: _filters.categoryId,
      locationRegion: _filters.locationRegion,
      minPrice: _filters.minPrice,
      maxPrice: _filters.maxPrice,
      minRating: _filters.minRating,
      isVerifiedMerchant: _filters.isVerifiedMerchant,
      sortBy: _filters.sortBy,
      sortOrder: _filters.sortOrder,
    );
    _filters = filters;
    context.read<ServiceBloc>().add(LoadServicesEvent(filters: filters, page: 1, limit: 20));
  }

  void _onRefresh() {
    _performSearch();
  }

  void _loadMore() {
    final state = context.read<ServiceBloc>().state;
    if (state is ServicesLoaded && state.response.hasMore) {
      context.read<ServiceBloc>().add(const LoadMoreServicesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<ServiceBloc>()),
        BlocProvider(create: (context) => getIt<CategoryBloc>()..add(const LoadCategoriesEvent())),
      ],
      child: BlocListener<ServiceBloc, ServiceState>(
        listener: (context, state) {
          if (!_refreshController.isRefresh) return;

          if (state is ServicesLoaded) {
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
            final services = serviceState is ServicesLoaded ? serviceState.allServices : <ServiceListItem>[];
            final isLoading = serviceState is ServiceLoading || serviceState is ServiceInitial;
            final hasError = serviceState is ServiceError;
            final isEmpty = !isLoading && !hasError && services.isEmpty;

            return ClientMainLayout(
              refreshController: _refreshController,
              onRefresh: _onRefresh,
              refreshHeader: const ClassicHeader(
                refreshingText: 'Yangilanmoqda...',
                completeText: 'Yangilandi!',
                idleText: 'Yangilash uchun torting',
                releaseText: 'Yangilash uchun qo\'yib yuboring',
                textStyle: TextStyle(color: AppColors.primary),
              ),
              expandedHeight: 80,
              collapsedHeight: 70,
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
                            onChanged: (value) {
                              // Debounce search could be added here
                            },
                            trailing:
                                _filters.categoryId != null ||
                                    _filters.locationRegion != null ||
                                    _filters.minPrice != null ||
                                    _filters.maxPrice != null ||
                                    _filters.minRating != null ||
                                    _filters.isVerifiedMerchant == true
                                ? GestureDetector(
                                    onTap: () => _showFiltersBottomSheet(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                                      ),
                                      child: const Icon(IconsaxPlusLinear.filter, color: Colors.white, size: 16),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () => _showFiltersBottomSheet(context),
                                    child: const Icon(IconsaxPlusLinear.filter, color: AppColors.textMuted, size: 20),
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        GestureDetector(
                          onTap: _performSearch,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                            ),
                            child: const Icon(IconsaxPlusLinear.search_normal_1, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              bodyChildren: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(AppDimensions.spacingL),
                    child: Center(child: CircularProgressIndicator()),
                  )
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
                      if (notification is ScrollEndNotification) {
                        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
                          _loadMore();
                        }
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppDimensions.spacingL),
                      itemCount:
                          services.length + (serviceState is ServicesLoaded && serviceState.response.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == services.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppDimensions.spacingM),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final service = services[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
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
