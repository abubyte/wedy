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
            // Favorite Button (only for client app) - Instagram approach: like button
            if (!isMerchant)
              WedyCircularButton(
                icon: (service?.isLiked ?? false) ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
                onTap: service != null
                    ? () {
                        final bloc = context.read<ServiceBloc>();
                        bloc.add(InteractWithServiceEvent(serviceId: service!.id, interactionType: 'like'));
                        // No need to reload - bloc handles optimistic update
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
                        ? () async {
                            final bloc = context.read<ServiceBloc>();
                            bloc.add(InteractWithServiceEvent(serviceId: service!.id, interactionType: 'share'));

                            // Share with deep link (web URL - Universal Links will open app automatically)
                            final deepLinkService = DeepLinkService();
                            await deepLinkService.shareService(
                              serviceId: service!.id,
                              serviceName: service!.name,
                              description: service!.description,
                            );
                          }
                        : null,
                  ),
          ],
        ),
      ],
    );
  }
}
