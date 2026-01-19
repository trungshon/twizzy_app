import '../../core/constants/api_constants.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../api/api_client.dart';

/// Bookmark Service
///
/// Service xử lý các thao tác liên quan đến Bookmark
class BookmarkService {
  final ApiClient _apiClient;

  BookmarkService(this._apiClient);

  /// Bookmark a twizz
  Future<void> bookmarkTwizz(String twizzId) async {
    try {
      await _apiClient.post(
        ApiConstants.bookmarkTwizz,
        body: {'twizz_id': twizzId},
        includeAuth: true,
      );
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi đánh dấu bài viết: ${e.toString()}',
      );
    }
  }

  /// Unbookmark a twizz
  Future<void> unbookmarkTwizz(String twizzId) async {
    try {
      await _apiClient.delete(
        ApiConstants.unbookmarkTwizz(twizzId),
        includeAuth: true,
      );
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi bỏ đánh dấu bài viết: ${e.toString()}',
      );
    }
  }

  /// Get user's bookmarked twizzs
  Future<NewFeedsResponse> getUserBookmarkedTwizzs({
    required String userId,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.getUserBookmarkedTwizzs(userId)}?limit=$limit&page=$page',
        includeAuth: true,
      );
      return NewFeedsResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi tải bài viết đã lưu: ${e.toString()}',
      );
    }
  }

  /// Get users who bookmarked a specific twizz
  Future<UsersListResponse> getUsersWhoBookmarkedTwizz({
    required String twizzId,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.getUsersWhoBookmarkedTwizz(twizzId)}?limit=$limit&page=$page',
        includeAuth: true,
      );
      return UsersListResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message:
            'Lỗi tải danh sách người đánh dấu: ${e.toString()}',
      );
    }
  }
}
