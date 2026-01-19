import '../../core/constants/api_constants.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../api/api_client.dart';

/// Like Service
///
/// Service xử lý các thao tác liên quan đến Like
class LikeService {
  final ApiClient _apiClient;

  LikeService(this._apiClient);

  /// Like a twizz
  Future<void> likeTwizz(String twizzId) async {
    try {
      await _apiClient.post(
        ApiConstants.likeTwizz,
        body: {'twizz_id': twizzId},
        includeAuth: true,
      );
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi thích bài viết: ${e.toString()}',
      );
    }
  }

  /// Unlike a twizz
  Future<void> unlikeTwizz(String twizzId) async {
    try {
      await _apiClient.delete(
        ApiConstants.unlikeTwizz(twizzId),
        includeAuth: true,
      );
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi bỏ thích bài viết: ${e.toString()}',
      );
    }
  }

  /// Get user's liked twizzs
  Future<NewFeedsResponse> getUserLikedTwizzs({
    required String userId,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.getUserLikedTwizzs(userId)}?limit=$limit&page=$page',
        includeAuth: true,
      );
      return NewFeedsResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi tải bài viết đã thích: ${e.toString()}',
      );
    }
  }

  /// Get users who liked a specific twizz
  Future<UsersListResponse> getUsersWhoLikedTwizz({
    required String twizzId,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.getUsersWhoLikedTwizz(twizzId)}?limit=$limit&page=$page',
        includeAuth: true,
      );
      return UsersListResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message:
            'Lỗi tải danh sách người thích: ${e.toString()}',
      );
    }
  }
}
