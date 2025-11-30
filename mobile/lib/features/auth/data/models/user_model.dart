import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// User model (data layer) - extends domain entity
@JsonSerializable()
class UserModel extends User {
  UserModel({
    required super.id,
    required super.phoneNumber,
    required super.name,
    super.avatarUrl,
    required super.type,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Manual mapping for snake_case API response to camelCase model
    return UserModel(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      type: json['user_type'] == 'client' ? UserType.client : UserType.merchant,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'name': name,
      'avatar_url': avatarUrl,
      'user_type': type.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  User toEntity() {
    return User(id: id, phoneNumber: phoneNumber, name: name, avatarUrl: avatarUrl, type: type, createdAt: createdAt);
  }

  /// Create from domain entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      phoneNumber: user.phoneNumber,
      name: user.name,
      avatarUrl: user.avatarUrl,
      type: user.type,
      createdAt: user.createdAt,
    );
  }
}
