import 'package:json_annotation/json_annotation.dart';
import '../../../auth/domain/entities/user.dart';

part 'profile_dto.g.dart';

/// Request DTO for updating user profile
@JsonSerializable()
class ProfileUpdateRequestDto {
  final String? name;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'otp_code')
  final String? otpCode;

  ProfileUpdateRequestDto({this.name, this.phoneNumber, this.otpCode});

  factory ProfileUpdateRequestDto.fromJson(Map<String, dynamic> json) => _$ProfileUpdateRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileUpdateRequestDtoToJson(this);
}

/// Response DTO for user profile
@JsonSerializable()
class ProfileResponseDto {
  final String id;
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  final String name;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'user_type')
  final String userType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  ProfileResponseDto({
    required this.id,
    required this.phoneNumber,
    required this.name,
    this.avatarUrl,
    required this.userType,
    required this.createdAt,
  });

  factory ProfileResponseDto.fromJson(Map<String, dynamic> json) => _$ProfileResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileResponseDtoToJson(this);

  /// Convert to User entity
  User toEntity() {
    return User(
      id: id,
      phoneNumber: phoneNumber,
      name: name,
      avatarUrl: avatarUrl,
      type: userType == 'client' ? UserType.client : UserType.merchant,
      createdAt: createdAt,
    );
  }
}

/// Response DTO for avatar upload
@JsonSerializable()
class AvatarUploadResponseDto {
  final bool success;
  final String message;
  @JsonKey(name: 's3_url')
  final String s3Url;
  @JsonKey(name: 'presigned_url')
  final String? presignedUrl;

  AvatarUploadResponseDto({required this.success, required this.message, required this.s3Url, this.presignedUrl});

  factory AvatarUploadResponseDto.fromJson(Map<String, dynamic> json) => _$AvatarUploadResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AvatarUploadResponseDtoToJson(this);
}
