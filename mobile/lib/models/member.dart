class Member {
  final int id;
  final int organizationId;
  final int? userId;
  final int? ayalkoottamId;
  final String memberCode;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? joinDate;
  final String status;
  final String? ayalkoottamName;
  final String? designation;
  final String? photoUrl;

  Member({
    required this.id,
    required this.organizationId,
    this.userId,
    this.ayalkoottamId,
    required this.memberCode,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.joinDate,
    required this.status,
    this.ayalkoottamName,
    this.designation,
    this.photoUrl,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? 0,
      organizationId: json['organization_id'] ?? 0,
      userId: json['user_id'],
      ayalkoottamId: json['ayalkoottam_id'],
      memberCode: json['member_code'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      joinDate: json['join_date'],
      status: json['status'] ?? 'active',
      ayalkoottamName: json['ayalkoottam_name'],
      designation: json['designation'],
      photoUrl: json['photo_url'],
    );
  }
}
