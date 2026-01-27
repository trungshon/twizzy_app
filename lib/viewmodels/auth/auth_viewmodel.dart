import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/auth/auth_models.dart';
import '../../services/auth_service/auth_service.dart';
import '../../services/google_auth/google_auth_service.dart';
import '../../services/socket_service/socket_service.dart';

/// Auth ViewModel
///
/// Quản lý state và business logic cho authentication
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final SocketService _socketService;

  AuthViewModel(this._authService, this._socketService);

  // State
  bool _isLoading = false;
  String? _error;
  ApiErrorResponse? _apiError;
  bool _isRegistered = false;
  String? _registeredEmail;
  User? _currentUser;
  String? _accessToken;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  ApiErrorResponse? get apiError => _apiError;
  bool get isRegistered => _isRegistered;
  String? get registeredEmail => _registeredEmail;
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;

  /// Clear error
  void clearError() {
    _error = null;
    _apiError = null;
    notifyListeners();
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String dateOfBirth,
  }) async {
    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        dateOfBirth: dateOfBirth,
      );

      final registerResponse = await _authService.register(
        request,
      );
      _accessToken = registerResponse.result.accessToken;

      // Load user info
      await getMe();

      _isRegistered = true;
      _registeredEmail = email;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        // If it's a validation error, use the first field error message
        if (e.hasValidationErrors()) {
          final firstError = e.errors!.values.first;
          _error = firstError.msg;
        } else {
          _error = e.message;
        }
      } else {
        _error = 'Có lỗi xảy ra khi đăng ký';
      }
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      final request = LoginRequest(
        email: email,
        password: password,
      );

      final loginResponse = await _authService.login(request);
      _accessToken = loginResponse.result.accessToken;

      // Load user info immediately after login
      await getMe();

      debugPrint(
        'Login successful, connecting socket for user...',
      );

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        // If it's a validation error, use the first field error message
        if (e.hasValidationErrors()) {
          final firstError = e.errors!.values.first;
          _error = firstError.msg;
        } else {
          _error = e.message;
        }
      } else {
        _error = 'Có lỗi xảy ra khi đăng nhập';
      }
      notifyListeners();
      return false;
    }
  }

  /// Verify email with OTP
  Future<bool> verifyEmail(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyEmail(email, otp);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _error = e.message;
      } else {
        _error = 'Có lỗi xảy ra khi xác nhận email';
      }
      notifyListeners();
      return false;
    }
  }

  /// Resend verify email
  Future<bool> resendVerifyEmail() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resendVerifyEmail();

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _error = e.message;
      } else {
        _error = 'Có lỗi xảy ra khi gửi lại email';
      }
      notifyListeners();
      return false;
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      await _authService.refreshToken();
      _accessToken = await _authService.getAccessToken();
      if (_accessToken != null) {
        _socketService.connect(_accessToken!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        _error = e.message;
      } else {
        _error = 'Có lỗi xảy ra khi refresh token';
      }
      notifyListeners();
      return false;
    }
  }

  /// Get current user info
  Future<bool> getMe() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.getMe();
      _currentUser = response.result;
      _accessToken = await _authService.getAccessToken();
      if (_accessToken != null) {
        _socketService.connect(_accessToken!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _error = e.message;
      } else {
        _error = 'Có lỗi xảy ra khi lấy thông tin user';
      }
      notifyListeners();
      return false;
    }
  }

  /// Forgot password - send OTP
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        if (e.hasValidationErrors()) {
          final firstError = e.errors!.values.first;
          _error = firstError.msg;
        } else {
          _error = e.message;
        }
      } else {
        _error = 'Có lỗi xảy ra khi gửi OTP';
      }
      notifyListeners();
      return false;
    }
  }

  /// Verify forgot password OTP
  Future<bool> verifyForgotPassword(
    String email,
    String otp,
  ) async {
    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      await _authService.verifyForgotPassword(email, otp);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        if (e.hasValidationErrors()) {
          final firstError = e.errors!.values.first;
          _error = firstError.msg;
        } else {
          _error = e.message;
        }
      } else {
        _error = 'Có lỗi xảy ra khi xác nhận OTP';
      }
      notifyListeners();
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      await _authService.resetPassword(
        email,
        otp,
        password,
        confirmPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        if (e.hasValidationErrors()) {
          final firstError = e.errors!.values.first;
          _error = firstError.msg;
        } else {
          _error = e.message;
        }
      } else {
        _error = 'Có lỗi xảy ra khi đặt lại mật khẩu';
      }
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    debugPrint('Logging out and disconnecting socket...');
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _socketService.disconnect();
      _currentUser = null;
      _isRegistered = false;
      _registeredEmail = null;
    } catch (e) {
      // Log error but still clear state
      debugPrint('Logout error: $e');
    } finally {
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }

  /// Reset state
  void reset() {
    _isLoading = false;
    _error = null;
    _isRegistered = false;
    _registeredEmail = null;
    _currentUser = null;
    notifyListeners();
  }

  /// Update username
  Future<bool> updateUsername(String username) async {
    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      final request = UpdateProfileRequest(username: username);
      await _authService.updateMe(request);

      // Refresh current user info
      await getMe();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        if (e.hasValidationErrors()) {
          final firstError = e.errors!.values.first;
          _error = firstError.msg;
        } else {
          _error = e.message;
        }
      } else {
        _error = 'Có lỗi xảy ra khi cập nhật username';
      }
      notifyListeners();
      return false;
    }
  }

  /// Google Sign-In
  ///
  /// Returns:
  /// - 'success' if login successful
  /// - 'new_user' if new user registered (may need email verification)
  /// - 'cancelled' if user cancelled
  /// - null if error
  Future<String?> googleSignIn() async {
    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      // Step 1: Sign in with Google native
      final googleAuthService = GoogleAuthService();
      final result = await googleAuthService.signIn();

      if (result == null) {
        // User cancelled
        _isLoading = false;
        notifyListeners();
        return 'cancelled';
      }

      if (result.idToken == null) {
        _isLoading = false;
        _error = 'Không thể lấy ID token từ Google';
        notifyListeners();
        return null;
      }

      // Step 2: Send ID token to backend
      final response = await _authService.googleOAuthMobile(
        result.idToken!,
      );

      _isLoading = false;
      notifyListeners();

      if (response.result.isNewUser) {
        _registeredEmail = result.email;
        return 'new_user';
      }
      _accessToken = response.result.accessToken;

      // Load user info
      await getMe();

      return 'success';
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        _error = e.message;
      } else {
        _error = 'Có lỗi xảy ra khi đăng nhập bằng Google';
      }
      notifyListeners();
      return null;
    }
  }

  /// Google Sign-Out
  Future<void> googleSignOut() async {
    try {
      final googleAuthService = GoogleAuthService();
      await googleAuthService.signOut();
    } catch (e) {
      debugPrint('Google sign out error: $e');
    }
  }

  /// Add user to Twizz Circle
  Future<bool> addToTwizzCircle(User user) async {
    if (_currentUser == null) {
      return false;
    }

    try {
      // Get current circle IDs
      final currentCircle = _currentUser!.twizzCircle ?? [];

      // Check if user is already in circle
      if (currentCircle.any((u) => u.id == user.id)) {
        return true; // Already in circle
      }

      // Add new user ID to the list
      final newCircleIds = [
        ...currentCircle.map((u) => u.id),
        user.id,
      ];

      // Update on server
      final response = await _authService.updateTwizzCircle(
        newCircleIds,
      );

      // Update local state from server response
      _currentUser = response.result;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is ApiErrorResponse) {
        _error = e.message;
      } else {
        _error = 'Lỗi thêm vào Twizz Circle';
      }
      notifyListeners();
      return false;
    }
  }

  /// Remove user from Twizz Circle
  Future<bool> removeFromTwizzCircle(User user) async {
    if (_currentUser == null) return false;

    try {
      // Get current circle
      final currentCircle = _currentUser!.twizzCircle ?? [];

      // Remove user from circle
      final newCircle =
          currentCircle.where((u) => u.id != user.id).toList();
      final newCircleIds = newCircle.map((u) => u.id).toList();

      // Update on server
      final response = await _authService.updateTwizzCircle(
        newCircleIds,
      );

      // Update local state from server response
      _currentUser = response.result;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is ApiErrorResponse) {
        _error = e.message;
      } else {
        _error = 'Lỗi xóa khỏi Twizz Circle';
      }
      notifyListeners();
      return false;
    }
  }
}
