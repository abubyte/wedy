part of '../service_page.dart';

class ServiceGalleryItems extends StatelessWidget {
  final List<ServiceImage> images;

  const ServiceGalleryItems({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 300,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) => Container(
          margin: EdgeInsets.only(
            left: index == 0 ? AppDimensions.spacingL : 0,
            right: index == images.length - 1 ? AppDimensions.spacingL : 0,
          ),
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            image: DecorationImage(image: NetworkImage(images[index].s3Url), fit: BoxFit.cover),
          ),
        ),
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.spacingS),
      ),
    );
  }
}
