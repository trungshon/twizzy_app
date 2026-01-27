import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import '../../core/constants/api_constants.dart';
import '../../models/auth/auth_models.dart';
import '../local_storage/token_storage.dart';

/// API Client
///
/// HTTP client để gọi API
class ApiClient {
  final TokenStorage _tokenStorage;
  final http.Client _client;
  bool _isRefreshing = false;

  /// Callback khi token được refresh thành công
  void Function(String accessToken)? onTokenRefreshed;

  /// Callback khi refresh token thất bại (cần logout)
  void Function()? onRefreshTokenFailed;

  ApiClient(this._tokenStorage, {http.Client? client})
    : _client = client ?? http.Client();

  /// Get headers with authorization if available
  Future<Map<String, String>> _getHeaders({
    bool includeAuth = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    return headers;
  }

  /// Handle error response
  ApiErrorResponse _handleError(http.Response response) {
    try {
      final errorJson =
          json.decode(response.body) as Map<String, dynamic>;
      return ApiErrorResponse.fromJson(errorJson);
    } catch (e) {
      return ApiErrorResponse(
        message: 'Có lỗi xảy ra: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Refresh access token
  Future<void> _refreshToken() async {
    if (_isRefreshing) {
      // Đợi nếu đang refresh
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        throw ApiErrorResponse(
          message: 'Không có refresh token',
          statusCode: 401,
        );
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/users/refresh-token',
      );
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      final response = await _client.post(
        url,
        headers: headers,
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final responseData =
            json.decode(response.body) as Map<String, dynamic>;
        final tokenResponse = TokenResponse.fromJson(
          responseData['result'] as Map<String, dynamic>,
        );

        // Lưu tokens mới
        await _tokenStorage.saveAccessToken(
          tokenResponse.accessToken,
        );
        await _tokenStorage.saveRefreshToken(
          tokenResponse.refreshToken,
        );

        // Notify that token has been refreshed
        if (onTokenRefreshed != null) {
          onTokenRefreshed!(tokenResponse.accessToken);
        }
      } else {
        // Refresh token failed, clear tokens
        await _tokenStorage.clearTokens();

        // Notify that refresh failed
        if (onRefreshTokenFailed != null) {
          onRefreshTokenFailed!();
        }
        throw _handleError(response);
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = false,
    bool retryOn401 = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(
        includeAuth: includeAuth,
      );

      var response = await _client.post(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      // Handle 401 Unauthorized - token expired
      if (response.statusCode == 401 &&
          includeAuth &&
          retryOn401 &&
          endpoint != '/users/refresh-token') {
        // Try to refresh token
        try {
          await _refreshToken();
          // Retry request with new token
          final newHeaders = await _getHeaders(
            includeAuth: includeAuth,
          );
          response = await _client.post(
            url,
            headers: newHeaders,
            body: body != null ? json.encode(body) : null,
          );
        } catch (e) {
          // Refresh failed, clear tokens and throw
          await _tokenStorage.clearTokens();
          throw _handleError(response);
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return json.decode(response.body)
            as Map<String, dynamic>;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi kết nối: ${e.toString()}',
      );
    }
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool includeAuth = true,
    bool retryOn401 = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(
        includeAuth: includeAuth,
      );

      var response = await _client.get(url, headers: headers);

      // Handle 401 Unauthorized - token expired
      if (response.statusCode == 401 &&
          includeAuth &&
          retryOn401 &&
          endpoint != '/users/refresh-token') {
        // Try to refresh token
        try {
          await _refreshToken();
          // Retry request with new token
          final newHeaders = await _getHeaders(
            includeAuth: includeAuth,
          );
          response = await _client.get(url, headers: newHeaders);
        } catch (e) {
          // Refresh failed, clear tokens and throw
          await _tokenStorage.clearTokens();
          throw _handleError(response);
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return json.decode(response.body)
            as Map<String, dynamic>;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi kết nối: ${e.toString()}',
      );
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    bool retryOn401 = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(
        includeAuth: includeAuth,
      );

      var response = await _client.put(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      // Handle 401 Unauthorized - token expired
      if (response.statusCode == 401 &&
          includeAuth &&
          retryOn401) {
        try {
          await _refreshToken();
          final newHeaders = await _getHeaders(
            includeAuth: includeAuth,
          );
          response = await _client.put(
            url,
            headers: newHeaders,
            body: body != null ? json.encode(body) : null,
          );
        } catch (e) {
          await _tokenStorage.clearTokens();
          throw _handleError(response);
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return json.decode(response.body)
            as Map<String, dynamic>;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi kết nối: ${e.toString()}',
      );
    }
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    bool retryOn401 = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(
        includeAuth: includeAuth,
      );

      var response = await _client.patch(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      // Handle 401 Unauthorized - token expired
      if (response.statusCode == 401 &&
          includeAuth &&
          retryOn401) {
        try {
          await _refreshToken();
          final newHeaders = await _getHeaders(
            includeAuth: includeAuth,
          );
          response = await _client.patch(
            url,
            headers: newHeaders,
            body: body != null ? json.encode(body) : null,
          );
        } catch (e) {
          await _tokenStorage.clearTokens();
          throw _handleError(response);
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return json.decode(response.body)
            as Map<String, dynamic>;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi kết nối: ${e.toString()}',
      );
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
    bool retryOn401 = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _getHeaders(
        includeAuth: includeAuth,
      );

      var response = await _client.delete(url, headers: headers);

      // Handle 401 Unauthorized - token expired
      if (response.statusCode == 401 &&
          includeAuth &&
          retryOn401) {
        try {
          await _refreshToken();
          final newHeaders = await _getHeaders(
            includeAuth: includeAuth,
          );
          response = await _client.delete(
            url,
            headers: newHeaders,
          );
        } catch (e) {
          await _tokenStorage.clearTokens();
          throw _handleError(response);
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return json.decode(response.body)
            as Map<String, dynamic>;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi kết nối: ${e.toString()}',
      );
    }
  }

  /// Multipart POST request (for file uploads)
  /// Supports refresh token retry on 401
  Future<Map<String, dynamic>> uploadFiles(
    String endpoint, {
    required List<MultipartFile> files,
    Map<String, String>? fields,
    bool retryOn401 = true,
  }) async {
    Future<http.Response> sendRequest() async {
      final accessToken = await _tokenStorage.getAccessToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      for (final file in files) {
        request.files.add(
          await http.MultipartFile.fromPath(
            file.fieldName,
            file.file.path,
            contentType: http_parser.MediaType.parse(
              file.mimeType,
            ),
          ),
        );
      }

      final streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    }

    try {
      var response = await sendRequest();

      // Handle 401 Unauthorized - token expired
      if (response.statusCode == 401 && retryOn401) {
        try {
          await _refreshToken();
          response = await sendRequest();
        } catch (e) {
          await _tokenStorage.clearTokens();
          throw _handleError(response);
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return json.decode(response.body)
            as Map<String, dynamic>;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi upload: ${e.toString()}',
      );
    }
  }
}

/// Helper class for multipart file uploads
class MultipartFile {
  final String fieldName;
  final File file;
  final String mimeType;

  MultipartFile({
    required this.fieldName,
    required this.file,
    required this.mimeType,
  });
}
