/// Base class for all failures in the app
///
/// Failures represent error states in the domain layer.
/// They are different from exceptions - failures are expected
/// error cases that the business logic handles.
sealed class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;

  /// Maps this failure to a user-friendly error message.
  /// Override [entityName] to customize the "not found" message.
  String toUserMessage({String entityName = 'Resource'}) {
    return switch (this) {
      NetworkFailure() => 'Network error. Please check your internet connection.',
      ServerFailure() => 'Server error. Please try again later.',
      NotFoundFailure() => '$entityName not found.',
      AuthFailure() => 'Authentication failed. Please login again.',
      ValidationFailure(:final message) => message,
      CacheFailure() => 'Storage error. Please try again.',
    };
  }
}

/// Failure for validation errors
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Failure for network/API errors
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Failure for server errors
final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure for authentication errors
final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Failure for not found errors
final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Failure for cache/storage errors
final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
