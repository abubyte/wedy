import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/gallery_image.dart';
import '../repositories/gallery_repository.dart';

/// Use case to get gallery images
class GetGalleryImages {
  final GalleryRepository repository;

  GetGalleryImages(this.repository);

  Future<Either<Failure, List<GalleryImage>>> call() {
    return repository.getGalleryImages();
  }
}
