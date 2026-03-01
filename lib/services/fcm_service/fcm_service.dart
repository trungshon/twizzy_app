import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../api/api_client.dart';
import '../local_notification_service/local_notification_service.dart';
import '../../routes/route_names.dart';
import '../../views/twizz/twizz_detail_screen.dart';
import '../../views/chat/chat_detail_screen.dart';
import '../../models/auth/auth_models.dart';

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

  /// Lưu message chờ xử lý khi navigator chưa sẵn sàng
  RemoteMessage? _pendingMessage;

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
    // Lưu lại để xử lý sau khi navigator sẵn sàng
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        'FCM có initialMessage chờ xử lý: ${initialMessage.data}',
      );
      _pendingMessage = initialMessage;
    }
  }

  /// Xử lý pending message sau khi navigator đã sẵn sàng
  /// Gọi từ main.dart sau khi runApp() đã chạy
  void processPendingMessage() {
    if (_pendingMessage != null) {
      debugPrint(
        'FCM xử lý pending message: ${_pendingMessage!.data}',
      );
      // Delay thêm để đảm bảo navigator đã settle hoàn toàn
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleMessageOpenedApp(_pendingMessage!);
        _pendingMessage = null;
      });
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
  }

  /// Xử lý khi user tap vào FCM notification để mở app
  /// Navigate tới màn hình tương ứng dựa trên loại thông báo
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM mở app từ notification: ${message.data}');
    final data = message.data;
    final type = data['type'] ?? '';

    // Đợi navigator sẵn sàng rồi mới navigate
    _waitForNavigatorAndNavigate(() {
      if (type == 'message') {
      // Thông báo tin nhắn → mở ChatDetailScreen
        _navigateToChat(data);
      } else {
      // Thông báo social → navigate theo loại
        _navigateToNotification(type, data);
      }
    });
  }

  /// Đợi cho navigator sẵn sàng rồi thực hiện callback
  void _waitForNavigatorAndNavigate(VoidCallback navigate) {
    // Kiểm tra ngay nếu navigator đã sẵn sàng
    if (navigatorKey.currentState != null) {
      navigate();
      return;
    }

    // Nếu chưa sẵn sàng, đợi frame tiếp theo rồi thử lại
    debugPrint('FCM: Navigator chưa sẵn sàng, đợi...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (navigatorKey.currentState != null) {
          navigate();
        } else {
          debugPrint(
            'FCM: Navigator vẫn chưa sẵn sàng sau delay',
          );
        }
      });
    });
  }

  /// Navigate tới màn hình chat khi tap thông báo tin nhắn
  void _navigateToChat(Map<String, dynamic> data) {
    final senderId = data['sender_id'] ?? '';
    final senderName = data['sender_name'] ?? '';
    final senderUsername = data['sender_username'] ?? '';
    final senderAvatar = data['sender_avatar'] ?? '';

    if (senderId.isEmpty) return;

    // Tạo User object từ FCM data để mở ChatDetailScreen
    final sender = User(
      id: senderId,
      name: senderName,
      email: '',
      username: senderUsername,
      avatar: senderAvatar.isNotEmpty ? senderAvatar : null,
      dateOfBirth: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      verify: 'Verified',
    );

    debugPrint('FCM navigate đến chat với ${sender.name}');
    navigatorKey.currentState?.pushNamed(
      RouteNames.chatDetail,
      arguments: ChatDetailScreenArgs(otherUser: sender),
    );
  }

  /// Navigate tới màn hình tương ứng với loại thông báo social
  void _navigateToNotification(
    String type,
    Map<String, dynamic> data,
  ) {
    final typeInt = int.tryParse(type);
    if (typeInt == null) return;

    // NotificationType enum:
    // 0=like, 1=comment, 2=quoteTwizz, 3=follow,
    // 4=mention, 5=reportResolved, 6=reportIgnored,
    // 7=postDeleted, 8=accountBanned
    switch (typeInt) {
      case 3: // Follow → mở trang profile người follow
        final senderUsername = data['sender_username'] ?? '';
        if (senderUsername.isNotEmpty) {
          debugPrint(
            'FCM navigate đến profile: $senderUsername',
          );
          navigatorKey.currentState?.pushNamed(
            RouteNames.userProfile,
            arguments: senderUsername,
          );
        }
        break;

      case 0: // Like
      case 1: // Comment
      case 2: // QuoteTwizz
      case 4: // Mention
      case 5: // ReportResolved
      case 6: // ReportIgnored
      case 7: // PostDeleted
      case 8: // AccountBanned
      default:
        // Mở chi tiết twizz nếu có twizz_id
        final twizzId = data['twizz_id'] ?? '';
        if (twizzId.isNotEmpty) {
          debugPrint('FCM navigate đến twizz: $twizzId');
          navigatorKey.currentState?.pushNamed(
            RouteNames.twizzDetail,
            arguments: TwizzDetailScreenArgs(twizzId: twizzId),
          );
        }
        break;
    }
  }
}
