import 'package:json_annotation/json_annotation.dart';

part 'auth_dto.g.dart';

/// Request DTO for sending OTP
@JsonSerializable()
class SendOtpRequestDto {
  @JsonKey(name: 'phone_number')
  final String phoneNumber;

  SendOtpRequestDto({required this.phoneNumber});

  factory SendOtpRequestDto.fromJson(Map<String, dynamic> json) => _$SendOtpRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SendOtpRequestDtoToJson(this);
}

/// Response DTO for sending OTP
@JsonSerializable()
class SendOtpResponseDto {
  final String message;
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  SendOtpResponseDto({required this.message, required this.phoneNumber, required this.expiresIn});

  factory SendOtpResponseDto.fromJson(Map<String, dynamic> json) => _$SendOtpResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SendOtpResponseDtoToJson(this);
}

/// Request DTO for verifying OTP
@JsonSerializable()
class VerifyOtpRequestDto {
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  @JsonKey(name: 'otp_code')
  final String otpCode;

  VerifyOtpRequestDto({required this.phoneNumber, required this.otpCode});

  factory VerifyOtpRequestDto.fromJson(Map<String, dynamic> json) => _$VerifyOtpRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyOtpRequestDtoToJson(this);
}

/// Response DTO for verifying OTP
@JsonSerializable()
class VerifyOtpResponseDto {
  @JsonKey(name: 'is_new_user')
  final bool isNewUser;
  @JsonKey(name: 'access_token')
  final String? accessToken;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  @JsonKey(name: 'expires_in')
  final int? expiresIn;
  final String message;

  VerifyOtpResponseDto({
    required this.isNewUser,
    this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
    this.expiresIn,
    required this.message,
  });

  factory VerifyOtpResponseDto.fromJson(Map<String, dynamic> json) => _$VerifyOtpResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyOtpResponseDtoToJson(this);
}

/// Request DTO for completing registration
@JsonSerializable()
class CompleteRegistrationRequestDto {
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  final String name;
  @JsonKey(name: 'user_type')
  final String userType;

  CompleteRegistrationRequestDto({required this.phoneNumber, required this.name, required this.userType});

  factory CompleteRegistrationRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CompleteRegistrationRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CompleteRegistrationRequestDtoToJson(this);
}

/// Response DTO for token response
@JsonSerializable()
class TokenResponseDto {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  TokenResponseDto({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
    required this.expiresIn,
  });

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) => _$TokenResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TokenResponseDtoToJson(this);
}

/// Request DTO for refreshing token
@JsonSerializable()
class RefreshTokenRequestDto {
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  RefreshTokenRequestDto({required this.refreshToken});

  factory RefreshTokenRequestDto.fromJson(Map<String, dynamic> json) => _$RefreshTokenRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshTokenRequestDtoToJson(this);
}
