/// Base class for all failures in the app
///
/// Failures represent error states in the domain layer.
/// They are different from exceptions - failures are expected
/// error cases that the business logic handles.
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

/// Failure for validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Failure for network/API errors
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Failure for server errors
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure for authentication errors
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Failure for not found errors
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Failure for cache/storage errors
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
