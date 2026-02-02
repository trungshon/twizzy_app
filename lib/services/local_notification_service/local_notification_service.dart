import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/notification/notification_models.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../routes/route_names.dart';
import '../../views/twizz/twizz_detail_screen.dart';
import '../../views/chat/chat_detail_screen.dart';

/// Global navigator key for navigation without context
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

/// Local Notification Service
/// Handles displaying local push notifications and navigation on tap
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _notificationChannelId =
      'twizzy_notifications';
  static const String _notificationChannelName =
      'Twizzy Notifications';
  static const String _messageChannelId = 'twizzy_messages';
  static const String _messageChannelName = 'Twizzy Messages';

  /// Initialize the notification service
  Future<void> initialize() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    // Request permission on Android 13+
    await _requestPermission();
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _notificationChannelId,
          _notificationChannelName,
          description:
              'Notifications for likes, comments, follows, etc.',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _messageChannelId,
          _messageChannelName,
          description: 'Notifications for new messages',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<void> _requestPermission() async {
    final androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Show a notification for a new social notification
  Future<void> showSocialNotification(
    NotificationModel notification,
  ) async {
    final title = notification.sender.name;
    final body = _getNotificationBody(notification);

    final payload = jsonEncode({
      'type': 'notification',
      'data': {
        'id': notification.id,
        'notificationType': notification.type.index,
        'senderId': notification.sender.id,
        'senderUsername': notification.sender.username,
        'twizzId': notification.twizzId,
        'twizz': notification.twizz?.toJson(),
      },
    });

    await _notificationsPlugin.show(
      notification.id.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannelId,
          _notificationChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Show a notification for a new message
  Future<void> showMessageNotification({
    required User sender,
    required String messageContent,
    required String conversationId,
  }) async {
    final title = sender.name;
    final body = messageContent;

    final payload = jsonEncode({
      'type': 'message',
      'data': {
        'sender': sender.toJson(),
        'conversationId': conversationId,
      },
    });

    await _notificationsPlugin.show(
      conversationId.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _messageChannelId,
          _messageChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  String _getNotificationBody(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.like:
        return 'đã thích bài viết của bạn';
      case NotificationType.comment:
        return 'đã bình luận bài viết của bạn';
      case NotificationType.quoteTwizz:
        return 'đã trích dẫn bài viết của bạn';
      case NotificationType.follow:
        return 'đã bắt đầu theo dõi bạn';
      case NotificationType.mention:
        return 'đã nhắc đến bạn trong một bài viết';
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final payload =
          jsonDecode(response.payload!) as Map<String, dynamic>;
      final type = payload['type'] as String;
      final data = payload['data'] as Map<String, dynamic>;

      if (type == 'notification') {
        _handleNotificationTap(data);
      } else if (type == 'message') {
        _handleMessageTap(data);
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final notificationType =
        NotificationType.values[data['notificationType'] as int];

    if (notificationType == NotificationType.follow) {
      final senderUsername = data['senderUsername'] as String?;
      if (senderUsername != null) {
        navigatorKey.currentState?.pushNamed(
          RouteNames.userProfile,
          arguments: senderUsername,
        );
      }
    } else if (data['twizz'] != null) {
      final twizzJson = data['twizz'] as Map<String, dynamic>;
      navigatorKey.currentState?.pushNamed(
        RouteNames.twizzDetail,
        arguments: TwizzDetailScreenArgs(
          twizz: Twizz.fromJson(twizzJson),
        ),
      );
    }
  }

  void _handleMessageTap(Map<String, dynamic> data) {
    final senderJson = data['sender'] as Map<String, dynamic>;
    final sender = User.fromJson(senderJson);

    navigatorKey.currentState?.pushNamed(
      RouteNames.chatDetail,
      arguments: ChatDetailScreenArgs(otherUser: sender),
    );
  }
}
