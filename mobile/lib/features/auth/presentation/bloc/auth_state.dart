import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Base class for auth states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// OTP sent successfully
class OtpSent extends AuthState {
  final String phoneNumber;

  const OtpSent(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

/// OTP verified - existing user logged in
class OtpVerified extends AuthState {
  const OtpVerified();
}

/// OTP verified - new user needs registration
class RegistrationRequired extends AuthState {
  final String phoneNumber;

  const RegistrationRequired(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

/// Registration completed successfully
class RegistrationCompleted extends AuthState {
  final User user;

  const RegistrationCompleted(this.user);

  @override
  List<Object?> get props => [user];
}

/// User authenticated
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// User not authenticated
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Error state
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
