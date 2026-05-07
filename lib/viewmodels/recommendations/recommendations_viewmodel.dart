import 'package:flutter/foundation.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';
import '../../services/twizz_service/twizz_sync_service.dart';

/// Recommendations ViewModel
///
/// ViewModel quản lý state của tab Đề xuất (For You)
class RecommendationsViewModel extends ChangeNotifier {
  final TwizzService _twizzService;
  final LikeService _likeService;
  final BookmarkService _bookmarkService;
  final TwizzSyncService _syncService;

  RecommendationsViewModel(
    this._twizzService,
    this._likeService,
    this._bookmarkService,
    this._syncService,
  ) {
    _syncService.eventStream.listen(_handleSyncEvent);
  }

  void _handleSyncEvent(TwizzSyncEvent event) {
    if (event.type == TwizzSyncEventType.update && event.twizz != null) {
      final updatedTwizz = event.twizz!;
      _updateTwizzState(
        updatedTwizz.id,
        isLiked: updatedTwizz.isLiked,
        likes: updatedTwizz.likes,
        isBookmarked: updatedTwizz.isBookmarked,
        bookmarks: updatedTwizz.bookmarks,
        commentCount: updatedTwizz.commentCount,
        quoteCount: updatedTwizz.quoteCount,
        userViews: updatedTwizz.userViews,
        guestViews: updatedTwizz.guestViews,
        broadcast: false,
      );
    } else if (event.type == TwizzSyncEventType.delete && event.twizzId != null) {
      _twizzs.removeWhere(
        (t) => t.id == event.twizzId || t.parentTwizz?.id == event.twizzId,
      );
      notifyListeners();
    }
  }

  // State
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  ApiErrorResponse? _apiError;
  final List<Twizz> _twizzs = [];
  int _currentPage = 1;
  int _totalPage = 0;
  static const int _limit = 20;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  ApiErrorResponse? get apiError => _apiError;
  List<Twizz> get twizzs => _twizzs;
  bool get hasMore => _currentPage <= _totalPage;

