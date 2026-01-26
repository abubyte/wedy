import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/gallery_image.dart';
import '../repositories/gallery_repository.dart';

/// Use case to add a gallery image
class AddGalleryImage {
  final GalleryRepository repository;

  AddGalleryImage(this.repository);

  Future<Either<Failure, ImageUploadResult>> call({
    required File file,
    int displayOrder = 0,
  }) {
    // Validate file exists
    if (!file.existsSync()) {
      return Future.value(const Left(ValidationFailure('File does not exist')));
    }

    return repository.addGalleryImage(file: file, displayOrder: displayOrder);
  }
}
