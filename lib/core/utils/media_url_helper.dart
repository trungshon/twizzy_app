import '../constants/api_constants.dart';

/// Media URL Helper
///
/// Helper để normalize media URLs từ backend
class MediaUrlHelper {
  /// Normalize media URL
  ///
  /// Chuyển đổi URL từ backend (có thể là full URL hoặc relative path)
  /// thành URL phù hợp với baseUrl hiện tại của app
  static String normalizeUrl(String url) {
    if (url.isEmpty) return url;

    final baseUrl = ApiConstants.baseUrl;

    // Nếu là relative path (bắt đầu với /)
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }

    // Nếu là full URL, extract path và rebuild với baseUrl hiện tại
    try {
      final uri = Uri.parse(url);
      final path = uri.path;

      // Nếu không có path, trả về URL gốc
      if (path.isEmpty) return url;

      // Rebuild với baseUrl hiện tại
      return '$baseUrl$path';
    } catch (e) {
      // Nếu parse lỗi, trả về URL gốc
      return url;
    }
  }

  /// Normalize image URL
  static String normalizeImageUrl(String url) {
    return normalizeUrl(url);
  }

  /// Normalize video URL
  static String normalizeVideoUrl(String url) {
    return normalizeUrl(url);
  }
}
