import 'package:flutter/material.dart';
import '../../models/notification/notification_models.dart';
import '../../services/notification_service/notification_service.dart';
import '../../services/socket_service/socket_service.dart';
import '../../routes/route_names.dart';
import '../../views/twizz/twizz_detail_screen.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService;
  final SocketService _socketService;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  NotificationViewModel(
    this._notificationService,
    this._socketService,
  ) {
    _initSocket();
  }

  void _initSocket() {
    _socketService.on('notification', _onNotificationReceived);
  }

  void _sortNotifications() {
    _notifications.sort((a, b) {
      if (a.isRead != b.isRead) {
        // Unread (false) comes first
        return a.isRead ? 1 : -1;
      }
      // Newest first
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  void _onNotificationReceived(dynamic data) {
    try {
      final notification = NotificationModel.fromJson(
        data as Map<String, dynamic>,
      );

      // Check if notification already exists (e.g., from a toggled like)
      final existingIndex = _notifications.indexWhere(
        (n) => n.id == notification.id,
      );
      if (existingIndex != -1) {
        _notifications.removeAt(existingIndex);
      }

      _notifications.insert(0, notification);
      _sortNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing real-time notification: $e');
    }
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _isLoading = true; // Set loading only on refresh/initial
      _error = null;
      notifyListeners();
    }

    try {
      final response =
          await _notificationService.getNotifications();
      _notifications = response.result;
      _sortNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // Find and update local state first for instant feedback
      final index = _notifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (index != -1 && !_notifications[index].isRead) {
        final oldNotification = _notifications[index];
        _notifications[index] = NotificationModel(
          id: oldNotification.id,
          userId: oldNotification.userId,
          sender: oldNotification.sender,
          type: oldNotification.type,
          twizzId: oldNotification.twizzId,
          isRead: true,
          createdAt: oldNotification.createdAt,
          twizz: oldNotification.twizz,
        );
        notifyListeners();

        // Call API in background
        await _notificationService.markAsRead(notificationId);
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_notifications.every((n) => n.isRead)) return;

    final originalNotifications = List<NotificationModel>.from(
      _notifications,
    );

    try {
      // Optimistic update
      _notifications =
          _notifications.map((n) {
            if (!n.isRead) {
              return NotificationModel(
                id: n.id,
                userId: n.userId,
                sender: n.sender,
                type: n.type,
                twizzId: n.twizzId,
                isRead: true,
                createdAt: n.createdAt,
                twizz: n.twizz,
              );
            }
            return n;
          }).toList();
      notifyListeners();

      await _notificationService.markAllAsRead();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      _notifications = originalNotifications; // Revert
      notifyListeners();
    }
  }

  Future<void> deleteReadNotifications() async {
    if (_notifications.every((n) => !n.isRead)) return;

    final originalNotifications = List<NotificationModel>.from(
      _notifications,
    );

    try {
      // Optimistic update: Remove read notifications
      _notifications.removeWhere((n) => n.isRead);
      notifyListeners();

      await _notificationService.deleteReadNotifications();
    } catch (e) {
      debugPrint('Error deleting read notifications: $e');
      _notifications = originalNotifications; // Revert
      notifyListeners();
    }
  }

  void handleNotificationClick(
    NotificationModel notification,
    dynamic context,
  ) {
    // Mark as read locally and on server
    markAsRead(notification.id);

    if (notification.type == NotificationType.follow) {
      // Navigate to profile
      if (notification.sender.username != null) {
        // Use username for UserProfileScreen
        Navigator.pushNamed(
          context,
          RouteNames.userProfile,
          arguments: notification.sender.username,
        );
      }
    } else if (notification.twizz != null) {
      // Navigate to twizz detail
      Navigator.pushNamed(
        context,
        RouteNames.twizzDetail,
        arguments: TwizzDetailScreenArgs(
          twizz: notification.twizz!,
        ),
      );
    }
  }

  @override
  void dispose() {
    _socketService.off('notification', _onNotificationReceived);
    super.dispose();
  }
}
