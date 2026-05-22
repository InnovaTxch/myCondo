class Announcement {
  final int id;
  final String title;
  final String message;
  final String category; // 'urgent', 'reminder', 'info'
  final String priority; // 'high', 'medium', 'low'
  final String status; // 'draft', 'scheduled', 'active', 'expired', 'archived'
  final DateTime createdAt;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isPinned;
  final DateTime? pinUntil;
  final bool requiresAck;
  final String audience; // 'all', 'residents', 'managers'
  final String postedBy;

  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    this.priority = 'medium',
    this.status = 'active',
    required this.createdAt,
    DateTime? startsAt,
    this.endsAt,
    this.isPinned = false,
    this.pinUntil,
    this.requiresAck = false,
    this.audience = 'all',
    required this.postedBy,
  }) : startsAt = startsAt ?? createdAt;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.parse(rawId.toString());

    final createdAtValue = json['created_at'];
    final createdAt = createdAtValue is String
        ? DateTime.parse(createdAtValue)
        : createdAtValue as DateTime;
    final startsAtValue = json['starts_at'];
    final startsAt = startsAtValue == null
        ? createdAt
        : (startsAtValue is String
              ? DateTime.parse(startsAtValue)
              : startsAtValue as DateTime);
    final endsAtValue = json['ends_at'];
    final endsAt = endsAtValue == null
        ? null
        : (endsAtValue is String
              ? DateTime.parse(endsAtValue)
              : endsAtValue as DateTime);
    final pinUntilValue = json['pin_until'];
    final pinUntil = pinUntilValue == null
        ? null
        : (pinUntilValue is String
              ? DateTime.parse(pinUntilValue)
              : pinUntilValue as DateTime);

    return Announcement(
      id: id,
      title: json['title'] as String,
      message: (json['content'] ?? json['message'] ?? '') as String,
      category: json['category'] as String? ?? 'info',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'active',
      createdAt: createdAt,
      startsAt: startsAt,
      endsAt: endsAt,
      isPinned: json['is_pinned'] as bool? ?? false,
      pinUntil: pinUntil,
      requiresAck: json['requires_ack'] as bool? ?? false,
      audience: json['audience'] as String? ?? 'all',
      postedBy: json['posted_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': message,
      'category': category,
      'priority': priority,
      'status': status,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
      'is_pinned': isPinned,
      'pin_until': pinUntil?.toUtc().toIso8601String(),
      'requires_ack': requiresAck,
      'audience': audience,
    };
  }
}
