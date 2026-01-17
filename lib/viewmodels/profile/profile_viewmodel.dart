import 'package:flutter/foundation.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';

/// Profile ViewModel
///
/// ViewModel quản lý state của profile screen với các tabs khác nhau
class ProfileViewModel extends ChangeNotifier {
  final TwizzService _twizzService;
  final LikeService _likeService;
  final BookmarkService _bookmarkService;

  ProfileViewModel(
    this._twizzService,
    this._likeService,
    this._bookmarkService,
  );

  // State for each tab
  final Map<int, List<Twizz>> _twizzsByTab = {};
  final Map<int, bool> _isLoadingByTab = {};
  final Map<int, bool> _isLoadingMoreByTab = {};
  final Map<int, String?> _errorByTab = {};
  final Map<int, int> _currentPageByTab = {};
  final Map<int, int> _totalPageByTab = {};
  static const int _limit = 10;

  // Tab indices
  static const int tabTwizz = 0;
  static const int tabRetwizz = 1;
  static const int tabQuoteTwizz = 2;
  static const int tabLiked = 3;
  static const int tabBookmarked = 4;

  // Getters
  List<Twizz> getTwizzs(int tabIndex) =>
      _twizzsByTab[tabIndex] ?? [];
  bool isLoading(int tabIndex) =>
      _isLoadingByTab[tabIndex] ?? false;
  bool isLoadingMore(int tabIndex) =>
      _isLoadingMoreByTab[tabIndex] ?? false;
  String? getError(int tabIndex) => _errorByTab[tabIndex];
  bool hasMore(int tabIndex) {
    final currentPage = _currentPageByTab[tabIndex] ?? 1;
    final totalPage = _totalPageByTab[tabIndex] ?? 0;
    return currentPage <= totalPage;
  }

  /// Load twizzs for a specific tab
  Future<void> loadTwizzs({
    required String userId,
    required int tabIndex,
    bool refresh = false,
  }) async {
    if (_isLoadingByTab[tabIndex] == true) return;

    if (refresh) {
      _currentPageByTab[tabIndex] = 1;
      _totalPageByTab[tabIndex] = 0;
      _twizzsByTab[tabIndex] = [];
    }

    _isLoadingByTab[tabIndex] = true;
    _errorByTab[tabIndex] = null;
    notifyListeners();

    try {
      NewFeedsResponse response;

      switch (tabIndex) {
        case tabTwizz:
          response = await _twizzService.getUserTwizzs(
            userId: userId,
            type: TwizzType.twizz.index,
            limit: _limit,
            page: _currentPageByTab[tabIndex] ?? 1,
          );
          break;
        case tabRetwizz:
          response = await _twizzService.getUserTwizzs(
            userId: userId,
            type: TwizzType.retwizz.index,
            limit: _limit,
            page: _currentPageByTab[tabIndex] ?? 1,
          );
          break;
        case tabQuoteTwizz:
          response = await _twizzService.getUserTwizzs(
            userId: userId,
            type: TwizzType.quoteTwizz.index,
            limit: _limit,
            page: _currentPageByTab[tabIndex] ?? 1,
          );
          break;
        case tabLiked:
          response = await _likeService.getUserLikedTwizzs(
            userId: userId,
            limit: _limit,
            page: _currentPageByTab[tabIndex] ?? 1,
          );
          break;
        case tabBookmarked:
          response = await _bookmarkService
              .getUserBookmarkedTwizzs(
                userId: userId,
                limit: _limit,
                page: _currentPageByTab[tabIndex] ?? 1,
              );
          break;
        default:
          _isLoadingByTab[tabIndex] = false;
          notifyListeners();
          return;
      }

      final currentList = _twizzsByTab[tabIndex] ?? [];
      currentList.addAll(response.twizzs);
      _twizzsByTab[tabIndex] = currentList;
      _totalPageByTab[tabIndex] = response.totalPage;
      final currentPage = _currentPageByTab[tabIndex] ?? 1;
      _currentPageByTab[tabIndex] = currentPage + 1;
    } catch (e) {
      if (e is ApiErrorResponse) {
        _errorByTab[tabIndex] = e.message;
      } else {
        _errorByTab[tabIndex] =
            'Lỗi tải bài viết: ${e.toString()}';
      }
    } finally {
      _isLoadingByTab[tabIndex] = false;
      notifyListeners();
    }
  }

