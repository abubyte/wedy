import 'dart:io';

/// Gallery events using Dart 3 sealed classes for exhaustiveness checking
sealed class GalleryEvent {
  const GalleryEvent();
}

/// Load gallery images
final class LoadGalleryEvent extends GalleryEvent {
  const LoadGalleryEvent();
}

/// Add a gallery image
final class AddGalleryImageEvent extends GalleryEvent {
  final File file;
  final int displayOrder;

  const AddGalleryImageEvent({
    required this.file,
    this.displayOrder = 0,
  });
}

/// Remove a gallery image
final class RemoveGalleryImageEvent extends GalleryEvent {
  final String imageId;

  const RemoveGalleryImageEvent(this.imageId);
}

/// Refresh gallery images
final class RefreshGalleryEvent extends GalleryEvent {
  const RefreshGalleryEvent();
}
