import '../auth/auth_models.dart';
import '../twizz/twizz_models.dart';

class Conversation {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final List<Media> medias;
  final bool isAccepted;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.medias = const [],
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
      medias:
          (json['medias'] as List<dynamic>?)
              ?.map(
                (m) => Media.fromJson(m as Map<String, dynamic>),
              )
              .toList() ??
          [],
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

  /// Kiểm tra tin nhắn có media không
  bool get hasMedia => medias.isNotEmpty;

  /// Lấy text hiển thị cho tin nhắn cuối (dùng trong chat list)
  String get displayContent {
    if (content.isNotEmpty) return content;
    if (medias.isNotEmpty) {
      final firstMedia = medias.first;
      return firstMedia.type == MediaType.image
          ? 'Đã gửi ảnh 📷'
          : 'Đã gửi video 🎬';
    }
    return '';
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
