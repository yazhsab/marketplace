class User {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
  });

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
