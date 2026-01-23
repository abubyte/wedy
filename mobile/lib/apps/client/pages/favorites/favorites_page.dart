import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

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
  ServiceBloc? _serviceBloc;
  bool _hasCheckedInitialLoad = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    // Refresh liked services - completion will be handled by BlocListener
    _serviceBloc?.add(const LoadLikedServicesEvent());
  }

  @override
  Widget build(BuildContext context) {
    // Use the global ServiceBloc instance to sync state across pages
    final globalBloc = context.read<ServiceBloc>();
    _serviceBloc = globalBloc;

    // Reload if state doesn't match what we need (only check once per build cycle)
    final currentState = globalBloc.state;
    final hasLikedServices = currentState is ServicesLoaded
        ? currentState.likedServices != null
        : false;

    if (!_hasCheckedInitialLoad || (!hasLikedServices && currentState is! ServiceLoading)) {
      _hasCheckedInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final state = globalBloc.state;
          final hasServices = state is ServicesLoaded
              ? state.likedServices != null
              : false;
          if (!hasServices && state is! ServiceLoading) {
            globalBloc.add(const LoadLikedServicesEvent());
          }
        }
      });
    }

    return BlocProvider.value(
      value: globalBloc,
      child: BlocListener<ServiceBloc, ServiceState>(
        listener: (context, state) {
          // Complete refresh when data is loaded or error occurs (only if refresh is active)
          if (!_refreshController.isRefresh) return;

          if (state is ServicesLoaded && state.likedServices != null) {
            if (mounted) {
              _refreshController.refreshCompleted();
            }
          } else if (state is ServiceError) {
            if (mounted) {
              _refreshController.refreshFailed();
            }
          }
        },
        child: BlocBuilder<ServiceBloc, ServiceState>(
          builder: (context, state) {
            final likedServices = state is ServicesLoaded
                ? (state.likedServices ?? <ServiceListItem>[])
                : <ServiceListItem>[];
            final isEmpty = likedServices.isEmpty && state is! ServiceLoading && state is! ServiceInitial;

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
                          SizedBox(
                            height: MediaQuery.of(context).size.height - 200,
                            width: double.infinity,
                            child: const Center(child: CircularProgressIndicator()),
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
                              itemCount: likedServices.length,
                              itemBuilder: (context, index) {
                                final service = likedServices[index];
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
                                    isFavorite: true,
                                    onTap: () => context.push('${RouteNames.serviceDetails}?id=${service.id}'),
                                    onFavoriteTap: () {
                                      // Unlike service (Instagram approach - tap to unlike)
                                      final bloc = context.read<ServiceBloc>();
                                      bloc.add(
                                        InteractWithServiceEvent(serviceId: service.id, interactionType: 'like'),
                                      );
                                      // No need to reload - bloc handles optimistic update
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
