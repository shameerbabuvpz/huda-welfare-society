class Banner {
  final int id;
  final String title;
  final String imageUrl;
  final int sortOrder;
  final bool isActive;
  final String? createdAt;

  Banner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
    );
  }
}
