class KaneevGroup {
  final int id;
  final int organizationId;
  final String name;
  final String code;
  final double donationAmount;
  final int? totalMembers;
  final int? durationMonths;
  final String? startDate;
  final String status;
  final List<KaneevMemberSlot>? members;
  final List<KaneevRecipient>? recipients;
  final List<KaneevBalanceLog>? balanceLogs;
  final double currentBalance;

  KaneevGroup({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    required this.donationAmount,
    this.totalMembers,
    this.durationMonths,
    this.startDate,
    required this.status,
    this.members,
    this.recipients,
    this.balanceLogs,
    this.currentBalance = 0,
  });

  factory KaneevGroup.fromJson(Map<String, dynamic> json) {
    return KaneevGroup(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
      code: json['code'],
      donationAmount: double.parse(json['donation_amount'].toString()),
      totalMembers: json['total_members'],
      durationMonths: json['duration_months'],
      startDate: json['start_date'],
      status: json['status'],
      members: json['members'] != null
          ? (json['members'] as List).map((m) => KaneevMemberSlot.fromJson(m)).toList()
          : null,
      recipients: json['recipients'] != null
          ? (json['recipients'] as List).map((r) => KaneevRecipient.fromJson(r)).toList()
          : null,
      balanceLogs: json['balance_logs'] != null
          ? (json['balance_logs'] as List).map((b) => KaneevBalanceLog.fromJson(b)).toList()
          : null,
      currentBalance: json['current_balance'] != null
          ? double.parse(json['current_balance'].toString())
          : 0,
    );
  }
}

class KaneevMemberSlot {
  final int id;
  final int memberId;
  final int? slotNumber;
  final String status;
  final String? memberName;
  final String? memberCode;
  final String? ayalkoottamName;

  KaneevMemberSlot({
    required this.id,
    required this.memberId,
    this.slotNumber,
    required this.status,
    this.memberName,
    this.memberCode,
    this.ayalkoottamName,
  });

  factory KaneevMemberSlot.fromJson(Map<String, dynamic> json) {
    return KaneevMemberSlot(
      id: json['id'],
      memberId: json['member_id'],
      slotNumber: json['slot_number'],
      status: json['status'],
      memberName: json['member_name'],
      memberCode: json['member_code'],
      ayalkoottamName: json['ayalkoottam_name'],
    );
  }
}

class KaneevRecipient {
  final int id;
  final int memberId;
  final int monthNumber;
  final double? totalAmount;
  final String? receivedDate;
  final String? memberName;

  KaneevRecipient({
    required this.id,
    required this.memberId,
    required this.monthNumber,
    this.totalAmount,
    this.receivedDate,
    this.memberName,
  });

  factory KaneevRecipient.fromJson(Map<String, dynamic> json) {
    return KaneevRecipient(
      id: json['id'],
      memberId: json['member_id'],
      monthNumber: json['month_number'],
      totalAmount: json['total_amount'] != null ? double.parse(json['total_amount'].toString()) : null,
      receivedDate: json['received_date']?.toString(),
      memberName: json['member_name'],
    );
  }
}

class KaneevBalanceLog {
  final int id;
  final int monthNumber;
  final double totalCollected;
  final double totalDistributed;
  final double monthBalance;
  final double cumulativeBalance;
  final String? notes;

  KaneevBalanceLog({
    required this.id,
    required this.monthNumber,
    required this.totalCollected,
    required this.totalDistributed,
    required this.monthBalance,
    required this.cumulativeBalance,
    this.notes,
  });

  factory KaneevBalanceLog.fromJson(Map<String, dynamic> json) {
    return KaneevBalanceLog(
      id: json['id'],
      monthNumber: json['month_number'],
      totalCollected: double.parse(json['total_collected'].toString()),
      totalDistributed: double.parse(json['total_distributed'].toString()),
      monthBalance: double.parse(json['month_balance'].toString()),
      cumulativeBalance: double.parse(json['cumulative_balance'].toString()),
      notes: json['notes'],
    );
  }
}

class KaneevMemberSummary {
  final int id;
  final int organizationId;
  final String name;
  final String code;
  final double donationAmount;
  final String status;
  final int? slotNumber;
  final bool hasReceived;
  final int? receivedMonth;
  final double currentBalance;

  KaneevMemberSummary({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    required this.donationAmount,
    required this.status,
    this.slotNumber,
    required this.hasReceived,
    this.receivedMonth,
    this.currentBalance = 0,
  });

  factory KaneevMemberSummary.fromJson(Map<String, dynamic> json) {
    return KaneevMemberSummary(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
      code: json['code'],
      donationAmount: double.parse(json['donation_amount'].toString()),
      status: json['status'],
      slotNumber: json['slot_number'],
      hasReceived: json['has_received'] == true,
      receivedMonth: json['received_month'],
      currentBalance: json['current_balance'] != null
          ? double.parse(json['current_balance'].toString())
          : 0,
    );
  }
}
