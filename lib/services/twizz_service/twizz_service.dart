import 'dart:io';
import '../../core/constants/api_constants.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../api/api_client.dart';

/// Twizz Service
///
/// Service xử lý các thao tác liên quan đến Twizz
class TwizzService {
  final ApiClient _apiClient;

  TwizzService(this._apiClient);

  /// Get NewFeeds
  Future<NewFeedsResponse> getNewFeeds({
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.getNewFeeds}?limit=$limit&page=$page',
        includeAuth: true,
      );
      return NewFeedsResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi tải bài viết: ${e.toString()}',
      );
    }
  }

  /// Get user's twizzs by type
  Future<NewFeedsResponse> getUserTwizzs({
    required String userId,
    int? type,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      String url =
          '${ApiConstants.getUserTwizzs(userId)}?limit=$limit&page=$page';
      if (type != null) {
        url += '&type=$type';
      }
      final response = await _apiClient.get(
        url,
        includeAuth: true,
      );
      return NewFeedsResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi tải bài viết: ${e.toString()}',
      );
    }
  }

  /// Create a new Twizz
  Future<CreateTwizzResponse> createTwizz(
    CreateTwizzRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.createTwizz,
        body: request.toJson(),
        includeAuth: true,
      );

      return CreateTwizzResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi đăng bài: ${e.toString()}',
      );
    }
  }

  /// Create a retwizz (repost)
  Future<CreateTwizzResponse> createRetwizz(
    String parentTwizzId,
  ) async {
    final request = CreateTwizzRequest(
      type: TwizzType.retwizz,
      audience: TwizzAudience.everyone,
      content: '',
      parentId: parentTwizzId,
    );
    return createTwizz(request);
  }

  /// Upload images (with auto refresh token)
  Future<List<Media>> uploadImages(List<File> files) async {
    try {
      final multipartFiles =
          files.map((file) {
            final extension =
                file.path.split('.').last.toLowerCase();
            return MultipartFile(
              fieldName: 'image',
              file: file,
              mimeType: _getImageMimeType(extension),
            );
          }).toList();

      final response = await _apiClient.uploadFiles(
        ApiConstants.uploadImage,
        files: multipartFiles,
      );

      final uploadResponse = UploadMediaResponse.fromJson(
        response,
      );
      return uploadResponse.result;
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi tải ảnh: ${e.toString()}',
      );
    }
  }

  /// Upload video (with auto refresh token)
  Future<List<Media>> uploadVideo(File file) async {
    try {
      final extension = file.path.split('.').last.toLowerCase();
      final multipartFile = MultipartFile(
        fieldName: 'video',
        file: file,
        mimeType: _getVideoMimeType(extension),
      );

      final response = await _apiClient.uploadFiles(
        ApiConstants.uploadVideo,
        files: [multipartFile],
      );

      final uploadResponse = UploadMediaResponse.fromJson(
        response,
      );
      return uploadResponse.result;
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi tải video: ${e.toString()}',
      );
    }
  }

  /// Delete a twizz
  Future<void> deleteTwizz(String twizzId) async {
    try {
      await _apiClient.delete(
        '${ApiConstants.deleteTwizz}/$twizzId',
      );
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi xóa bài: ${e.toString()}',
      );
    }
  }

  String _getImageMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _getVideoMimeType(String extension) {
    switch (extension) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }
}
