class Asset {
  final int id;
  final int organizationId;
  final String name;
  final String? description;
  final String assetCode;
  final String? category;
  final String status;
  final String? condition;
  final String? purchaseDate;
  final double? cost;

  Asset({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    required this.assetCode,
    this.category,
    required this.status,
    this.condition,
    this.purchaseDate,
    this.cost,
  });

  bool get isAvailableForIssue =>
      status == 'available' && (condition == null || condition == 'working');

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
      description: json['description'],
      assetCode: json['asset_code'],
      category: json['category'],
      status: json['status'],
      condition: json['condition'],
      purchaseDate: json['purchase_date'],
      cost: json['cost'] != null ? double.tryParse(json['cost'].toString()) : null,
    );
  }
}

class AssetTransaction {
  final int id;
  final int assetId;
  final int memberId;
  final String issueDate;
  final String? dueDate;
  final String? returnDate;
  final String status;
  final String? remarks;
  final String? issueRemarks;
  final String? conditionOnReturn;
  final String? assetName;
  final String? assetCode;
  final String? assetCategory;
  final String? memberName;
  final String? memberPhone;
  final String? issuedByEmail;

  AssetTransaction({
    required this.id,
    required this.assetId,
    required this.memberId,
    required this.issueDate,
    this.dueDate,
    this.returnDate,
    required this.status,
    this.remarks,
    this.issueRemarks,
    this.conditionOnReturn,
    this.assetName,
    this.assetCode,
    this.assetCategory,
    this.memberName,
    this.memberPhone,
    this.issuedByEmail,
  });

  bool get isActive => status == 'issued';
  bool get isOverdue =>
      status == 'issued' && dueDate != null && DateTime.tryParse(dueDate!)?.isBefore(DateTime.now()) == true;

  factory AssetTransaction.fromJson(Map<String, dynamic> json) {
    return AssetTransaction(
      id: json['id'],
      assetId: json['asset_id'],
      memberId: json['member_id'],
      issueDate: json['issue_date'] ?? '',
      dueDate: json['due_date'],
      returnDate: json['return_date'],
      status: json['status'] ?? '',
      remarks: json['remarks'],
      issueRemarks: json['issue_remarks'],
      conditionOnReturn: json['condition_on_return'],
      assetName: json['asset_name'],
      assetCode: json['asset_code'],
      assetCategory: json['asset_category'],
      memberName: json['member_name'],
      memberPhone: json['member_phone'],
      issuedByEmail: json['issued_by_email'],
    );
  }
}

class AssetStats {
  final int total;
  final int available;
  final int issued;
  final int damaged;
  final int missing;

  AssetStats({
    required this.total,
    required this.available,
    required this.issued,
    required this.damaged,
    required this.missing,
  });

  factory AssetStats.fromJson(Map<String, dynamic> json) {
    return AssetStats(
      total: json['total'] ?? 0,
      available: json['available'] ?? 0,
      issued: json['issued'] ?? 0,
      damaged: json['damaged'] ?? 0,
      missing: json['missing'] ?? 0,
    );
  }
}
