import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/core/utils/shimmer_helper.dart';
import 'package:wedy/features/category/domain/entities/category.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_event.dart';
import 'package:wedy/features/service/presentation/bloc/service_state.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'package:wedy/shared/navigation/route_names.dart';
import 'package:wedy/shared/widgets/section_header.dart';
import '../../../widgets/service_card.dart';

/// Widget that displays services for a specific category with its own ServiceBloc
class CategoryServicesSection extends StatefulWidget {
  const CategoryServicesSection({super.key, required this.category, this.isLoading = false});

  final ServiceCategory category;
  final bool isLoading;

  @override
  State<CategoryServicesSection> createState() => _CategoryServicesSectionState();
}

class _CategoryServicesSectionState extends State<CategoryServicesSection> {
  List<ServiceListItem> _cachedServices = [];
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    // Load services for this category immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoaded) {
        _loadCategoryServices();
      }
    });
  }

  @override
  void didUpdateWidget(CategoryServicesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if category changed
    if (oldWidget.category.id != widget.category.id) {
      _hasLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadCategoryServices();
        }
      });
    }
  }

  void _loadCategoryServices() {
    if (_hasLoaded) return;

    final globalBloc = context.read<ServiceBloc>();
    globalBloc.add(
      LoadServicesEvent(filters: ServiceSearchFilters(categoryId: widget.category.id), page: 1, limit: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the global ServiceBloc instance to sync state across pages
    final globalBloc = context.read<ServiceBloc>();

    return BlocProvider.value(
      value: globalBloc,
      child: BlocListener<ServiceBloc, ServiceState>(
        listenWhen: (previous, current) {
          // Listen when services are loaded for this category
          return current is UniversalServicesState || current is ServicesLoaded;
        },
        listener: (context, state) {
          List<ServiceListItem>? categoryServices;
          if (state is UniversalServicesState) {
            categoryServices = state.categoryServices[widget.category.id];
          } else if (state is ServicesLoaded) {
            categoryServices = state.allServices.where((s) => s.categoryId == widget.category.id).toList();
          }

          if (categoryServices != null && categoryServices.isNotEmpty) {
            setState(() {
              _cachedServices = categoryServices!;
              _hasLoaded = true;
            });
          }
        },
        child: BlocBuilder<ServiceBloc, ServiceState>(
          builder: (context, state) {
            // Use cached services, but sync liked state from current state if available
            List<ServiceListItem> services = _cachedServices;

            // Sync liked state from current state (for optimistic updates)
            List<ServiceListItem>? stateServices;
            if (state is UniversalServicesState) {
              stateServices = state.categoryServices[widget.category.id];
            } else if (state is ServicesLoaded) {
              stateServices = state.allServices.where((s) => s.categoryId == widget.category.id).toList();
            }

            if (stateServices != null && stateServices.isNotEmpty) {
              // Update cache with latest liked state
              final serviceMap = {for (var s in stateServices) s.id: s};
              final updatedServices = _cachedServices.map((service) {
                final updated = serviceMap[service.id];
                return updated ?? service;
              }).toList();
              if (updatedServices != _cachedServices) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _cachedServices = updatedServices;
                    });
                  }
                });
                services = updatedServices;
              }
            }

            return Column(
              children: [
                // Section Header
                SectionHeader(
                  title: widget.category.name,
                  onTap: () => context.pushNamed(RouteNames.items, extra: widget.category),
                  applyPadding: true,
                ),
                const SizedBox(height: AppDimensions.spacingS),

                // Services for this category
                if (!_hasLoaded && services.isEmpty)
                  SizedBox(
                    height: 211,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, serviceIndex) {
                        return SizedBox(width: 150, child: ShimmerHelper.shimmerRounded(height: 211));
                      },
                      separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.spacingS),
                      itemCount: 3, // Show 3 shimmer items
                    ),
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
                            isFavorite: service.isLiked,
                            onTap: () => context.push('${RouteNames.serviceDetails}?id=${service.id}'),
                            onFavoriteTap: () {
                              final bloc = context.read<ServiceBloc>();
                              bloc.add(InteractWithServiceEvent(serviceId: service.id, interactionType: 'like'));
                              // No need to reload - bloc handles optimistic update
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
      ),
    );
  }
}
