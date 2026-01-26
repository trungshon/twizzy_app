/// Route Names
///
/// Định nghĩa tên các routes trong ứng dụng
class RouteNames {
  // Auth Routes
  static const String authCheck = '/';
  static const String register = '/register';
  static const String login = '/login';
  static const String createAccount = '/create-account';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String verifyForgotPassword =
      '/verify-forgot-password';
  static const String resetPassword = '/reset-password';
  static const String setUsername = '/set-username';

  // Main Routes
  static const String home = '/home';

  // Profile Routes
  static const String myProfile = '/my-profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String userProfile = '/user-profile';
  static const String followerList = '/follower-list';

  // Twizz Routes
  static const String createTwizz = '/create-twizz';
  static const String twizzInteraction = '/twizz-interaction';
  static const String twizzDetail = '/twizz-detail';

  // Test Routes
  static const String videoTest = '/video-test';

  // Chat Routes
  static const String chatDetail = '/chat-detail';

  // Private constructor để prevent instantiation
  RouteNames._();
}
