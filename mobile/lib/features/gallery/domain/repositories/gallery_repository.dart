import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/gallery_image.dart';

/// Gallery repository interface (domain layer)
abstract class GalleryRepository {
  /// Get all gallery images
  Future<Either<Failure, List<GalleryImage>>> getGalleryImages();

  /// Add gallery image
  Future<Either<Failure, ImageUploadResult>> addGalleryImage({required File file, required int displayOrder});

  /// Delete gallery image
  Future<Either<Failure, void>> deleteGalleryImage(String imageId);
}
