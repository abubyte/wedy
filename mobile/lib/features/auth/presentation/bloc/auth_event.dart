import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Base class for auth events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to send OTP
class SendOtpEvent extends AuthEvent {
  final String phoneNumber;

  const SendOtpEvent(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

/// Event to verify OTP
class VerifyOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String otpCode;

  const VerifyOtpEvent({required this.phoneNumber, required this.otpCode});

  @override
  List<Object?> get props => [phoneNumber, otpCode];
}

/// Event to complete registration
class CompleteRegistrationEvent extends AuthEvent {
  final String phoneNumber;
  final String name;
  final UserType userType;

  const CompleteRegistrationEvent({required this.phoneNumber, required this.name, required this.userType});

  @override
  List<Object?> get props => [phoneNumber, name, userType];
}

/// Event to refresh token
class RefreshTokenEvent extends AuthEvent {
  final String refreshToken;

  const RefreshTokenEvent(this.refreshToken);

  @override
  List<Object?> get props => [refreshToken];
}

/// Event to logout
class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

/// Event to check authentication status
class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}
