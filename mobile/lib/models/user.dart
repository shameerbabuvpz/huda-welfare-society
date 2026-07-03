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
    const validRoles = {'super_admin', 'admin', 'member'};
    final rawRoles = (json['roles'] as List<dynamic>?)?.cast<String>() ?? [];
    final primaryRole = json['role'] as String?;

    // Keep only known roles, de-duplicated and order-preserving.
    final rolesList = <String>[];
    for (final r in [if (primaryRole != null) primaryRole, ...rawRoles]) {
      if (validRoles.contains(r) && !rolesList.contains(r)) {
        rolesList.add(r);
      }
    }

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
