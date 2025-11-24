import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_tokens.dart';
import '../entities/user.dart';

/// Repository interface for authentication
abstract class AuthRepository {
  /// Send OTP to phone number
  Future<Either<Failure, void>> sendOtp(String phoneNumber);

  /// Verify OTP code
  Future<Either<Failure, AuthTokens>> verifyOtp({required String phoneNumber, required String otpCode});

  /// Complete user registration
  Future<Either<Failure, User>> completeRegistration({required String name, required UserType userType});

  /// Refresh authentication tokens
  Future<Either<Failure, AuthTokens>> refreshToken(String refreshToken);
}
