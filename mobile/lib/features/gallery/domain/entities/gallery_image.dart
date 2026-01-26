/// Gallery image entity (domain layer)
class GalleryImage {
  final String id;
  final String s3Url;
  final String fileName;
  final int? fileSize;
  final int displayOrder;
  final DateTime createdAt;

  const GalleryImage({
    required this.id,
    required this.s3Url,
    required this.fileName,
    this.fileSize,
    required this.displayOrder,
    required this.createdAt,
  });
}

/// Image upload response entity
class ImageUploadResult {
  final bool success;
  final String message;
  final String? imageId;
  final String? s3Url;
  final String? presignedUrl;

  const ImageUploadResult({
    required this.success,
    required this.message,
    this.imageId,
    this.s3Url,
    this.presignedUrl,
  });
}
