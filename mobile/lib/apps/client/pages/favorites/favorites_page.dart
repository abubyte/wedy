import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/service/presentation/bloc/service_bloc.dart';
import '../../../../features/service/presentation/bloc/service_event.dart';
import '../../../../features/service/presentation/bloc/service_state.dart';
import '../../../../features/service/domain/entities/service.dart';
import '../../../../shared/navigation/route_names.dart';
import '../../widgets/service_card.dart';

part 'widgets/empty_state.dart';

class ClientFavoritesPage extends StatefulWidget {
  const ClientFavoritesPage({super.key});

  @override
  State<ClientFavoritesPage> createState() => _ClientFavoritesPageState();
}

class _ClientFavoritesPageState extends State<ClientFavoritesPage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    // Load saved services when page opens
    context.read<ServiceBloc>().add(const LoadSavedServicesEvent());
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    // Refresh saved services
    context.read<ServiceBloc>().add(const LoadSavedServicesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ServiceBloc>()..add(const LoadSavedServicesEvent()),
      child: BlocListener<ServiceBloc, ServiceState>(
        listener: (context, state) {
          if (!_refreshController.isRefresh) return;

          if (state is SavedServicesLoaded || state is ServiceError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _refreshController.isRefresh) {
                if (state is SavedServicesLoaded) {
                  _refreshController.refreshCompleted();
                } else {
                  _refreshController.refreshFailed();
                }
              }
            });
          }
        },
        child: BlocBuilder<ServiceBloc, ServiceState>(
          builder: (context, state) {
            final savedServices = state is SavedServicesLoaded ? state.savedServices : <ServiceListItem>[];
            final isEmpty = savedServices.isEmpty && state is! ServiceLoading && state is! ServiceInitial;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  enablePullDown: true,
                  enablePullUp: false,
                  header: const ClassicHeader(
                    refreshingText: 'Yangilanmoqda...',
                    completeText: 'Yangilandi!',
                    idleText: 'Yangilash uchun torting',
                    releaseText: 'Yangilash uchun qo\'yib yuboring',
                    textStyle: TextStyle(color: AppColors.primary),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state is ServiceLoading || state is ServiceInitial)
                          const Padding(
                            padding: EdgeInsets.all(AppDimensions.spacingL),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (!isEmpty) ...[
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(AppDimensions.spacingL),
                            child: Text('Sevimlilar', style: AppTextStyles.headline2),
                          ),

                          // Services
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
                              itemCount: savedServices.length,
                              itemBuilder: (context, index) {
                                final service = savedServices[index];
                                return SizedBox(
                                  width: ((MediaQuery.of(context).size.width - AppDimensions.spacingL * 2) / 2) -
                                      AppDimensions.spacingL -
                                      AppDimensions.spacingS,
                                  child: ClientServiceCard(
                                    imageUrl: service.mainImageUrl ?? '',
                                    title: service.name,
                                    price: service.price.toStringAsFixed(0),
                                    location: service.locationRegion,
                                    category: service.categoryName,
                                    rating: service.overallRating,
                                    isFavorite: true,
                                    onTap: () => context.push('${RouteNames.serviceDetails}?id=${service.id}'),
                                    onFavoriteTap: () {
                                      // Unsave service
                                      final bloc = context.read<ServiceBloc>();
                                      bloc.add(
                                        InteractWithServiceEvent(serviceId: service.id, interactionType: 'save'),
                                      );
                                      // Reload saved services after a delay
                                      Future.delayed(const Duration(milliseconds: 500), () {
                                        if (mounted) {
                                          bloc.add(const LoadSavedServicesEvent());
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        // Empty state
                        if (isEmpty) ...[const _FavoritesEmptyState()],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

