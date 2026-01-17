import 'package:flutter/foundation.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';

/// NewsFeed ViewModel
///
/// ViewModel quản lý state của newsfeed
class NewsFeedViewModel extends ChangeNotifier {
  final TwizzService _twizzService;
  final LikeService _likeService;
  final BookmarkService _bookmarkService;

  NewsFeedViewModel(
    this._twizzService,
    this._likeService,
    this._bookmarkService,
  );

  // State
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  ApiErrorResponse? _apiError;
  final List<Twizz> _twizzs = [];
  int _currentPage = 1;
  int _totalPage = 0;
  static const int _limit = 10;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  ApiErrorResponse? get apiError => _apiError;
  List<Twizz> get twizzs => _twizzs;
  bool get hasMore => _currentPage <= _totalPage;

  /// Load initial newsfeed
  Future<void> loadNewsFeed({bool refresh = false}) async {
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
      final response = await _twizzService.getNewFeeds(
        limit: _limit,
        page: _currentPage,
      );

      _twizzs.addAll(response.twizzs);
      _totalPage = response.totalPage;
      _currentPage++;
    } catch (e) {
      if (e is ApiErrorResponse) {
        _apiError = e;
        _error = e.message;
      } else {
        _error = 'Lỗi tải bài viết: ${e.toString()}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more twizzs (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _twizzService.getNewFeeds(
        limit: _limit,
        page: _currentPage,
      );

      _twizzs.addAll(response.twizzs);
      _totalPage = response.totalPage;
      _currentPage++;
    } catch (e) {
      debugPrint('Load more error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh newsfeed
  Future<void> refresh() async {
    await loadNewsFeed(refresh: true);
  }

  /// Add new twizz to top of list
  void addTwizz(Twizz twizz) {
    _twizzs.insert(0, twizz);
    notifyListeners();
  }

  /// Like a twizz
  Future<void> likeTwizz(Twizz twizz) async {
    if (twizz.isLiked) return; // Already liked

    // Optimistic update
    final index = _twizzs.indexWhere((t) => t.id == twizz.id);
    if (index == -1) return;

    _twizzs[index] = twizz.copyWith(
      isLiked: true,
      likes: (twizz.likes ?? 0) + 1,
    );
    notifyListeners();

    try {
      await _likeService.likeTwizz(twizz.id);
    } catch (e) {
      // Revert on error
      _twizzs[index] = twizz;
      notifyListeners();
      if (e is ApiErrorResponse) {
        debugPrint('Like error: ${e.message}');
      }
    }
  }

  /// Unlike a twizz
  Future<void> unlikeTwizz(Twizz twizz) async {
    if (!twizz.isLiked) return; // Not liked

    // Optimistic update
    final index = _twizzs.indexWhere((t) => t.id == twizz.id);
    if (index == -1) return;

    _twizzs[index] = twizz.copyWith(
      isLiked: false,
      likes: (twizz.likes ?? 1) - 1,
    );
    notifyListeners();

    try {
      await _likeService.unlikeTwizz(twizz.id);
    } catch (e) {
      // Revert on error
      _twizzs[index] = twizz;
      notifyListeners();
      if (e is ApiErrorResponse) {
        debugPrint('Unlike error: ${e.message}');
      }
    }
  }

  /// Toggle like status
  Future<void> toggleLike(Twizz twizz) async {
    if (twizz.isLiked) {
      await unlikeTwizz(twizz);
    } else {
      await likeTwizz(twizz);
    }
  }

  /// Bookmark a twizz
  Future<void> bookmarkTwizz(Twizz twizz) async {
    if (twizz.isBookmarked) return; // Already bookmarked

    // Optimistic update
    final index = _twizzs.indexWhere((t) => t.id == twizz.id);
    if (index == -1) return;

    _twizzs[index] = twizz.copyWith(
      isBookmarked: true,
      bookmarks: (twizz.bookmarks ?? 0) + 1,
    );
    notifyListeners();

    try {
      await _bookmarkService.bookmarkTwizz(twizz.id);
    } catch (e) {
      // Revert on error
      _twizzs[index] = twizz;
      notifyListeners();
      if (e is ApiErrorResponse) {
        debugPrint('Bookmark error: ${e.message}');
      }
    }
  }

  /// Unbookmark a twizz
  Future<void> unbookmarkTwizz(Twizz twizz) async {
    if (!twizz.isBookmarked) return; // Not bookmarked

    // Optimistic update
    final index = _twizzs.indexWhere((t) => t.id == twizz.id);
    if (index == -1) return;

    _twizzs[index] = twizz.copyWith(
      isBookmarked: false,
      bookmarks: (twizz.bookmarks ?? 1) - 1,
    );
    notifyListeners();

    try {
      await _bookmarkService.unbookmarkTwizz(twizz.id);
    } catch (e) {
      // Revert on error
      _twizzs[index] = twizz;
      notifyListeners();
      if (e is ApiErrorResponse) {
        debugPrint('Unbookmark error: ${e.message}');
      }
    }
  }

  /// Toggle bookmark status
  Future<void> toggleBookmark(Twizz twizz) async {
    if (twizz.isBookmarked) {
      await unbookmarkTwizz(twizz);
    } else {
      await bookmarkTwizz(twizz);
    }
  }

  /// Clear all state
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
}
