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
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      organizationId: json['organization_id'],
      userId: json['user_id'],
      ayalkoottamId: json['ayalkoottam_id'],
      memberCode: json['member_code'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      joinDate: json['join_date'],
      status: json['status'],
      ayalkoottamName: json['ayalkoottam_name'],
      designation: json['designation'],
    );
  }
}
