part of '../service_page.dart';

class ServiceGalleryItems extends StatelessWidget {
  const ServiceGalleryItems({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: EdgeInsets.only(
            left: index == 0 ? AppDimensions.spacingL : 0,
            right: index == 4 ? AppDimensions.spacingL : 0,
          ),
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            image: const DecorationImage(
              image: NetworkImage('https://picsum.photos/300/300'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppDimensions.spacingS),
      ),
    );
  }
}