  /// Load trang đầu tiên
  Future<void> loadRecommendations({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _totalPage = 0;
      _twizzs.clear();
    }

    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      final response = await _twizzService.getRecommendations(
        limit: _limit,
        page: _currentPage,
      );

      _twizzs.addAll(response.twizzs);
      _totalPage = response.totalPage;
      // Dùng page thực tế từ server để tránh lệch khi pool bị làm mới
      _currentPage = response.page + 1;
    } catch (e) {
      if (e is ApiErrorResponse) {
        _apiError = e;
        _error = e.message;
      } else {
        _error = 'Lỗi tải bài viết đề xuất: ${e.toString()}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load thêm (infinite scroll).
  ///
  /// Khi pool 60 bài bị lướt hết, backend tự tính lại pool mới và trả về
  /// page=1 của pool mới. ViewModel phát hiện qua response.page và điều chỉnh
  /// _currentPage, sau đó tiếp tục append (không xóa list đã có).
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _twizzService.getRecommendations(
        limit: _limit,
        page: _currentPage,
      );

      _twizzs.addAll(response.twizzs);
      _totalPage = response.totalPage;
      // Nếu server trả pool mới (response.page < _currentPage),
      // reset _currentPage theo page thực tế để đồng bộ
      _currentPage = response.page + 1;
    } catch (e) {
      debugPrint('Load more recommendations error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh
  Future<void> refresh() async {
    await loadRecommendations(refresh: true);
  }

  /// Like
  Future<void> toggleLike(Twizz twizz) async {
    if (twizz.isLiked) {
      await _unlikeTwizz(twizz);
    } else {
      await _likeTwizz(twizz);
    }
  }

  Future<void> _likeTwizz(Twizz twizz) async {
    if (twizz.isLiked) return;
    _updateTwizzState(twizz.id, isLiked: true, likes: (twizz.likes ?? 0) + 1);
    try {
      await _likeService.likeTwizz(twizz.id);
    } catch (e) {
      _updateTwizzState(twizz.id, isLiked: false, likes: twizz.likes);
      if (e is ApiErrorResponse) debugPrint('Like error: ${e.message}');
    }
  }

  Future<void> _unlikeTwizz(Twizz twizz) async {
    if (!twizz.isLiked) return;
    _updateTwizzState(twizz.id, isLiked: false, likes: (twizz.likes ?? 1) - 1);
    try {
      await _likeService.unlikeTwizz(twizz.id);
    } catch (e) {
      _updateTwizzState(twizz.id, isLiked: true, likes: twizz.likes);
      if (e is ApiErrorResponse) debugPrint('Unlike error: ${e.message}');
    }
  }

  /// Bookmark
  Future<void> toggleBookmark(Twizz twizz) async {
    if (twizz.isBookmarked) {
      await _unbookmarkTwizz(twizz);
    } else {
      await _bookmarkTwizz(twizz);
    }
  }

  Future<void> _bookmarkTwizz(Twizz twizz) async {
    if (twizz.isBookmarked) return;
    _updateTwizzState(twizz.id, isBookmarked: true, bookmarks: (twizz.bookmarks ?? 0) + 1);
    try {
      await _bookmarkService.bookmarkTwizz(twizz.id);
    } catch (e) {
      _updateTwizzState(twizz.id, isBookmarked: false, bookmarks: twizz.bookmarks);
      if (e is ApiErrorResponse) debugPrint('Bookmark error: ${e.message}');
    }
  }

  Future<void> _unbookmarkTwizz(Twizz twizz) async {
    if (!twizz.isBookmarked) return;
    _updateTwizzState(twizz.id, isBookmarked: false, bookmarks: (twizz.bookmarks ?? 1) - 1);
    try {
      await _bookmarkService.unbookmarkTwizz(twizz.id);
    } catch (e) {
      _updateTwizzState(twizz.id, isBookmarked: true, bookmarks: twizz.bookmarks);
      if (e is ApiErrorResponse) debugPrint('Unbookmark error: ${e.message}');
    }
  }

  /// Delete
  Future<bool> deleteTwizz(Twizz twizz) async {
    try {
      await _twizzService.deleteTwizz(twizz.id);
      _twizzs.removeWhere((t) => t.id == twizz.id);
      _syncService.emitDelete(twizz.id);
      notifyListeners();
      return true;
    } catch (e) {
      if (e is ApiErrorResponse) debugPrint('Delete error: ${e.message}');
      return false;
    }
  }

  /// Clear tất cả state (khi logout)
  void clear() {
    _twizzs.clear();
    _currentPage = 1;
    _totalPage = 0;
    _error = null;
    _apiError = null;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  void _updateTwizzState(
    String id, {
    bool? isLiked,
    int? likes,
    bool? isBookmarked,
    int? bookmarks,
    int? commentCount,
    int? quoteCount,
    int? userViews,
    int? guestViews,
    bool broadcast = true,
  }) {
    bool modified = false;
    for (int i = 0; i < _twizzs.length; i++) {
      if (_twizzs[i].id == id) {
        _twizzs[i] = _twizzs[i].copyWith(
          isLiked: isLiked,
          likes: likes,
          isBookmarked: isBookmarked,
          bookmarks: bookmarks,
          commentCount: commentCount,
          quoteCount: quoteCount,
          userViews: userViews,
          guestViews: guestViews,
        );
        modified = true;
        if (broadcast) _syncService.emitUpdate(_twizzs[i]);
      }
      if (_twizzs[i].parentTwizz?.id == id) {
        _twizzs[i] = _twizzs[i].copyWith(
          parentTwizz: _twizzs[i].parentTwizz!.copyWith(
            isLiked: isLiked,
            likes: likes,
            isBookmarked: isBookmarked,
            bookmarks: bookmarks,
            commentCount: commentCount,
            quoteCount: quoteCount,
            userViews: userViews,
            guestViews: guestViews,
          ),
        );
        modified = true;
        if (broadcast) _syncService.emitUpdate(_twizzs[i].parentTwizz!);
      }
    }
    if (modified) notifyListeners();
  }
}
