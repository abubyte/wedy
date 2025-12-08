import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wedy/core/di/injection_container.dart';
import 'package:wedy/core/constants/app_dimensions.dart';
import 'package:wedy/features/service/presentation/bloc/service_bloc.dart';
import 'package:wedy/features/service/presentation/bloc/service_event.dart';
import 'package:wedy/features/service/presentation/bloc/service_state.dart';
import 'package:wedy/features/service/domain/entities/service.dart';
import 'hot_offers_banner_widget.dart';

/// Widget that displays featured services with its own ServiceBloc
class FeaturedServicesSection extends StatelessWidget {
  const FeaturedServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<ServiceBloc>();
        bloc.add(const LoadServicesEvent(featured: true, page: 1, limit: 10));
        return bloc;
      },
      child: BlocBuilder<ServiceBloc, ServiceState>(
        builder: (context, state) {
          if (state is ServiceLoading || state is ServiceInitial) {
            return const Padding(
              padding: EdgeInsets.all(AppDimensions.spacingL),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ServiceError) {
            return const SizedBox.shrink();
          }

          final featuredServices = state is ServicesLoaded ? state.allServices : <ServiceListItem>[];

          if (featuredServices.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
            child: HotOffersBannerWidget(services: featuredServices),
          );
        },
      ),
    );
  }
}
