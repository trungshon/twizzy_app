import '../../core/constants/api_constants.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../api/api_client.dart';

/// Search Service
///
/// Service xử lý tìm kiếm người dùng và twizz
class SearchService {
  final ApiClient _apiClient;

  SearchService(this._apiClient);

  /// Search users (for mentions)
  ///
  /// [content] - Search query (username or name)
  /// [field] - 'username' | 'name' | null (search both)
  /// [limit] - Number of results per page
  /// [page] - Page number
  Future<SearchUsersResponse> searchUsers({
    required String content,
    String? field,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{
        'content': content,
        'type': 'users',
        'limit': limit.toString(),
        'page': page.toString(),
      };

      if (field != null) {
        queryParams['field'] = field;
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _apiClient.get(
        '${ApiConstants.search}?$queryString',
        includeAuth: true,
      );

      return SearchUsersResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi tìm kiếm: ${e.toString()}',
      );
    }
  }
}
