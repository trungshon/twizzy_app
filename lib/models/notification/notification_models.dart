import '../auth/auth_models.dart';
import '../twizz/twizz_models.dart';

/// NotificationType enum
enum NotificationType {
  like, // 0
  comment, // 1
  quoteTwizz, // 2
  follow, // 3
  mention, // 4
}

/// Notification Model
class NotificationModel {
  final String id;
  final String userId;
  final User sender;
  final NotificationType type;
  final String? twizzId;
  final bool isRead;
  final DateTime createdAt;
  final Twizz? twizz;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.sender,
    required this.type,
    this.twizzId,
    required this.isRead,
    required this.createdAt,
    this.twizz,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] as String,
      userId: json['user_id'] as String,
      sender: User.fromJson(
        json['sender'] as Map<String, dynamic>,
      ),
      type: NotificationType.values[json['type'] as int],
      twizzId: json['twizz_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.parse(json['created_at'] as String).toLocal(),
      twizz:
          json['twizz'] != null
              ? Twizz.fromJson(
                json['twizz'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

/// Notifications Response Model
class NotificationsResponse {
  final String message;
  final List<NotificationModel> result;

  NotificationsResponse({
    required this.message,
    required this.result,
  });

  factory NotificationsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return NotificationsResponse(
      message: json['message'] as String? ?? '',
      result:
          (json['result'] as List<dynamic>)
              .map(
                (n) => NotificationModel.fromJson(
                  n as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }
}
