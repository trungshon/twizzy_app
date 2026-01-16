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

  // Main Routes
  static const String home = '/home';

  // Profile Routes
  static const String myProfile = '/my-profile';

  // Test Routes
  static const String videoTest = '/video-test';

  // Private constructor để prevent instantiation
  RouteNames._();
}
