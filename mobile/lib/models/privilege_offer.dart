class PrivilegeOffer {
  final int id;
  final int organizationId;
  final String companyName;
  final String? description;
  final String offerType; // percentage | flat | freebie
  final double? offerValue;
  final String? termsAndConditions;
  final String qrCode;
  final String? qrData;
  final String? contactPhone;
  final String? contactEmail;
  final String? logoUrl;
  final String? imageUrl;
  final String status;
  final int redemptionCount;
  final DateTime? createdAt;

  PrivilegeOffer({
    required this.id,
    required this.organizationId,
    required this.companyName,
    this.description,
    required this.offerType,
    this.offerValue,
    this.termsAndConditions,
    required this.qrCode,
    this.qrData,
    this.contactPhone,
    this.contactEmail,
    this.logoUrl,
    this.imageUrl,
    required this.status,
    this.redemptionCount = 0,
    this.createdAt,
  });

  factory PrivilegeOffer.fromJson(Map<String, dynamic> json) {
    return PrivilegeOffer(
      id: json['id'],
      organizationId: json['organization_id'],
      companyName: json['company_name'],
      description: json['description'],
      offerType: json['offer_type'] ?? 'percentage',
      offerValue: json['offer_value'] != null ? double.tryParse(json['offer_value'].toString()) : null,
      termsAndConditions: json['terms_and_conditions'],
      qrCode: json['qr_code'],
      qrData: json['qr_data'],
      contactPhone: json['contact_phone'],
      contactEmail: json['contact_email'],
      logoUrl: json['logo_url'],
      imageUrl: json['image_url'],
      status: json['status'] ?? 'active',
      redemptionCount: json['redemption_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class PrivilegeRedemption {
  final int id;
  final int offerId;
  final int memberId;
  final String? memberName;
  final String? memberCode;
  final String? companyName;
  final String? offerType;
  final double? offerValue;
  final String? offerDescription;
  final DateTime? redeemedAt;

  PrivilegeRedemption({
    required this.id,
    required this.offerId,
    required this.memberId,
    this.memberName,
    this.memberCode,
    this.companyName,
    this.offerType,
    this.offerValue,
    this.offerDescription,
    this.redeemedAt,
  });

  factory PrivilegeRedemption.fromJson(Map<String, dynamic> json) {
    return PrivilegeRedemption(
      id: json['id'],
      offerId: json['offer_id'],
      memberId: json['member_id'],
      memberName: json['member_name'],
      memberCode: json['member_code'],
      companyName: json['company_name'],
      offerType: json['offer_type'],
      offerValue: json['offer_value'] != null ? double.tryParse(json['offer_value'].toString()) : null,
      offerDescription: json['offer_description'],
      redeemedAt: json['redeemed_at'] != null ? DateTime.tryParse(json['redeemed_at']) : null,
    );
  }
}
