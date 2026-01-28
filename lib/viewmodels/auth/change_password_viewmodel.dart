import 'package:flutter/material.dart';
import '../../models/auth/auth_models.dart';
import '../../services/auth_service/auth_service.dart';

/// Change Password ViewModel
class ChangePasswordViewModel extends ChangeNotifier {
  final AuthService _authService;

  ChangePasswordViewModel(this._authService);

  // State
  bool _isLoading = false;
  String? _error;
  ApiErrorResponse? _apiError;

  bool _isPasswordVisible = false;
  bool _isOldPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final TextEditingController _oldPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  ApiErrorResponse? get apiError => _apiError;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isOldPasswordVisible => _isOldPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;

  TextEditingController get oldPasswordController =>
      _oldPasswordController;
  TextEditingController get newPasswordController =>
      _newPasswordController;
  TextEditingController get confirmPasswordController =>
      _confirmPasswordController;

  /// Toggle password visibility
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleOldPasswordVisibility() {
    _isOldPasswordVisible = !_isOldPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  /// Change Password
  Future<bool> changePassword() async {
    // Validation
    if (_oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _error = 'Vui lòng điền đầy đủ thông tin';
      notifyListeners();
      return false;
    }

    if (_newPasswordController.text.length < 8) {
      _error = 'Mật khẩu mới phải có ít nhất 8 ký tự';
      notifyListeners();
      return false;
    }

    if (_newPasswordController.text !=
        _confirmPasswordController.text) {
      _error = 'Mật khẩu xác nhận không khớp';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      final request = ChangePasswordRequest(
        oldPassword: _oldPasswordController.text,
        password: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      await _authService.changePassword(request);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        _error = e.message;
      } else {
        _error = 'Lỗi đổi mật khẩu: ${e.toString()}';
      }
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void clear() {
    _isLoading = false;
    _error = null;
    _apiError = null;
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _isPasswordVisible = false;
    _isOldPasswordVisible = false;
    _isConfirmPasswordVisible = false;
    notifyListeners();
  }
}
