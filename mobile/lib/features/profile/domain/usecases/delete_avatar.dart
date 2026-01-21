import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

/// Use case for deleting user avatar
class DeleteAvatar {
  final ProfileRepository repository;

  DeleteAvatar(this.repository);

  /// Execute the use case
  Future<Either<Failure, void>> call() async {
    return await repository.deleteAvatar();
  }
}
