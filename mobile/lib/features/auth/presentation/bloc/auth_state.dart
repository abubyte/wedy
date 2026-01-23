import '../../domain/entities/user.dart';

/// Auth states using Dart 3 sealed classes for exhaustiveness checking
sealed class AuthState {
  const AuthState();
}

/// Initial state
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// OTP sent successfully
final class OtpSent extends AuthState {
  final String phoneNumber;

  const OtpSent(this.phoneNumber);
}

/// OTP verified - existing user logged in
final class OtpVerified extends AuthState {
  const OtpVerified();
}

/// OTP verified - new user needs registration
final class RegistrationRequired extends AuthState {
  final String phoneNumber;

  const RegistrationRequired(this.phoneNumber);
}

/// Registration completed successfully
final class RegistrationCompleted extends AuthState {
  final User user;

  const RegistrationCompleted(this.user);
}

/// User authenticated
final class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);
}

/// User not authenticated
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Error state
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}
