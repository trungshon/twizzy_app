import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/auth/auth_models.dart';
import '../../services/auth_service/auth_service.dart';
import '../../services/twizz_service/twizz_service.dart';

/// Edit Profile ViewModel
///
/// Quản lý state và business logic cho màn hình chỉnh sửa profile
class EditProfileViewModel extends ChangeNotifier {
  final AuthService _authService;
  final TwizzService _twizzService;

  EditProfileViewModel(this._authService, this._twizzService);

  // State
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _error;
  ApiErrorResponse? _apiError;

  // Form fields
  String? _name;
  String? _bio;
  String? _location;
  String? _website;
  DateTime? _dateOfBirth;
  String? _avatar;
  String? _coverPhoto;
  String? _username;

  // Getters
  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  String? get error => _error;
  ApiErrorResponse? get apiError => _apiError;
  String? get name => _name;
  String? get bio => _bio;
  String? get location => _location;
  String? get website => _website;
  DateTime? get dateOfBirth => _dateOfBirth;
  String? get avatar => _avatar;
  String? get coverPhoto => _coverPhoto;
  String? get username => _username;

  /// Initialize form with current user data
  void initialize(User user) {
    _name = user.name;
    _bio = user.bio;
    _location = user.location;
    _website = user.website;
    _dateOfBirth = user.dateOfBirth;
    _avatar = user.avatar;
    _coverPhoto = user.coverPhoto;
    _username = user.username;
    _error = null;
    _apiError = null;
    notifyListeners();
  }

  /// Update name
  void updateName(String? value) {
    _name = value;
    notifyListeners();
  }

  /// Update bio
  void updateBio(String? value) {
    _bio = value;
    notifyListeners();
  }

  /// Update location
  void updateLocation(String? value) {
    _location = value;
    notifyListeners();
  }

  /// Update website
  void updateWebsite(String? value) {
    _website = value;
    notifyListeners();
  }

  /// Update date of birth
  void updateDateOfBirth(DateTime? value) {
    _dateOfBirth = value;
    notifyListeners();
  }

  /// Update avatar
  void updateAvatar(String? value) {
    _avatar = value;
    notifyListeners();
  }

  /// Update cover photo
  void updateCoverPhoto(String? value) {
    _coverPhoto = value;
    notifyListeners();
  }

  /// Update username
  void updateUsername(String? value) {
    _username = value;
    notifyListeners();
  }

  /// Upload avatar image
  Future<String?> uploadAvatar(File imageFile) async {
    _isUploadingImage = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      final medias = await _twizzService.uploadImages([
        imageFile,
      ]);
      if (medias.isNotEmpty) {
        final imageUrl = medias.first.url;
        _avatar = imageUrl;
        _isUploadingImage = false;
        notifyListeners();
        return imageUrl;
      }
      _isUploadingImage = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isUploadingImage = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        _error = e.message;
      } else {
        _error = 'Lỗi tải ảnh đại diện: ${e.toString()}';
      }
      notifyListeners();
      return null;
    }
  }

  /// Upload cover photo image
  Future<String?> uploadCoverPhoto(File imageFile) async {
    _isUploadingImage = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      final medias = await _twizzService.uploadImages([
        imageFile,
      ]);
      if (medias.isNotEmpty) {
        final imageUrl = medias.first.url;
        _coverPhoto = imageUrl;
        _isUploadingImage = false;
        notifyListeners();
        return imageUrl;
      }
      _isUploadingImage = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isUploadingImage = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        _error = e.message;
      } else {
        _error = 'Lỗi tải ảnh bìa: ${e.toString()}';
      }
      notifyListeners();
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    _apiError = null;
    notifyListeners();
  }

  /// Check if form has changes
  bool hasChanges(User originalUser) {
    return _name != originalUser.name ||
        _bio != originalUser.bio ||
        _location != originalUser.location ||
        _website != originalUser.website ||
        _dateOfBirth != originalUser.dateOfBirth ||
        _avatar != originalUser.avatar ||
        _coverPhoto != originalUser.coverPhoto ||
        _username != originalUser.username;
  }

  /// Update profile - only send changed fields
  Future<User?> updateProfile(User originalUser) async {
    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      // Helper function to check if a string value has changed
      bool hasStringChanged(String? newValue, String? oldValue) {
        final newVal = newValue?.trim() ?? '';
        final oldVal = oldValue?.trim() ?? '';
        return newVal != oldVal;
      }

      // Helper function to check if date has changed
      bool hasDateChanged(
        DateTime? newValue,
        DateTime oldValue,
      ) {
        if (newValue == null) return false;
        return newValue.year != oldValue.year ||
            newValue.month != oldValue.month ||
            newValue.day != oldValue.day;
      }

      // Build request with only changed fields
      final request = UpdateProfileRequest(
        // Only include name if it changed
        name:
            hasStringChanged(_name, originalUser.name)
                ? _name
                : null,
        // Only include bio if it changed
        bio:
            hasStringChanged(_bio, originalUser.bio)
                ? _bio
                : null,
        // Only include location if it changed
        location:
            hasStringChanged(_location, originalUser.location)
                ? _location
                : null,
        // Only include website if it changed
        website:
            hasStringChanged(_website, originalUser.website)
                ? _website
                : null,
        // Only include dateOfBirth if it changed
        dateOfBirth:
            hasDateChanged(
                  _dateOfBirth,
                  originalUser.dateOfBirth,
                )
                ? (_dateOfBirth != null
                    ? _dateOfBirth!.toIso8601String().split(
                      'T',
                    )[0]
                    : null)
                : null,
        // Only include avatar if it changed
        avatar:
            hasStringChanged(_avatar, originalUser.avatar)
                ? _avatar
                : null,
        // Only include coverPhoto if it changed
        coverPhoto:
            hasStringChanged(
                  _coverPhoto,
                  originalUser.coverPhoto,
                )
                ? _coverPhoto
                : null,
        // Only include username if it changed
        username:
            hasStringChanged(_username, originalUser.username)
                ? _username
                : null,
      );

      final response = await _authService.updateMe(request);
      _isLoading = false;
      notifyListeners();
      return response.result;
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
        _error = 'Có lỗi xảy ra khi cập nhật thông tin';
      }
      notifyListeners();
      return null;
    }
  }
}
