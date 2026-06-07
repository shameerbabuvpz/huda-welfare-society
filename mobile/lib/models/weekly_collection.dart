class WeeklyCollection {
  final int id;
  final int ayalkoottamId;
  final String weekStartDate;
  final double deposit;
  final double withdrawal;
  final double loan;
  final double loanRepayment;
  final double adjustment;
  final double netTotal;
  final String? note;
  final String? ayalkoottamName;
  final String? ayalkoottamPlace;

  WeeklyCollection({
    required this.id,
    required this.ayalkoottamId,
    required this.weekStartDate,
    required this.deposit,
    required this.withdrawal,
    required this.loan,
    required this.loanRepayment,
    required this.adjustment,
    required this.netTotal,
    this.note,
    this.ayalkoottamName,
    this.ayalkoottamPlace,
  });

  factory WeeklyCollection.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
    return WeeklyCollection(
      id: json['id'],
      ayalkoottamId: json['ayalkoottam_id'],
      weekStartDate: '${json['week_start_date']}'.split('T').first,
      deposit: d(json['deposit']),
      withdrawal: d(json['withdrawal']),
      loan: d(json['loan']),
      loanRepayment: d(json['loan_repayment']),
      adjustment: d(json['adjustment']),
      netTotal: d(json['net_total']),
      note: json['note'],
      ayalkoottamName: json['ayalkoottam_name'],
      ayalkoottamPlace: json['ayalkoottam_place'],
    );
  }
}

/// Per-ayalkoottam totals inside a consolidation period or summary.
class ConsolidationGroup {
  final int ayalkoottamId;
  final String ayalkoottamName;
  final String? ayalkoottamPlace;
  final double deposit;
  final double withdrawal;
  final double loan;
  final double loanRepayment;
  final double adjustment;
  final double netTotal;
  final int entryCount;

  ConsolidationGroup({
    required this.ayalkoottamId,
    required this.ayalkoottamName,
    this.ayalkoottamPlace,
    required this.deposit,
    required this.withdrawal,
    required this.loan,
    required this.loanRepayment,
    required this.adjustment,
    required this.netTotal,
    required this.entryCount,
  });

  factory ConsolidationGroup.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
    return ConsolidationGroup(
      ayalkoottamId: json['ayalkoottam_id'],
      ayalkoottamName: json['ayalkoottam_name'] ?? '',
      ayalkoottamPlace: json['ayalkoottam_place'],
      deposit: d(json['deposit']),
      withdrawal: d(json['withdrawal']),
      loan: d(json['loan']),
      loanRepayment: d(json['loan_repayment']),
      adjustment: d(json['adjustment']),
      netTotal: d(json['net_total']),
      entryCount: json['entry_count'] ?? 0,
    );
  }
}

/// A single period (week or month) in the consolidated report.
class ConsolidationPeriod {
  final String periodKey;
  final String periodStart;
  final String periodEnd;
  final double deposit;
  final double withdrawal;
  final double loan;
  final double loanRepayment;
  final double adjustment;
  final double netTotal;
  final int entryCount;
  final List<ConsolidationGroup> ayalkoottams;

  ConsolidationPeriod({
    required this.periodKey,
    required this.periodStart,
    required this.periodEnd,
    required this.deposit,
    required this.withdrawal,
    required this.loan,
    required this.loanRepayment,
    required this.adjustment,
    required this.netTotal,
    required this.entryCount,
    required this.ayalkoottams,
  });

  factory ConsolidationPeriod.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
    return ConsolidationPeriod(
      periodKey: json['period_key'] ?? '',
      periodStart: '${json['period_start']}'.split('T').first,
      periodEnd: '${json['period_end']}'.split('T').first,
      deposit: d(json['deposit']),
      withdrawal: d(json['withdrawal']),
      loan: d(json['loan']),
      loanRepayment: d(json['loan_repayment']),
      adjustment: d(json['adjustment']),
      netTotal: d(json['net_total']),
      entryCount: json['entry_count'] ?? 0,
      ayalkoottams: (json['ayalkoottams'] as List? ?? [])
          .map((e) => ConsolidationGroup.fromJson(e))
          .toList(),
    );
  }
}

/// Full consolidated report payload.
class ConsolidationReport {
  final String groupBy;
  final String? fromDate;
  final String? toDate;
  final List<ConsolidationPeriod> periods;
  final List<ConsolidationGroup> byAyalkoottam;
  final ConsolidationGroup totals;

  ConsolidationReport({
    required this.groupBy,
    this.fromDate,
    this.toDate,
    required this.periods,
    required this.byAyalkoottam,
    required this.totals,
  });

  factory ConsolidationReport.fromJson(Map<String, dynamic> json) {
    final totalsJson = Map<String, dynamic>.from(json['totals'] ?? {});
    totalsJson['ayalkoottam_id'] = totalsJson['ayalkoottam_id'] ?? 0;
    totalsJson['ayalkoottam_name'] = totalsJson['ayalkoottam_name'] ?? 'Total';
    return ConsolidationReport(
      groupBy: json['group_by'] ?? 'week',
      fromDate: json['from_date'],
      toDate: json['to_date'],
      periods: (json['periods'] as List? ?? [])
          .map((e) => ConsolidationPeriod.fromJson(e))
          .toList(),
      byAyalkoottam: (json['by_ayalkoottam'] as List? ?? [])
          .map((e) => ConsolidationGroup.fromJson(e))
          .toList(),
      totals: ConsolidationGroup.fromJson(totalsJson),
    );
  }
}
