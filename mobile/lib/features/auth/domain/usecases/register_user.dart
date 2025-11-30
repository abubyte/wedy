import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for completing user registration
class RegisterUser {
  final AuthRepository repository;

  RegisterUser(this.repository);

  /// Execute the use case
  Future<Either<Failure, User>> call({
    required String phoneNumber,
    required String name,
    required UserType userType,
  }) async {
    // Business logic validation
    if (phoneNumber.isEmpty) {
      return const Left(ValidationFailure('Phone number cannot be empty'));
    }

    if (name.trim().isEmpty) {
      return const Left(ValidationFailure('Name cannot be empty'));
    }

    if (name.trim().length < 2) {
      return const Left(ValidationFailure('Name must be at least 2 characters'));
    }

    if (name.trim().length > 100) {
      return const Left(ValidationFailure('Name must be less than 100 characters'));
    }

    // Call repository (data layer)
    return await repository.completeRegistration(phoneNumber: phoneNumber, name: name.trim(), userType: userType);
  }
}
