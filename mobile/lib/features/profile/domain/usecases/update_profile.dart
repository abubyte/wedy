import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/profile_repository.dart';

/// Use case for updating user profile
class UpdateProfile {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  /// Execute the use case
  Future<Either<Failure, User>> call({String? name, String? phoneNumber, String? otpCode}) async {
    // Business logic validation
    if (name != null && name.trim().isEmpty) {
      return const Left(ValidationFailure('Name cannot be empty'));
    }

    if (name != null) {
      final trimmedName = name.trim();
      if (trimmedName.length < 2) {
        return const Left(ValidationFailure('Name must be at least 2 characters'));
      }
      if (trimmedName.length > 100) {
        return const Left(ValidationFailure('Name must be less than 100 characters'));
      }
    }

    if (phoneNumber != null && phoneNumber.trim().isEmpty) {
      return const Left(ValidationFailure('Phone number cannot be empty'));
    }

    // Call repository
    return await repository.updateProfile(name: name?.trim(), phoneNumber: phoneNumber, otpCode: otpCode);
  }
}
