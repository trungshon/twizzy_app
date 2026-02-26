import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../local_notification_service/local_notification_service.dart';

/// Handler xử lý FCM message khi app ở background/terminated
/// Phải là top-level function (không nằm trong class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
  debugPrint(
    'FCM Background: ${message.notification?.title} - ${message.notification?.body}',
  );
  // FCM tự động hiện notification trên system tray khi app ở background/terminated
  // Không cần xử lý thêm ở đây
}

/// FCM Service
///
/// Quản lý Firebase Cloud Messaging cho push notification
/// Hoạt động cùng với Socket.IO:
/// - Socket.IO: xử lý real-time khi app đang mở
/// - FCM: push notification khi app ở background/tắt hẳn
class FcmService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;
  final ApiClient _apiClient;

  String? _currentToken;

  FcmService(this._apiClient);

  String? get currentToken => _currentToken;

  /// Khởi tạo FCM service
  Future<void> initialize() async {
    // Đăng ký handler cho background messages
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // Yêu cầu quyền thông báo
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
      'FCM quyền thông báo: ${settings.authorizationStatus}',
    );

    // Lấy FCM token hiện tại
    _currentToken = await _messaging.getToken();
    debugPrint('FCM Token: $_currentToken');

    // Lắng nghe khi token bị refresh (ví dụ: gỡ app rồi cài lại)
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token đã refresh: $newToken');
      _currentToken = newToken;
      _registerTokenOnServer(newToken);
    });

    // Xử lý foreground messages
    // Khi app đang mở, Socket.IO đã handle rồi nên không cần hiện thêm
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Xử lý khi user tap vào notification (app từ background về foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageOpenedApp,
    );

    // Kiểm tra nếu app được mở từ trạng thái tắt hẳn bởi notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Đăng ký FCM token lên server (gọi sau khi login thành công)
  Future<void> registerToken() async {
    if (_currentToken == null) return;
    await _registerTokenOnServer(_currentToken!);
  }

  /// Xóa FCM token khỏi server (gọi trước khi logout)
  Future<void> unregisterToken() async {
    if (_currentToken == null) return;
    try {
      await _apiClient.post(
        '/users/fcm-token/remove',
        body: {'fcm_token': _currentToken},
        includeAuth: true,
      );
      debugPrint('FCM token đã được xóa khỏi server');
    } catch (e) {
      debugPrint('Lỗi khi xóa FCM token: $e');
    }
  }

  /// Gửi FCM token lên server để lưu trữ
  Future<void> _registerTokenOnServer(String token) async {
    try {
      await _apiClient.post(
        '/users/fcm-token',
        body: {'fcm_token': token},
        includeAuth: true,
      );
      debugPrint('FCM token đã được đăng ký lên server');
    } catch (e) {
      debugPrint('Lỗi khi đăng ký FCM token: $e');
    }
  }

  /// Xử lý FCM message khi app đang ở foreground
  /// Socket.IO đã xử lý notification rồi, nên chỉ log để debug
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      'FCM Foreground: ${message.notification?.title} - ${message.notification?.body}',
    );
    // Không hiện local notification vì Socket.IO đã xử lý
    // FCM foreground message sẽ bị bỏ qua để tránh hiện trùng
  }

  /// Xử lý khi user tap vào FCM notification để mở app
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM mở app từ notification: ${message.data}');
    final data = message.data;
    final twizzId = data['twizz_id'];

    // Navigate tới chi tiết twizz nếu có
    if (twizzId != null && twizzId.isNotEmpty) {
      navigatorKey.currentState?.pushNamed(
        '/twizz-detail',
        arguments: twizzId,
      );
    }
  }
}
