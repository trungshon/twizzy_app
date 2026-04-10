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

      // Nếu KHÔNG phải local → URL bên ngoài (Cloudinary, CDN) → tối ưu hóa nếu là Cloudinary
      if (!isLocalUrl) {
        // Nếu là URL Cloudinary
        if (host.contains('res.cloudinary.com')) {
          // Xử lý chung cho cả ảnh và video
          if (url.contains('/upload/')) {
            // Nếu là video, thêm vc_auto
            if (url.contains('/video/')) {
              if (!url.contains('/f_auto,q_auto,vc_auto/')) {
                return url.replaceFirst(
                  '/upload/',
                  '/upload/f_auto,q_auto,vc_auto/',
                );
              }
            }
            // Nếu là ảnh, chỉ cần f_auto,q_auto
            else if (!url.contains('/f_auto,q_auto/')) {
              return url.replaceFirst(
                '/upload/',
                '/upload/f_auto,q_auto/',
              );
            }
          }
        }
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

  /// Normalize video URL with HLS (Adaptive Bitrate Streaming)
  static String normalizeVideoUrl(String url) {
    if (url.isEmpty || !url.contains('res.cloudinary.com')) {
      return normalizeUrl(url);
    }

    // Chuyển sang định dạng HLS (.m3u8) với streaming profile auto (sp_auto)
    // Điều này cho phép tự động điều chỉnh chất lượng theo băng thông người dùng
    if (url.contains('/video/upload/')) {
      // Bỏ qua nếu đã là m3u8
      if (url.endsWith('.m3u8')) return url;

      // Xóa các transformations cũ và thay bằng sp_auto
      String baseUrl = url.split('/upload/')[0];
      String pathAfterUpload = url.split('/upload/')[1];

      // Bỏ qua version (v123456) nếu có
      if (pathAfterUpload.startsWith('v') &&
          pathAfterUpload.contains('/')) {
        pathAfterUpload = pathAfterUpload.substring(
          pathAfterUpload.indexOf('/') + 1,
        );
      }

      // Đổi extension sang .m3u8
      String publicId = pathAfterUpload.split('.').first;
      return '$baseUrl/upload/sp_auto/$publicId.m3u8';
    }

    return normalizeUrl(url);
  }
}
