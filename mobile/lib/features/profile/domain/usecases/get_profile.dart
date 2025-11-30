import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/profile_repository.dart';

/// Use case for getting user profile
class GetProfile {
  final ProfileRepository repository;

  GetProfile(this.repository);

  /// Execute the use case
  Future<Either<Failure, User>> call() async {
    return await repository.getProfile();
  }
}
