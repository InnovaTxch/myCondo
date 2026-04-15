class Announcement {
  final String id;
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
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      category: json['category'] as String? ?? 'info',
      createdAt: DateTime.parse(json['created_at'] as String),
      postedBy: json['posted_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'category': category,
        'posted_by': postedBy,
      };
}