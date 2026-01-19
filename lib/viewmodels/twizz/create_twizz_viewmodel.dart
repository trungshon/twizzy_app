import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/search_service/search_service.dart';
import '../../services/twizz_service/twizz_sync_service.dart';

/// Create Twizz ViewModel
///
/// Quản lý state và business logic cho màn hình tạo twizz
class CreateTwizzViewModel extends ChangeNotifier {
  final TwizzService _twizzService;
  final SearchService _searchService;
  final TwizzSyncService _syncService;

  CreateTwizzViewModel(
    this._twizzService,
    this._searchService,
    this._syncService,
  );

  // Media limits (từ backend)
  static const int maxImages = 4;
  static const int maxImageSizeBytes = 300 * 1024; // 300KB
  static const int maxTotalImageSizeBytes =
      300 * 1024 * 4; // 1.2MB
  static const int maxVideoSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int maxVideoDurationMinutes = 5;

  // State
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isSearchingUsers = false;
  String? _error;
  ApiErrorResponse? _apiError;
  TwizzAudience _audience = TwizzAudience.everyone;
  String _content = '';
  final List<File> _selectedImages = [];
  File? _selectedVideo;
  final List<Media> _uploadedMedias = [];
  final List<SearchUserResult> _mentionedUsers = [];
  List<SearchUserResult> _searchResults = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  bool get isSearchingUsers => _isSearchingUsers;
  String? get error => _error;
  ApiErrorResponse? get apiError => _apiError;

  /// Get detailed error message including validation errors
  String get detailedErrorMessage {
    if (_apiError == null) return _error ?? 'Có lỗi xảy ra';

    if (_apiError!.hasValidationErrors()) {
      // Get first validation error message
      final firstError = _apiError!.errors!.values.first;
      return firstError.msg;
    }

    return _apiError!.message;
  }

  TwizzAudience get audience => _audience;
  String get content => _content;
  List<File> get selectedImages => _selectedImages;
  File? get selectedVideo => _selectedVideo;
  List<Media> get uploadedMedias => _uploadedMedias;
  List<SearchUserResult> get mentionedUsers => _mentionedUsers;
  List<SearchUserResult> get searchResults => _searchResults;

  /// Check if can post
  bool get canPost {
    final hasContent = _content.trim().isNotEmpty;
    final hasMedia =
        _selectedImages.isNotEmpty || _selectedVideo != null;
    return (hasContent || hasMedia) &&
        !_isLoading &&
        !_isUploading;
  }

