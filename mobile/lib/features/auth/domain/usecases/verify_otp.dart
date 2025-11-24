import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

/// Use case for verifying OTP code
class VerifyOtp {
  final AuthRepository repository;

  VerifyOtp(this.repository);

  /// Execute the use case
  Future<Either<Failure, AuthTokens>> call({required String phoneNumber, required String otpCode}) async {
    // Business logic validation
    if (phoneNumber.isEmpty) {
      return const Left(ValidationFailure('Phone number cannot be empty'));
    }

    if (otpCode.isEmpty) {
      return const Left(ValidationFailure('OTP code cannot be empty'));
    }

    // OTP format validation (6 digits)
    if (!RegExp(r'^\d{6}$').hasMatch(otpCode)) {
      return const Left(ValidationFailure('OTP code must be 6 digits'));
    }

    // Call repository (data layer)
    return await repository.verifyOtp(phoneNumber: phoneNumber, otpCode: otpCode);
  }
}
