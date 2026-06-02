import 'package:flutter/foundation.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';
import '../../services/twizz_service/twizz_sync_service.dart';
import '../../services/view_tracker/view_tracker_service.dart';

/// NewsFeed ViewModel
///
/// ViewModel quản lý state của newsfeed
class NewsFeedViewModel extends ChangeNotifier {
  final TwizzService _twizzService;
  final LikeService _likeService;
  final BookmarkService _bookmarkService;
  final TwizzSyncService _syncService;
  final ViewTrackerService _viewTracker;

  NewsFeedViewModel(
    this._twizzService,
    this._likeService,
    this._bookmarkService,
    this._syncService,
    this._viewTracker,
  ) {
    // Listen for sync events
    _syncService.eventStream.listen(_handleSyncEvent);
  }

  void _handleSyncEvent(TwizzSyncEvent event) {
    if (event.type == TwizzSyncEventType.update &&
        event.twizz != null) {
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
        mentions: updatedTwizz.mentions,
        content: updatedTwizz.content,
        broadcast: false, // Don't broadcast back
      );
    } else if (event.type == TwizzSyncEventType.delete &&
        event.twizzId != null) {
      // Remove the deleted post
      _twizzs.removeWhere(
        (t) =>
            t.id == event.twizzId ||
            t.parentTwizz?.id == event.twizzId,
      );
      notifyListeners();
    } else if (event.type == TwizzSyncEventType.create &&
        event.twizz != null) {
      final newTwizz = event.twizz!;
      // Only add if it's not already in the list
      if (!_twizzs.any((t) => t.id == newTwizz.id)) {
        _twizzs.insert(0, newTwizz);
        notifyListeners();
      }
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
  int _globalTotal = 0;
  static const int _limit = 10;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  ApiErrorResponse? get apiError => _apiError;
  List<Twizz> get twizzs => _twizzs;
  bool get hasMore => _currentPage <= _totalPage;
  int get globalTotal => _globalTotal;

  String? _sessionStart;

  /// Load initial newsfeed
  Future<void> loadNewsFeed({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      await _viewTracker.flushNow();
      _currentPage = 1;
      _totalPage = 0;
      _globalTotal = 0;
      _twizzs.clear();
      _sessionStart = DateTime.now().toUtc().toIso8601String();
    } else {
      _sessionStart ??= DateTime.now().toUtc().toIso8601String();
    }

    _isLoading = true;
    _error = null;
    _apiError = null;
    notifyListeners();

    try {
      final response = await _twizzService.getNewFeeds(
        limit: _limit,
        page: _currentPage,
        sessionStart: _sessionStart,
      );

      _twizzs.addAll(response.twizzs);
      _totalPage = response.totalPage;
      _globalTotal = response.globalTotal;
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
      // Ép gửi danh sách bài đã xem lên Backend trước khi load thêm
      await _viewTracker.flushNow();

      final response = await _twizzService.getNewFeeds(
        limit: _limit,
        page: _currentPage,
        sessionStart: _sessionStart,
      );

      _twizzs.addAll(response.twizzs);
      _totalPage = response.totalPage;
      _globalTotal = response.globalTotal;
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

  /// Report visibility for view tracking
  void reportVisibility(String twizzId, double fraction) {
    _viewTracker.reportVisibility(twizzId, fraction);
  }

  /// Reset viewed history and refresh
  Future<void> resetFollowingViews() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _twizzService.resetFollowingViews();
      // Clear local buffer as well
      await _viewTracker.flushNow();

      // Reset loading state so that refresh() can proceed
      _isLoading = false;

      // Reload feed
      await refresh();
    } catch (e) {
      if (e is ApiErrorResponse) {
        _error = e.message;
      } else {
        _error = 'Lỗi làm mới danh sách: ${e.toString()}';
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add new twizz to top of list
  void addTwizz(Twizz twizz) {
    if (!_twizzs.any((t) => t.id == twizz.id)) {
      _twizzs.insert(0, twizz);
      _syncService.emitCreate(twizz);
      notifyListeners();
    }
  }

  /// Like a twizz
  Future<void> likeTwizz(Twizz twizz) async {
    if (twizz.isLiked) return; // Already liked

    _updateTwizzState(
      twizz.id,
      isLiked: true,
      likes: (twizz.likes ?? 0) + 1,
    );
    // notifyListeners(); // Will be called by _updateTwizzState if broadcast is true

    try {
      await _likeService.likeTwizz(twizz.id);
    } catch (e) {
      // Revert on error
      _updateTwizzState(
        twizz.id,
        isLiked: false,
        likes: twizz.likes,
      );
      // notifyListeners(); // Will be called by _updateTwizzState if broadcast is true
      if (e is ApiErrorResponse) {
        debugPrint('Like error: ${e.message}');
      }
    }
  }

  /// Unlike a twizz
  Future<void> unlikeTwizz(Twizz twizz) async {
    if (!twizz.isLiked) return; // Not liked

    _updateTwizzState(
      twizz.id,
      isLiked: false,
      likes: (twizz.likes ?? 1) - 1,
    );
    // notifyListeners(); // Will be called by _updateTwizzState if broadcast is true

    try {
      await _likeService.unlikeTwizz(twizz.id);
    } catch (e) {
      // Revert on error
      _updateTwizzState(
        twizz.id,
        isLiked: true,
        likes: twizz.likes,
      );
      // notifyListeners(); // Will be called by _updateTwizzState if broadcast is true
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

    _updateTwizzState(
      twizz.id,
      isBookmarked: true,
      bookmarks: (twizz.bookmarks ?? 0) + 1,
    );
    // notifyListeners(); // Will be called by _updateTwizzState if broadcast is true

    try {
      await _bookmarkService.bookmarkTwizz(twizz.id);
    } catch (e) {
      // Revert on error
      _updateTwizzState(
        twizz.id,
        isBookmarked: false,
        bookmarks: twizz.bookmarks,
      );
      // notifyListeners(); // Will be called by _updateTwizzState if broadcast is true
      if (e is ApiErrorResponse) {
        debugPrint('Bookmark error: ${e.message}');
      }
    }
  }

  /// Unbookmark a twizz
  Future<void> unbookmarkTwizz(Twizz twizz) async {
    if (!twizz.isBookmarked) return; // Not bookmarked

    _updateTwizzState(
      twizz.id,
      isBookmarked: false,
      bookmarks: (twizz.bookmarks ?? 1) - 1,
    );
    // notifyListeners(); // Will be called by _updateTwizzState if broadcast is true

    try {
      await _bookmarkService.unbookmarkTwizz(twizz.id);
    } catch (e) {
      // Revert on error
      _updateTwizzState(
        twizz.id,
        isBookmarked: true,
        bookmarks: twizz.bookmarks,
      );
      // notifyListeners(); // Will be called by _updateTwizzState if broadcast is true
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

  /// Delete a twizz
  Future<bool> deleteTwizz(Twizz twizz) async {
    try {
      await _twizzService.deleteTwizz(twizz.id);

      // Remove from list
      _twizzs.removeWhere((t) => t.id == twizz.id);

      // Broadcast delete
      _syncService.emitDelete(twizz.id);

      notifyListeners();
      return true;
    } catch (e) {
      if (e is ApiErrorResponse) {
        debugPrint('Delete error: ${e.message}');
      } else {
        debugPrint('Delete error: $e');
      }
      return false;
    }
  }

  /// Clear all state
  void clear() {
    _viewTracker.flushNow();
    _twizzs.clear();
    _currentPage = 1;
    _totalPage = 0;
    _error = null;
    _apiError = null;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Update state for a twizz across all instances in the list
  /// (handles both top-level and nested parentTwizz)
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
    List<dynamic>? mentions,
    String? content,
    bool broadcast = true,
  }) {
    bool modified = false;
    for (int i = 0; i < _twizzs.length; i++) {
      // Update top-level
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
          mentions: mentions,
          content: content,
        );
        modified = true;

        if (broadcast) {
          _syncService.emitUpdate(_twizzs[i]);
        }
      }
      // Update nested parentTwizz
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
            mentions: mentions,
            content: content,
          ),
        );
        modified = true;

        if (broadcast) {
          _syncService.emitUpdate(_twizzs[i].parentTwizz!);
        }
      }
    }
    if (modified) {
      notifyListeners();
    }
  }
}
