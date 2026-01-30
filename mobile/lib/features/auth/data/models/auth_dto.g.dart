// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendOtpRequestDto _$SendOtpRequestDtoFromJson(Map<String, dynamic> json) =>
    SendOtpRequestDto(phoneNumber: json['phone_number'] as String);

Map<String, dynamic> _$SendOtpRequestDtoToJson(SendOtpRequestDto instance) => <String, dynamic>{
  'phone_number': instance.phoneNumber,
};

SendOtpResponseDto _$SendOtpResponseDtoFromJson(Map<String, dynamic> json) => SendOtpResponseDto(
  message: json['message'] as String,
  phoneNumber: json['phone_number'] as String,
  expiresIn: (json['expires_in'] as num).toInt(),
);

Map<String, dynamic> _$SendOtpResponseDtoToJson(SendOtpResponseDto instance) => <String, dynamic>{
  'message': instance.message,
  'phone_number': instance.phoneNumber,
  'expires_in': instance.expiresIn,
};

VerifyOtpRequestDto _$VerifyOtpRequestDtoFromJson(Map<String, dynamic> json) =>
    VerifyOtpRequestDto(phoneNumber: json['phone_number'] as String, otpCode: json['otp_code'] as String);

Map<String, dynamic> _$VerifyOtpRequestDtoToJson(VerifyOtpRequestDto instance) => <String, dynamic>{
  'phone_number': instance.phoneNumber,
  'otp_code': instance.otpCode,
};

VerifyOtpResponseDto _$VerifyOtpResponseDtoFromJson(Map<String, dynamic> json) => VerifyOtpResponseDto(
  isNewUser: json['is_new_user'] as bool,
  accessToken: json['access_token'] as String?,
  refreshToken: json['refresh_token'] as String?,
  tokenType: json['token_type'] as String? ?? 'bearer',
  expiresIn: (json['expires_in'] as num?)?.toInt(),
  message: json['message'] as String,
);

Map<String, dynamic> _$VerifyOtpResponseDtoToJson(VerifyOtpResponseDto instance) => <String, dynamic>{
  'is_new_user': instance.isNewUser,
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'token_type': instance.tokenType,
  'expires_in': instance.expiresIn,
  'message': instance.message,
};

CompleteRegistrationRequestDto _$CompleteRegistrationRequestDtoFromJson(Map<String, dynamic> json) =>
    CompleteRegistrationRequestDto(
      phoneNumber: json['phone_number'] as String,
      name: json['name'] as String,
      userType: json['user_type'] as String,
    );

Map<String, dynamic> _$CompleteRegistrationRequestDtoToJson(CompleteRegistrationRequestDto instance) =>
    <String, dynamic>{'phone_number': instance.phoneNumber, 'name': instance.name, 'user_type': instance.userType};

TokenResponseDto _$TokenResponseDtoFromJson(Map<String, dynamic> json) => TokenResponseDto(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  tokenType: json['token_type'] as String? ?? 'bearer',
  expiresIn: (json['expires_in'] as num).toInt(),
);

Map<String, dynamic> _$TokenResponseDtoToJson(TokenResponseDto instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'token_type': instance.tokenType,
  'expires_in': instance.expiresIn,
};

RefreshTokenRequestDto _$RefreshTokenRequestDtoFromJson(Map<String, dynamic> json) =>
    RefreshTokenRequestDto(refreshToken: json['refresh_token'] as String);

Map<String, dynamic> _$RefreshTokenRequestDtoToJson(RefreshTokenRequestDto instance) => <String, dynamic>{
  'refresh_token': instance.refreshToken,
};
