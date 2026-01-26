import '../../domain/entities/gallery_image.dart';

/// Loading type for gallery operations
enum GalleryLoadingType {
  initial,
  adding,
  removing,
}

/// Error type for gallery operations
enum GalleryErrorType {
  network,
  server,
  auth,
  tariffLimit,
  notFound,
  unknown,
}

/// Gallery states using Dart 3 sealed classes for exhaustiveness checking
sealed class GalleryState {
  const GalleryState();
}

/// Initial state
final class GalleryInitial extends GalleryState {
  const GalleryInitial();
}

/// Loading state with operation type
final class GalleryLoading extends GalleryState {
  final GalleryLoadingType type;
  final List<GalleryImage>? previousImages;

  const GalleryLoading({
    this.type = GalleryLoadingType.initial,
    this.previousImages,
  });
}

/// Gallery data holder
class GalleryData {
  final List<GalleryImage> images;
  final GalleryOperation? lastOperation;

  const GalleryData({
    this.images = const [],
    this.lastOperation,
  });

  GalleryData copyWith({
    List<GalleryImage>? images,
    GalleryOperation? Function()? lastOperation,
  }) {
    return GalleryData(
      images: images ?? this.images,
      lastOperation: lastOperation != null ? lastOperation() : this.lastOperation,
    );
  }

  GalleryData addImage(GalleryImage image) {
    return copyWith(images: [...images, image]);
  }

  GalleryData removeImage(String imageId) {
    return copyWith(images: images.where((i) => i.id != imageId).toList());
  }
}

/// Represents a completed operation for UI feedback
sealed class GalleryOperation {
  const GalleryOperation();
}

final class ImageAddedOperation extends GalleryOperation {
  final String imageId;
  final String s3Url;
  const ImageAddedOperation({required this.imageId, required this.s3Url});
}

final class ImageRemovedOperation extends GalleryOperation {
  final String imageId;
  const ImageRemovedOperation(this.imageId);
}

/// Gallery loaded successfully
final class GalleryLoaded extends GalleryState {
  final GalleryData data;

  const GalleryLoaded(this.data);

  List<GalleryImage> get images => data.images;
}

/// Error state with type information
final class GalleryError extends GalleryState {
  final String message;
  final GalleryErrorType type;
  final List<GalleryImage>? previousImages;

  const GalleryError(
    this.message, {
    this.type = GalleryErrorType.unknown,
    this.previousImages,
  });
}
