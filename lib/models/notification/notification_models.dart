import '../auth/auth_models.dart';
import '../twizz/twizz_models.dart';
import '../report/report_models.dart';

/// NotificationType enum
enum NotificationType {
  like, // 0
  comment, // 1
  quoteTwizz, // 2
  follow, // 3
  mention, // 4
  reportResolved, // 5
  reportIgnored, // 6
  postDeleted, // 7
  accountBanned, // 8
}

/// Notification Model
class NotificationModel {
  final String id;
  final String userId;
  final User sender;
  final NotificationType type;
  final String? twizzId;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;
  final Report? report;
  final Twizz? twizz;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.sender,
    required this.type,
    this.twizzId,
    this.metadata,
    required this.isRead,
    required this.createdAt,
    this.report,
    this.twizz,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Helper to extract string from ObjectId or plain string
    String safeId(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map && value['\$oid'] != null) {
        return value['\$oid'] as String;
      }
      return value.toString();
    }

    // Helper to parse date
    DateTime safeDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value).toLocal();
        } catch (_) {
          return DateTime.now();
        }
      }
      if (value is Map && value['\$date'] != null) {
        try {
          return DateTime.parse(
            value['\$date'] as String,
          ).toLocal();
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return NotificationModel(
      id: safeId(json['_id']),
      userId: safeId(json['user_id']),
      sender: User.fromJson(
        json['sender'] as Map<String, dynamic>,
      ),
      type: NotificationType.values[json['type'] as int? ?? 0],
      twizzId: json['twizz_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: safeDate(json['created_at']),
      report:
          json['report'] != null
              ? Report.fromJson(
                json['report'] as Map<String, dynamic>,
              )
              : null,
      twizz:
          json['twizz'] != null
              ? Twizz.fromJson(
                json['twizz'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    User? sender,
    NotificationType? type,
    String? twizzId,
    Map<String, dynamic>? metadata,
    bool? isRead,
    DateTime? createdAt,
    Report? report,
    Twizz? twizz,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      twizzId: twizzId ?? this.twizzId,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      report: report ?? this.report,
      twizz: twizz ?? this.twizz,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'sender': sender.toJson(),
      'type': type.index,
      'twizz_id': twizzId,
      'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'report': report?.toJson(),
      'twizz': twizz?.toJson(),
    };
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
