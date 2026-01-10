import 'package:flutter/foundation.dart';

/// API Constants
///
/// Định nghĩa base URL và các API endpoints
class ApiConstants {
  // Base URL - Tự động detect platform
  static String get baseUrl {
    if (kIsWeb) {
      // Web: sử dụng localhost
      return 'http://localhost:3000';
    }

    // Mobile platforms
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator: sử dụng 10.0.2.2 để trỏ về localhost của máy host
        // Nếu chạy trên physical device, thay bằng IP của máy host (ví dụ: http://192.168.1.100:3000)
        return 'http://10.0.2.2:3000';
      case TargetPlatform.iOS:
        // iOS simulator: sử dụng localhost
        // Nếu chạy trên physical device, thay bằng IP của máy host
        return 'http://localhost:3000';
      default:
        // Desktop (Windows, macOS, Linux) và các platform khác
        return 'http://localhost:3000';
    }
  }

  // API Endpoints
  static const String register = '/users/register';
  static const String login = '/users/login';
  static const String logout = '/users/logout';
  static const String refreshToken = '/users/refresh-token';
  static const String verifyEmail = '/users/verify-email';
  static const String resendVerifyEmail =
      '/users/resend-verify-email';
  static const String forgotPassword = '/users/forgot-password';
  static const String verifyForgotPassword =
      '/users/verify-forgot-password';
  static const String resetPassword = '/users/reset-password';
  static const String getMe = '/users/me';
}
