/// User entity
class User {
  final String id;
  final String phoneNumber;
  final String name;
  final String? avatarUrl;
  final UserType type;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.phoneNumber,
    required this.name,
    this.avatarUrl,
    required this.type,
    required this.createdAt,
  });
}

/// User type enum
enum UserType { client, merchant }
