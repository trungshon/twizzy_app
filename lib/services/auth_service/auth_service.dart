import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../models/auth/auth_models.dart';
import '../api/api_client.dart';
import '../local_storage/token_storage.dart';

/// Auth Service
///
/// Service xử lý authentication
class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService(this._apiClient, this._tokenStorage);

  /// Register new user
  Future<RegisterResponse> register(
    RegisterRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        body: request.toJson(),
      );

      final registerResponse = RegisterResponse.fromJson(
        response,
      );

      // Lưu tokens vào secure storage
      await _tokenStorage.saveAccessToken(
        registerResponse.result.accessToken,
      );
      await _tokenStorage.saveRefreshToken(
        registerResponse.result.refreshToken,
      );

      return registerResponse;
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi đăng ký: ${e.toString()}',
      );
    }
  }

  /// Login user
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        body: request.toJson(),
      );

      final loginResponse = LoginResponse.fromJson(response);

      // Lưu tokens vào secure storage
      await _tokenStorage.saveAccessToken(
        loginResponse.result.accessToken,
      );
      await _tokenStorage.saveRefreshToken(
        loginResponse.result.refreshToken,
      );

      return loginResponse;
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi đăng nhập: ${e.toString()}',
      );
    }
  }

  /// Verify email with OTP
  Future<VerifyEmailResponse> verifyEmail(
    String email,
    String emailVerifyOtp,
  ) async {
    try {
      final request = VerifyEmailRequest(
        email: email,
        emailVerifyOtp: emailVerifyOtp,
      );
      final response = await _apiClient.post(
        ApiConstants.verifyEmail,
        body: request.toJson(),
        includeAuth: false,
      );

      final verifyResponse = VerifyEmailResponse.fromJson(
        response,
      );

      // Cập nhật tokens nếu có
      if (verifyResponse.result != null) {
        await _tokenStorage.saveAccessToken(
          verifyResponse.result!.accessToken,
        );
        await _tokenStorage.saveRefreshToken(
          verifyResponse.result!.refreshToken,
        );
      }

      return verifyResponse;
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi xác nhận email: ${e.toString()}',
      );
    }
  }

  /// Resend verify email
  Future<void> resendVerifyEmail() async {
    try {
      await _apiClient.post(
        ApiConstants.resendVerifyEmail,
        includeAuth: true,
      );
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi gửi lại email xác nhận: ${e.toString()}',
      );
    }
  }

  /// Refresh access token
  Future<RefreshTokenResponse> refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        throw ApiErrorResponse(
          message: 'Không có refresh token',
          statusCode: 401,
        );
      }

      final request = RefreshTokenRequest(
        refreshToken: refreshToken,
      );
      final response = await _apiClient.post(
        ApiConstants.refreshToken,
        body: request.toJson(),
        includeAuth: false,
      );

      final refreshResponse = RefreshTokenResponse.fromJson(
        response,
      );

      // Lưu tokens mới vào secure storage
      await _tokenStorage.saveAccessToken(
        refreshResponse.result.accessToken,
      );
      await _tokenStorage.saveRefreshToken(
        refreshResponse.result.refreshToken,
      );

      return refreshResponse;
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi refresh token: ${e.toString()}',
      );
    }
  }

  /// Get current user info
  Future<GetMeResponse> getMe() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getMe,
        includeAuth: true,
      );

      return GetMeResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi lấy thông tin user: ${e.toString()}',
      );
    }
  }

  /// Update current user profile
  Future<UpdateMeResponse> updateMe(
    UpdateProfileRequest request,
  ) async {
    try {
      final response = await _apiClient.patch(
        ApiConstants.updateMe,
        body: request.toJson(),
        includeAuth: true,
      );

      return UpdateMeResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi cập nhật thông tin: ${e.toString()}',
      );
    }
  }

  /// Forgot password - send OTP to email
  Future<ForgotPasswordResponse> forgotPassword(
    String email,
  ) async {
    try {
      final request = ForgotPasswordRequest(email: email);
      final response = await _apiClient.post(
        ApiConstants.forgotPassword,
        body: request.toJson(),
        includeAuth: false,
      );

      return ForgotPasswordResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi quên mật khẩu: ${e.toString()}',
      );
    }
  }

  /// Verify forgot password OTP
  Future<VerifyForgotPasswordResponse> verifyForgotPassword(
    String email,
    String otp,
  ) async {
    try {
      final request = VerifyForgotPasswordRequest(
        email: email,
        forgotPasswordOtp: otp,
      );
      final response = await _apiClient.post(
        ApiConstants.verifyForgotPassword,
        body: request.toJson(),
        includeAuth: false,
      );

      return VerifyForgotPasswordResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi xác nhận OTP: ${e.toString()}',
      );
    }
  }

  /// Reset password
  Future<ResetPasswordResponse> resetPassword(
    String email,
    String otp,
    String password,
    String confirmPassword,
  ) async {
    try {
      final request = ResetPasswordRequest(
        email: email,
        forgotPasswordOtp: otp,
        password: password,
        confirmPassword: confirmPassword,
      );
      final response = await _apiClient.post(
        ApiConstants.resetPassword,
        body: request.toJson(),
        includeAuth: false,
      );

      return ResetPasswordResponse.fromJson(response);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi đặt lại mật khẩu: ${e.toString()}',
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post(
          ApiConstants.logout,
          body: {'refresh_token': refreshToken},
          includeAuth: true,
        );
      }
    } catch (e) {
      // Log error but still clear tokens
      debugPrint('Logout error: $e');
    } finally {
      // Xóa tokens dù API call thành công hay thất bại
      await _tokenStorage.clearTokens();
    }
  }

  /// Google OAuth Mobile - Send ID token to backend for verification
  Future<GoogleOAuthMobileResponse> googleOAuthMobile(
    String idToken,
  ) async {
    try {
      final request = GoogleOAuthMobileRequest(idToken: idToken);
      final response = await _apiClient.post(
        ApiConstants.googleOAuthMobile,
        body: request.toJson(),
        includeAuth: false,
      );

      final oauthResponse = GoogleOAuthMobileResponse.fromJson(
        response,
      );

      // Lưu tokens vào secure storage
      await _tokenStorage.saveAccessToken(
        oauthResponse.result.accessToken,
      );
      await _tokenStorage.saveRefreshToken(
        oauthResponse.result.refreshToken,
      );

      return oauthResponse;
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi đăng nhập bằng Google: ${e.toString()}',
      );
    }
  }

  /// Change Password
  Future<void> changePassword(
    ChangePasswordRequest request,
  ) async {
    try {
      await _apiClient.put(
        ApiConstants.changePassword,
        body: request.toJson(),
        includeAuth: true,
      );
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi đổi mật khẩu: ${e.toString()}',
      );
    }
  }

  /// Get user profile by username
  Future<User> getUserProfile(String username) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getUserProfile(username),
        includeAuth: true,
      );

      final result = response['result'] as Map<String, dynamic>;
      return User.fromJson(result);
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi lấy thông tin người dùng: ${e.toString()}',
      );
    }
  }

  /// Follow a user
  Future<void> followUser(String userId) async {
    try {
      await _apiClient.post(
        ApiConstants.followUser,
        body: {'followed_user_id': userId},
        includeAuth: true,
      );
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi theo dõi người dùng: ${e.toString()}',
      );
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String userId) async {
    try {
      await _apiClient.delete(
        ApiConstants.unfollowUser(userId),
        includeAuth: true,
      );
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message: 'Lỗi bỏ theo dõi người dùng: ${e.toString()}',
      );
    }
  }

  /// Get followers list
  Future<List<User>> getFollowers(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.getFollowers(userId)}?page=$page&limit=$limit',
        includeAuth: true,
      );

      final result = response['result'] as List;
      return result.map((e) => User.fromJson(e)).toList();
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message:
            'Lỗi lấy danh sách người theo dõi: ${e.toString()}',
      );
    }
  }

  /// Get following list
  Future<List<User>> getFollowing(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.getFollowing(userId)}?page=$page&limit=$limit',
        includeAuth: true,
      );

      final result = response['result'] as List;
      return result.map((e) => User.fromJson(e)).toList();
    } catch (e) {
      if (e is ApiErrorResponse) {
        rethrow;
      }
      throw ApiErrorResponse(
        message:
            'Lỗi lấy danh sách đang theo dõi: ${e.toString()}',
      );
    }
  }
}
