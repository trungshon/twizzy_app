import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Constants
///
/// Định nghĩa base URL và các API endpoints
class ApiConstants {
  // Base URL - Tự động detect platform từ env
  static String get baseUrl {
    if (kIsWeb) {
      // Web: sử dụng BASE_URL_WEB từ env
      return dotenv.get(
        'BASE_URL_WEB',
        fallback: 'http://localhost:3000',
      );
    }

    // Mobile platforms
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator: sử dụng BASE_URL_ANDROID từ env
        // Nếu chạy trên physical device, thay bằng IP của máy host trong .env
        return dotenv.get(
          'BASE_URL_ANDROID',
          fallback: 'http://10.0.2.2:3000',
        );
      case TargetPlatform.iOS:
        // iOS simulator: sử dụng BASE_URL_IOS từ env
        // Nếu chạy trên physical device, thay bằng IP của máy host trong .env
        return dotenv.get(
          'BASE_URL_IOS',
          fallback: 'http://localhost:3000',
        );
      default:
        // Desktop (Windows, macOS, Linux) và các platform khác
        return dotenv.get(
          'BASE_URL_DEFAULT',
          fallback: 'http://localhost:3000',
        );
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

  // Google OAuth
  static const String googleOAuthMobile =
      '/users/oauth/google/mobile';

  // Twizz
  static const String createTwizz = '/twizzs';
  static const String getNewFeeds = '/twizzs';
  static String getUserTwizzs(String userId) =>
      '/twizzs/users/$userId/twizzs';

  // Media Upload
  static const String uploadImage = '/medias/upload-image';
  static const String uploadVideo = '/medias/upload-video';

  // Search
  static const String search = '/search';

  // Likes
  static const String likeTwizz = '/likes';
  static String unlikeTwizz(String twizzId) =>
      '/likes/twizzs/$twizzId';
  static String getUserLikedTwizzs(String userId) =>
      '/likes/users/$userId/liked-twizzs';

  // Bookmarks
  static const String bookmarkTwizz = '/bookmarks';
  static String unbookmarkTwizz(String twizzId) =>
      '/bookmarks/twizzs/$twizzId';
  static String getUserBookmarkedTwizzs(String userId) =>
      '/bookmarks/users/$userId/bookmarked-twizzs';

  // Static files (images, videos)
  static String videoStream(String name) =>
      '/static/video-stream/$name';
  static String image(String name) => '/static/image/$name';
}
