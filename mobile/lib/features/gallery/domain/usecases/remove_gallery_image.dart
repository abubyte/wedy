import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/gallery_repository.dart';

/// Use case to remove a gallery image
class RemoveGalleryImage {
  final GalleryRepository repository;

  RemoveGalleryImage(this.repository);

  Future<Either<Failure, void>> call(String imageId) {
    if (imageId.isEmpty) {
      return Future.value(const Left(ValidationFailure('Image ID is required')));
    }

    return repository.deleteGalleryImage(imageId);
  }
}
