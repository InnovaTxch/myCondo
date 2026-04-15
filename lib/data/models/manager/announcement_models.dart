class Announcement {
  final int id;
  final String title;
  final String message;
  final String category; // 'urgent', 'reminder', 'info'
  final DateTime createdAt;
  final String postedBy;

  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    required this.postedBy,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.parse(rawId.toString());

    final createdAtValue = json['created_at'];
    final createdAt = createdAtValue is String
        ? DateTime.parse(createdAtValue)
        : createdAtValue as DateTime;

    return Announcement(
      id: id,
      title: json['title'] as String,
      message: (json['content'] ?? json['message'] ?? '') as String,
      category: json['category'] as String? ?? 'info',
      createdAt: createdAt,
      postedBy: json['posted_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': message,
        'category': category,
      };
}
