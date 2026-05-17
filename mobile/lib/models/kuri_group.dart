class KuriGroup {
  final int id;
  final int organizationId;
  final String name;
  final String code;
  final int totalMembers;
  final double monthlyAmount;
  final int durationMonths;
  final String startDate;
  final String status;
  final List<KuriMemberSlot>? members;
  final List<KuriWinner>? winners;

  KuriGroup({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    required this.totalMembers,
    required this.monthlyAmount,
    required this.durationMonths,
    required this.startDate,
    required this.status,
    this.members,
    this.winners,
  });

  factory KuriGroup.fromJson(Map<String, dynamic> json) {
    return KuriGroup(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
      code: json['code'],
      totalMembers: json['total_members'],
      monthlyAmount: double.parse(json['monthly_amount'].toString()),
      durationMonths: json['duration_months'],
      startDate: json['start_date'],
      status: json['status'],
      members: json['members'] != null
          ? (json['members'] as List).map((m) => KuriMemberSlot.fromJson(m)).toList()
          : null,
      winners: json['winners'] != null
          ? (json['winners'] as List).map((w) => KuriWinner.fromJson(w)).toList()
          : null,
    );
  }
}

class KuriMemberSlot {
  final int id;
  final int memberId;
  final int? slotNumber;
  final String status;
  final String? memberName;
  final String? memberCode;
  final String? memberPhone;
  final String? ayalkoottamName;

  KuriMemberSlot({
    required this.id,
    required this.memberId,
    this.slotNumber,
    required this.status,
    this.memberName,
    this.memberCode,
    this.memberPhone,
    this.ayalkoottamName,
  });

  factory KuriMemberSlot.fromJson(Map<String, dynamic> json) {
    return KuriMemberSlot(
      id: json['id'],
      memberId: json['member_id'],
      slotNumber: json['slot_number'],
      status: json['status'],
      memberName: json['member_name'],
      memberCode: json['member_code'],
      memberPhone: json['member_phone'],
      ayalkoottamName: json['ayalkoottam_name'],
    );
  }
}

class KuriWinner {
  final int id;
  final int memberId;
  final int monthNumber;
  final String wonDate;
  final String? memberName;
  final double? payoutAmount;
  final String? payoutDate;

  KuriWinner({
    required this.id,
    required this.memberId,
    required this.monthNumber,
    required this.wonDate,
    this.memberName,
    this.payoutAmount,
    this.payoutDate,
  });

  factory KuriWinner.fromJson(Map<String, dynamic> json) {
    return KuriWinner(
      id: json['id'],
      memberId: json['member_id'],
      monthNumber: json['month_number'],
      wonDate: json['won_date'],
      memberName: json['member_name'],
      payoutAmount: json['payout_amount'] != null ? double.parse(json['payout_amount'].toString()) : null,
      payoutDate: json['payout_date'],
    );
  }
}

class KuriPaymentStatus {
  final Map<String, dynamic> group;
  final int? slotNumber;
  final List<int> paidMonths;
  final List<int> pendingMonths;
  final bool hasWon;
  final int? winMonth;

  KuriPaymentStatus({
    required this.group,
    this.slotNumber,
    required this.paidMonths,
    required this.pendingMonths,
    required this.hasWon,
    this.winMonth,
  });

  factory KuriPaymentStatus.fromJson(Map<String, dynamic> json) {
    return KuriPaymentStatus(
      group: json['group'],
      slotNumber: json['slot_number'],
      paidMonths: List<int>.from(json['paid_months']),
      pendingMonths: List<int>.from(json['pending_months']),
      hasWon: json['has_won'],
      winMonth: json['win_month'],
    );
  }
}
