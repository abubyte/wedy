import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Use case for uploading user avatar
class UploadAvatar {
  final ProfileRepository repository;

  UploadAvatar(this.repository);

  /// Execute the use case
  Future<Either<Failure, String>> call(String imagePath) async {
    // Business logic validation
    if (imagePath.isEmpty) {
      return const Left(ValidationFailure('Image path cannot be empty'));
    }

    // Call repository
    return await repository.uploadAvatar(imagePath);
  }
}