  /// Load more twizzs for a specific tab
  Future<void> loadMore({
    required String userId,
    required int tabIndex,
  }) async {
    if (_isLoadingMoreByTab[tabIndex] == true ||
        !hasMore(tabIndex))
      return;

    _isLoadingMoreByTab[tabIndex] = true;
    notifyListeners();

    try {
      NewFeedsResponse response;

      switch (tabIndex) {
        case tabTwizz:
          response = await _twizzService.getUserTwizzs(
            userId: userId,
            type: TwizzType.twizz.index,
            limit: _limit,
            page: _currentPageByTab[tabIndex] ?? 1,
          );
          break;
        case tabRetwizz:
          response = await _twizzService.getUserTwizzs(
            userId: userId,
            type: TwizzType.retwizz.index,
            limit: _limit,
            page: _currentPageByTab[tabIndex] ?? 1,
          );
          break;
        case tabQuoteTwizz:
          response = await _twizzService.getUserTwizzs(
            userId: userId,
            type: TwizzType.quoteTwizz.index,
            limit: _limit,
            page: _currentPageByTab[tabIndex] ?? 1,
          );
          break;
        case tabLiked:
          response = await _likeService.getUserLikedTwizzs(
            userId: userId,
            limit: _limit,
            page: _currentPageByTab[tabIndex] ?? 1,
          );
          break;
        case tabBookmarked:
          response = await _bookmarkService
              .getUserBookmarkedTwizzs(
                userId: userId,
                limit: _limit,
                page: _currentPageByTab[tabIndex] ?? 1,
              );
          break;
        default:
          _isLoadingMoreByTab[tabIndex] = false;
          notifyListeners();
          return;
      }

      final currentList = _twizzsByTab[tabIndex] ?? [];
      currentList.addAll(response.twizzs);
      _twizzsByTab[tabIndex] = currentList;
      _totalPageByTab[tabIndex] = response.totalPage;
      final currentPage = _currentPageByTab[tabIndex] ?? 1;
      _currentPageByTab[tabIndex] = currentPage + 1;
    } catch (e) {
      if (e is ApiErrorResponse) {
        _errorByTab[tabIndex] = e.message;
      } else {
        _errorByTab[tabIndex] =
            'Lỗi tải bài viết: ${e.toString()}';
      }
    } finally {
      _isLoadingMoreByTab[tabIndex] = false;
      notifyListeners();
    }
  }

  /// Refresh twizzs for a specific tab
  Future<void> refresh({
    required String userId,
    required int tabIndex,
  }) async {
    await loadTwizzs(
      userId: userId,
      tabIndex: tabIndex,
      refresh: true,
    );
  }

  /// Toggle like for a twizz
  Future<void> toggleLike(Twizz twizz, int tabIndex) async {
    final twizzs = _twizzsByTab[tabIndex] ?? [];
    final index = twizzs.indexWhere((t) => t.id == twizz.id);
    if (index == -1) return;

    final currentTwizz = twizzs[index];
    final isCurrentlyLiked = currentTwizz.isLiked;
    final newLikeCount =
        (currentTwizz.likes ?? 0) + (isCurrentlyLiked ? -1 : 1);

    // Optimistic update
    twizzs[index] = currentTwizz.copyWith(
      isLiked: !isCurrentlyLiked,
      likes: newLikeCount,
    );
    _twizzsByTab[tabIndex] = twizzs;
    notifyListeners();

    try {
      if (isCurrentlyLiked) {
        await _likeService.unlikeTwizz(twizz.id);
      } else {
        await _likeService.likeTwizz(twizz.id);
      }
    } catch (e) {
      // Revert optimistic update on error
      twizzs[index] = currentTwizz;
      _twizzsByTab[tabIndex] = twizzs;
      notifyListeners();
      debugPrint('Error toggling like: $e');
    }
  }

  /// Toggle bookmark for a twizz
  Future<void> toggleBookmark(Twizz twizz, int tabIndex) async {
    final twizzs = _twizzsByTab[tabIndex] ?? [];
    final index = twizzs.indexWhere((t) => t.id == twizz.id);
    if (index == -1) return;

    final currentTwizz = twizzs[index];
    final isCurrentlyBookmarked = currentTwizz.isBookmarked;
    final newBookmarkCount =
        (currentTwizz.bookmarks ?? 0) +
        (isCurrentlyBookmarked ? -1 : 1);

    // Optimistic update
    twizzs[index] = currentTwizz.copyWith(
      isBookmarked: !isCurrentlyBookmarked,
      bookmarks: newBookmarkCount,
    );
    _twizzsByTab[tabIndex] = twizzs;
    notifyListeners();

    try {
      if (isCurrentlyBookmarked) {
        await _bookmarkService.unbookmarkTwizz(twizz.id);
      } else {
        await _bookmarkService.bookmarkTwizz(twizz.id);
      }
    } catch (e) {
      // Revert optimistic update on error
      twizzs[index] = currentTwizz;
      _twizzsByTab[tabIndex] = twizzs;
      notifyListeners();
      debugPrint('Error toggling bookmark: $e');
    }
  }

  /// Clear all data
  void clear() {
    _twizzsByTab.clear();
    _isLoadingByTab.clear();
    _isLoadingMoreByTab.clear();
    _errorByTab.clear();
    _currentPageByTab.clear();
    _totalPageByTab.clear();
    notifyListeners();
  }
}
