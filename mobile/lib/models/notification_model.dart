class AppNotification {
  final int id;
  final String title;
  final String body;
  final String? audienceType;
  final String? createdAt;
  final String? sentAt;
  final String? status;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.audienceType,
    this.createdAt,
    this.sentAt,
    this.status,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      audienceType: json['audience_type'],
      createdAt: json['created_at'],
      sentAt: json['sent_at'],
      status: json['status'],
    );
  }
}
