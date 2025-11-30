// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      type: $enumDecode(_$UserTypeEnumMap, json['user_type']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone_number': instance.phoneNumber,
      'avatar_url': instance.avatarUrl,
      'user_type': _$UserTypeEnumMap[instance.type]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$UserTypeEnumMap = {
  UserType.client: 'client',
  UserType.merchant: 'merchant',
};
