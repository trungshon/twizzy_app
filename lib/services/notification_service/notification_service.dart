import '../../models/notification/notification_models.dart';
import '../api/api_client.dart';

/// Notification Service
class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  /// Get notification history
  Future<NotificationsResponse> getNotifications({
    int limit = 20,
    int page = 1,
  }) async {
    final response = await _apiClient.get(
      '/notifications?limit=$limit&page=$page',
      includeAuth: true,
    );

    return NotificationsResponse.fromJson(response);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _apiClient.patch(
      '/notifications/$notificationId/read',
      includeAuth: true,
    );
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _apiClient.patch(
      '/notifications/mark-all-as-read',
      includeAuth: true,
    );
  }

  /// Delete read notifications
  Future<void> deleteReadNotifications() async {
    await _apiClient.delete(
      '/notifications/read',
      includeAuth: true,
    );
  }
}