  /// Get audience display text
  String get audienceDisplayText {
    switch (_audience) {
      case TwizzAudience.everyone:
        return 'Tất cả mọi người';
      case TwizzAudience.twizzCircle:
        return 'Những người bạn cho phép';
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    _apiError = null;
    notifyListeners();
  }

  /// Set audience
  void setAudience(TwizzAudience audience) {
    _audience = audience;
    notifyListeners();
  }

  /// Update content
  void updateContent(String value) {
    _content = value;
    notifyListeners();
  }

  /// Add images with size validation
  Future<void> addImages(List<File> images) async {
    _error = null;

    // Nếu đã có video thì không thể thêm ảnh
    if (_selectedVideo != null) {
      _error = 'Không thể thêm ảnh khi đã có video';
      notifyListeners();
      return;
    }

    // Giới hạn tối đa 4 ảnh
    final remainingSlots = maxImages - _selectedImages.length;
    if (remainingSlots <= 0) {
      _error = 'Chỉ có thể đăng tối đa $maxImages ảnh';
      notifyListeners();
      return;
    }

    final imagesToAdd = <File>[];
    final oversizedImages = <String>[];

    for (final image in images.take(remainingSlots)) {
      final fileSize = await image.length();
      if (fileSize > maxImageSizeBytes) {
        final fileName = image.path.split('/').last;
        final fileSizeKB = (fileSize / 1024).toStringAsFixed(1);
        oversizedImages.add('$fileName (${fileSizeKB}KB)');
      } else {
        imagesToAdd.add(image);
      }
    }

    // Kiểm tra tổng dung lượng
    if (imagesToAdd.isNotEmpty) {
      int totalSize = 0;
      for (final img in _selectedImages) {
        totalSize += await img.length();
      }
      for (final img in imagesToAdd) {
        totalSize += await img.length();
      }

      if (totalSize > maxTotalImageSizeBytes) {
        final totalSizeMB = (totalSize / (1024 * 1024))
            .toStringAsFixed(2);
        _error =
            'Tổng dung lượng ảnh vượt quá 1.2MB (hiện tại: ${totalSizeMB}MB)';
        notifyListeners();
        return;
      }
    }

    if (oversizedImages.isNotEmpty) {
      final maxSizeKB = maxImageSizeBytes ~/ 1024;
      _error =
          'Ảnh vượt quá ${maxSizeKB}KB: ${oversizedImages.join(", ")}';
    }

    if (imagesToAdd.isNotEmpty) {
      _selectedImages.addAll(imagesToAdd);
    }

    notifyListeners();
  }

  /// Remove image at index
  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  /// Set video with size validation
  Future<void> setVideo(File video) async {
    _error = null;

    // Nếu đã có ảnh thì không thể thêm video
    if (_selectedImages.isNotEmpty) {
      _error = 'Không thể thêm video khi đã có ảnh';
      notifyListeners();
      return;
    }

    // Kiểm tra dung lượng video
    final fileSize = await video.length();
    if (fileSize > maxVideoSizeBytes) {
      final fileSizeMB = (fileSize / (1024 * 1024))
          .toStringAsFixed(1);
      final maxSizeMB = maxVideoSizeBytes ~/ (1024 * 1024);
      _error =
          'Video vượt quá ${maxSizeMB}MB (hiện tại: ${fileSizeMB}MB)';
      notifyListeners();
      return;
    }

    _selectedVideo = video;
    notifyListeners();
  }

  /// Remove video
  void removeVideo() {
    _selectedVideo = null;
    notifyListeners();
  }

  /// Add mentioned user
  void addMention(SearchUserResult user) {
    // Check if already mentioned
    if (_mentionedUsers.any((u) => u.id == user.id)) {
      return;
    }
    _mentionedUsers.add(user);
    _searchResults = [];
    notifyListeners();
  }

  /// Remove mentioned user
  void removeMention(String userId) {
    _mentionedUsers.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  /// Search users for mention
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearchingUsers = true;
    notifyListeners();

    try {
      final response = await _searchService.searchUsers(
        content: query,
        limit: 10,
      );
      _searchResults = response.users;
    } catch (e) {
      _searchResults = [];
      debugPrint('Search users error: $e');
    } finally {
      _isSearchingUsers = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  /// Extract hashtags from content
  List<String> _extractHashtags() {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(_content);
    return matches.map((m) => m.group(1)!).toList();
  }

  /// Upload all media files
  Future<bool> _uploadMedias() async {
    _uploadedMedias.clear();

    try {
      // Upload images
      if (_selectedImages.isNotEmpty) {
        final uploadedImages = await _twizzService.uploadImages(
          _selectedImages,
        );
        _uploadedMedias.addAll(uploadedImages);
      }

      // Upload video
      if (_selectedVideo != null) {
        final uploadedVideos = await _twizzService.uploadVideo(
          _selectedVideo!,
        );
        _uploadedMedias.addAll(uploadedVideos);
      }

      return true;
    } catch (e) {
      if (e is ApiErrorResponse) {
        _apiError = e;
        _error = e.message;
      } else {
        _apiError = null;
        _error = 'Lỗi tải media: ${e.toString()}';
      }
      return false;
    }
  }

  /// Create twizz
  Future<Twizz?> createTwizz() async {
    if (!canPost) return null;

    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      // Upload media first
      if (_selectedImages.isNotEmpty || _selectedVideo != null) {
        _isUploading = true;
        notifyListeners();

        final uploadSuccess = await _uploadMedias();
        _isUploading = false;
        notifyListeners();

        if (!uploadSuccess) {
          _isLoading = false;
          notifyListeners();
          return null;
        }
      }

      // Extract hashtags
      final hashtags = _extractHashtags();

      // Get mention user IDs
      final mentionIds =
          _mentionedUsers.map((u) => u.id).toList();

      // Create request
      final request = CreateTwizzRequest(
        audience: _audience,
        content: _content,
        hashtags: hashtags,
        mentions: mentionIds,
        medias: _uploadedMedias,
      );

      final response = await _twizzService.createTwizz(request);

      _isLoading = false;
      notifyListeners();

      // Reset state
      _reset();

      // Emit sync event
      _syncService.emitCreate(response.result);

      return response.result;
    } catch (e) {
      _isLoading = false;
      if (e is ApiErrorResponse) {
        _apiError = e;
        _error = e.message;
      } else {
        _apiError = null;
        _error = 'Lỗi đăng bài: ${e.toString()}';
      }
      notifyListeners();
      return null;
    }
  }

  /// Reset all state
  void _reset() {
    _content = '';
    _selectedImages.clear();
    _selectedVideo = null;
    _uploadedMedias.clear();
    _mentionedUsers.clear();
    _searchResults.clear();
    _audience = TwizzAudience.everyone;
  }

  /// Dispose and reset
  void clear() {
    _reset();
    _isLoading = false;
    _isUploading = false;
    _isSearchingUsers = false;
    _error = null;
    _apiError = null;
    notifyListeners();
  }
}
