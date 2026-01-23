import '../../domain/entities/user.dart';

/// Auth events using Dart 3 sealed classes for exhaustiveness checking
sealed class AuthEvent {
  const AuthEvent();
}

/// Event to send OTP
final class SendOtpEvent extends AuthEvent {
  final String phoneNumber;

  const SendOtpEvent(this.phoneNumber);
}

/// Event to verify OTP
final class VerifyOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String otpCode;

  const VerifyOtpEvent({required this.phoneNumber, required this.otpCode});
}

/// Event to complete registration
final class CompleteRegistrationEvent extends AuthEvent {
  final String phoneNumber;
  final String name;
  final UserType userType;

  const CompleteRegistrationEvent({required this.phoneNumber, required this.name, required this.userType});
}

/// Event to refresh token
final class RefreshTokenEvent extends AuthEvent {
  final String refreshToken;

  const RefreshTokenEvent(this.refreshToken);
}

/// Event to logout
final class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

/// Event to check authentication status
final class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}
