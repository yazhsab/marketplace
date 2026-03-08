import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.fullName,
    super.email,
    super.phone,
    required super.role,
    super.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'delivery',
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'avatarUrl': avatarUrl,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      avatarUrl: user.avatarUrl,
    );
  }
}
