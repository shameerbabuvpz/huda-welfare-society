class Ayalkoottam {
  final int id;
  final int? organizationId;
  final String name;
  final String? place;
  final String status;
  final int? memberCount;

  Ayalkoottam({
    required this.id,
    this.organizationId,
    required this.name,
    this.place,
    this.status = 'active',
    this.memberCount,
  });

  factory Ayalkoottam.fromJson(Map<String, dynamic> json) {
    return Ayalkoottam(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
      place: json['place'],
      status: json['status'] ?? 'active',
      memberCount: json['member_count'],
    );
  }
}
