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
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/circular_button.dart';
import 'package:wedy/apps/client/widgets/service_card.dart';
import 'package:wedy/apps/client/widgets/search_field.dart';

part 'widgets/category_meta_card.dart';
part 'widgets/hot_offers_meta_card.dart';

class ClientItemsPage extends StatefulWidget {
  const ClientItemsPage({super.key, this.hotOffers = false, this.category});

  final bool hotOffers;
  final ServiceCategory? category;

  @override
  State<ClientItemsPage> createState() => _ClientItemsPageState();
}

class _ClientItemsPageState extends State<ClientItemsPage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    final category = widget.category;
    if (widget.hotOffers) {
      context.read<ServiceBloc>().add(const RefreshServicesEvent(featured: true));
    } else if (category != null) {
      context.read<ServiceBloc>().add(RefreshServicesEvent(filters: ServiceSearchFilters(categoryId: category.id)));
    } else {
      context.read<ServiceBloc>().add(const RefreshServicesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    return BlocProvider(
      create: (context) {
        final bloc = getIt<ServiceBloc>();
        if (widget.hotOffers) {
          bloc.add(const LoadServicesEvent(featured: true, page: 1, limit: 20));
        } else if (category != null) {
          bloc.add(LoadServicesEvent(filters: ServiceSearchFilters(categoryId: category.id), page: 1, limit: 20));
        } else {
          bloc.add(const LoadServicesEvent(page: 1, limit: 20));
        }
        return bloc;
      },
      child: BlocListener<ServiceBloc, ServiceState>(
        listener: (context, state) {
          if (_refreshController.isRefresh) {
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
          }
        },
        child: BlocBuilder<ServiceBloc, ServiceState>(
          builder: (context, state) {
            final services = state is ServicesLoaded ? state.allServices : <ServiceListItem>[];
            final isLoading = state is ServiceLoading;
            final error = state is ServiceError ? state.message : null;

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
                child: Row(
                  children: [
                    const WedyCircularButton(),
                    const SizedBox(width: AppDimensions.spacingS),
                        Expanded(
                          child: ClientSearchField(
                            readOnly: true,
                            onTap: () => context.pushNamed(RouteNames.search),
                          ),
                        ),
                    const SizedBox(width: AppDimensions.spacingS),
                    const WedyCircularButton(icon: IconsaxPlusLinear.filter),
                  ],
                ),
              ),
              bodyChildren: [
                // Page Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                  child: !widget.hotOffers ? _CategoryMetaCard(category: category) : const _HotOffersMetaCard(),
                ),
                const SizedBox(height: AppDimensions.spacingM),

                // Loading state
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(AppDimensions.spacingL),
                    child: Center(child: CircularProgressIndicator()),
                  )
                // Error state
                else if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            error,
                            style: AppTextStyles.bodyRegular.copyWith(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                          ElevatedButton(
                            onPressed: () {
                              final category = widget.category;
                              if (widget.hotOffers) {
                                context.read<ServiceBloc>().add(
                                  const LoadServicesEvent(featured: true, page: 1, limit: 20),
                                );
                              } else if (category != null) {
                                context.read<ServiceBloc>().add(
                                  LoadServicesEvent(
                                    filters: ServiceSearchFilters(categoryId: category.id),
                                    page: 1,
                                    limit: 20,
                                  ),
                                );
                              } else {
                                context.read<ServiceBloc>().add(const LoadServicesEvent(page: 1, limit: 20));
                              }
                            },
                            child: const Text('Qayta urinish'),
                          ),
                        ],
                      ),
                    ),
                  )
                // Empty state
                else if (services.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(IconsaxPlusLinear.box_search, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: AppDimensions.spacingM),
                          Text(
                            widget.hotOffers ? 'Aksiyali xizmatlar topilmadi' : 'Xizmatlar topilmadi',
                            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                // Services grid
                else
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimensions.spacingL,
                      right: AppDimensions.spacingL,
                      bottom: AppDimensions.spacingL,
                    ),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppDimensions.spacingS,
                        mainAxisSpacing: AppDimensions.spacingS,
                        childAspectRatio: .8,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
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
                            isFavorite: service.isSaved,
                            onTap: () => context.push('${RouteNames.serviceDetails}?id=${service.id}'),
                            onFavoriteTap: () {
                              final bloc = context.read<ServiceBloc>();
                              bloc.add(InteractWithServiceEvent(serviceId: service.id, interactionType: 'save'));
                              // Reload services after interaction to update favorite status
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (context.mounted) {
                                  final category = widget.category;
                                  if (widget.hotOffers) {
                                    bloc.add(const LoadServicesEvent(featured: true, page: 1, limit: 20));
                                  } else if (category != null) {
                                    bloc.add(
                                      LoadServicesEvent(
                                        filters: ServiceSearchFilters(categoryId: category.id),
                                        page: 1,
                                        limit: 20,
                                      ),
                                    );
                                  } else {
                                    bloc.add(const LoadServicesEvent(page: 1, limit: 20));
                                  }
                                }
                              });
                            },
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
}
