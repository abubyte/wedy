import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wedy/core/di/injection_container.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/features/category/domain/entities/category.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_event.dart';
import 'package:wedy/features/service/presentation/bloc/service_state.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/section_header.dart';
import '../../../widgets/service_card.dart';

/// Widget that displays services for a specific category with its own ServiceBloc
class CategoryServicesSection extends StatelessWidget {
  const CategoryServicesSection({super.key, required this.category});

  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<ServiceBloc>();
        bloc.add(LoadServicesEvent(filters: ServiceSearchFilters(categoryId: category.id), page: 1, limit: 20));
        return bloc;
      },
      child: BlocBuilder<ServiceBloc, ServiceState>(
        builder: (context, state) {
          final services = state is ServicesLoaded ? state.allServices : <ServiceListItem>[];

          return Column(
            children: [
              // Section Header
              SectionHeader(
                title: category.name,
                onTap: () => context.pushNamed(RouteNames.items, extra: category),
                applyPadding: true,
              ),
              const SizedBox(height: AppDimensions.spacingS),

              // Services for this category
              if (state is ServiceLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (services.isEmpty)
                const SizedBox.shrink()
              else
                SizedBox(
                  height: 211,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, serviceIndex) {
                      final service = services[serviceIndex];
                      return SizedBox(
                        width: 150,
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
                                bloc.add(
                                  LoadServicesEvent(
                                    filters: ServiceSearchFilters(categoryId: category.id),
                                    page: 1,
                                    limit: 20,
                                  ),
                                );
                              }
                            });
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.spacingS),
                    itemCount: services.length > 3 ? 3 : services.length,
                  ),
                ),
              const SizedBox(height: AppDimensions.spacingS),
            ],
          );
        },
      ),
    );
  }
}
