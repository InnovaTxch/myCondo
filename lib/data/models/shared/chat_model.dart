class ChatModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime? createdAt;

  const ChatModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'].toString(),
      conversationId: map['conversation_id'].toString(),
      senderId: map['sender_id'] as String,
      content: map['content'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }
}