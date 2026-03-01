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

    // Nếu là URL bên ngoài (Cloudinary, CDN, ...) → giữ nguyên
    // Chỉ normalize URL từ backend local (localhost, 10.0.2.2, ...)
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      // Kiểm tra có phải URL backend local không
      final isLocalUrl =
          host == 'localhost' ||
          host == '10.0.2.2' ||
          host == '127.0.0.1' ||
          host.startsWith('192.168.');

      // Nếu KHÔNG phải local → URL bên ngoài (Cloudinary, CDN) → giữ nguyên
      if (!isLocalUrl) {
        return url;
      }

      // Nếu là local URL → rebuild với baseUrl hiện tại
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
