class User {
  final int id;
  final String? name;
  final String? phone;
  final String role;
  final List<String> roles;
  final int? organizationId;
  final String? photoUrl;
  final String? lastLoginAt;

  User({
    required this.id,
    this.name,
    this.phone,
    required this.role,
    this.roles = const [],
    this.organizationId,
    this.photoUrl,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rolesList = (json['roles'] as List<dynamic>?)?.cast<String>() ?? [];
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'],
      roles: rolesList.isNotEmpty ? rolesList : [json['role']],
      organizationId: json['organizationId'] ?? json['organization_id'],
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      lastLoginAt: json['lastLoginAt'] ?? json['last_login_at'],
    );
  }

  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isMember => role == 'member';
  bool get hasMultipleRoles => roles.length > 1;
}
