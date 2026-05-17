class PrivilegeCard {
  final int id;
  final int organizationId;
  final int memberId;
  final String cardCode;
  final String? qrData;
  final String status;
  final String? memberName;
  final String? organizationName;
  final int? ayalkoottamId;
  final String? ayalkoottamName;

  PrivilegeCard({
    required this.id,
    required this.organizationId,
    required this.memberId,
    required this.cardCode,
    this.qrData,
    required this.status,
    this.memberName,
    this.organizationName,
    this.ayalkoottamId,
    this.ayalkoottamName,
  });

  factory PrivilegeCard.fromJson(Map<String, dynamic> json) {
    return PrivilegeCard(
      id: json['id'],
      organizationId: json['organization_id'],
      memberId: json['member_id'],
      cardCode: json['card_code'],
      qrData: json['qr_data'],
      status: json['status'],
      memberName: json['member_name'],
      organizationName: json['organization_name'],
      ayalkoottamId: json['ayalkoottam_id'],
      ayalkoottamName: json['ayalkoottam_name'],
    );
  }
}
