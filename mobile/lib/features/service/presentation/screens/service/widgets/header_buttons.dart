part of '../service_page.dart';

class ServiceHeaderButtons extends StatelessWidget {
  const ServiceHeaderButtons({super.key, this.isMerchant = false, this.service});

  final bool isMerchant;
  final Service? service;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        isMerchant
            ? WedyCircularButton(
                icon: IconsaxPlusLinear.export_2,
                color: AppColors.primaryLight,
                borderColor: AppColors.primary,
                onTap: () {},
              )
            : const WedyCircularButton(),

        // Favorite & Share Buttons
        Row(
          children: [
            // Favorite Button (only for client app)
            if (!isMerchant)
              WedyCircularButton(
                icon: (service?.isSaved ?? false) ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
                color: (service?.isSaved ?? false) ? AppColors.primary : AppColors.surface,
                borderColor: (service?.isSaved ?? false) ? AppColors.primary : AppColors.border,
                onTap: service != null
                    ? () {
                        final bloc = context.read<ServiceBloc>();
                        bloc.add(InteractWithServiceEvent(serviceId: service!.id, interactionType: 'save'));
                        // Reload service details after interaction to update favorite status
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (context.mounted) {
                            bloc.add(LoadServiceByIdEvent(service!.id));
                          }
                        });
                      }
                    : null,
              )
            else
              WedyCircularButton(icon: IconsaxPlusLinear.trend_up, isPrimary: true, onTap: () {}),
            const SizedBox(width: AppDimensions.spacingS),

            // Share Button
            isMerchant
                ? WedyCircularButton(
                    icon: IconsaxPlusLinear.edit,
                    isPrimary: true,
                    onTap: () => context.push(RouteNames.edit),
                  )
                : WedyCircularButton(
                    icon: IconsaxPlusLinear.export_2,
                    onTap: service != null
                        ? () {
                            final bloc = context.read<ServiceBloc>();
                            bloc.add(InteractWithServiceEvent(serviceId: service!.id, interactionType: 'share'));
                          }
                        : null,
                  ),
          ],
        ),
      ],
    );
  }
}
