class Admin {
  final int id;
  final String? name;
  final String? phone;
  final String? email;
  final String role;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  Admin({
    required this.id,
    this.name,
    this.phone,
    this.email,
    required this.role,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      role: json['role'] ?? 'admin',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  bool get isActive => status == 'active';
  bool get isSuperAdmin => role == 'super_admin';
}
