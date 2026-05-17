class Organization {
  final int id;
  final String name;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final String? place;
  final String? logoUrl;
  final String status;

  Organization({
    required this.id,
    required this.name,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.place,
    this.logoUrl,
    required this.status,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      address: json['address'],
      place: json['place'],
      logoUrl: json['logo_url'] ?? json['logoUrl'],
      status: json['status'],
    );
  }
}
