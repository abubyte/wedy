// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileUpdateRequestDto _$ProfileUpdateRequestDtoFromJson(
        Map<String, dynamic> json) =>
    ProfileUpdateRequestDto(
      name: json['name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      otpCode: json['otp_code'] as String?,
    );

Map<String, dynamic> _$ProfileUpdateRequestDtoToJson(
        ProfileUpdateRequestDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone_number': instance.phoneNumber,
      'otp_code': instance.otpCode,
    };

ProfileResponseDto _$ProfileResponseDtoFromJson(Map<String, dynamic> json) =>
    ProfileResponseDto(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      userType: json['user_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ProfileResponseDtoToJson(ProfileResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone_number': instance.phoneNumber,
      'name': instance.name,
      'avatar_url': instance.avatarUrl,
      'user_type': instance.userType,
      'created_at': instance.createdAt.toIso8601String(),
    };

AvatarUploadResponseDto _$AvatarUploadResponseDtoFromJson(
        Map<String, dynamic> json) =>
    AvatarUploadResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      s3Url: json['s3_url'] as String,
      presignedUrl: json['presigned_url'] as String?,
    );

Map<String, dynamic> _$AvatarUploadResponseDtoToJson(
        AvatarUploadResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      's3_url': instance.s3Url,
      'presigned_url': instance.presignedUrl,
    };
