import '../auth/auth_models.dart';

class Conversation {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isAccepted;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isAccepted,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      content: json['content'] ?? '',
      isAccepted: json['is_accepted'] ?? false,
      isRead: json['is_read'] ?? false,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at']).toLocal()
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at']).toLocal()
              : DateTime.now(),
    );
  }
}

class ChatThread {
  final User otherUser;
  final Conversation latestMessage;

  ChatThread({
    required this.otherUser,
    required this.latestMessage,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      otherUser: User.fromJson(json['other_user']),
      latestMessage: Conversation.fromJson(
        json['latest_message'],
      ),
    );
  }
}
