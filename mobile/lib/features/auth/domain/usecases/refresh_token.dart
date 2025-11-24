import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

/// Use case for refreshing authentication tokens
class RefreshToken {
  final AuthRepository repository;

  RefreshToken(this.repository);

  /// Execute the use case
  Future<Either<Failure, AuthTokens>> call(String refreshToken) async {
    // Business logic validation
    if (refreshToken.isEmpty) {
      return const Left(ValidationFailure('Refresh token cannot be empty'));
    }

    // Call repository (data layer)
    return await repository.refreshToken(refreshToken);
  }
}
