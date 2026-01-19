import 'package:flutter/foundation.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';
import '../../services/twizz_service/twizz_sync_service.dart';

/// Profile ViewModel
///
/// ViewModel quản lý state của profile screen với các tabs khác nhau
class ProfileViewModel extends ChangeNotifier {
  final TwizzService _twizzService;
  final LikeService _likeService;
  final BookmarkService _bookmarkService;
  final TwizzSyncService _syncService;

  ProfileViewModel(
    this._twizzService,
    this._likeService,
    this._bookmarkService,
    this._syncService,
  ) {
    // Listen for sync events
    _syncService.eventStream.listen(_handleSyncEvent);
  }

  void _handleSyncEvent(TwizzSyncEvent event) {
    if (event.type == TwizzSyncEventType.update &&
        event.twizz != null) {
      final updatedTwizz = event.twizz!;
      _updateTwizzInAllTabs(
        updatedTwizz.id,
        updatedTwizz,
        broadcast: false, // Don't broadcast back
      );
    } else if (event.type == TwizzSyncEventType.create &&
        event.twizz != null) {
      final twizz = event.twizz!;

      // Handle regular Twizz
      if (twizz.type == TwizzType.twizz) {
        final twizzs = _twizzsByTab[tabTwizz] ?? [];
        if (!twizzs.any((t) => t.id == twizz.id)) {
          twizzs.insert(0, twizz);
          _twizzsByTab[tabTwizz] = twizzs;
          notifyListeners();
        }
      }
    } else if (event.type == TwizzSyncEventType.delete &&
        event.twizzId != null) {
      for (final entry in _twizzsByTab.entries) {
        final tabIndex = entry.key;
        final list = entry.value;
        // Remove the deleted post
        list.removeWhere(
          (t) =>
              t.id == event.twizzId ||
              t.parentTwizz?.id == event.twizzId,
        );
        _twizzsByTab[tabIndex] = list;
      }
      notifyListeners();
    }
  }

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
  static const int tabQuoteTwizz = 1;
  static const int tabLiked = 2;
  static const int tabBookmarked = 3;

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
    Future.microtask(() => notifyListeners());

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
        !hasMore(tabIndex)) {
      return;
    }

    _isLoadingMoreByTab[tabIndex] = true;
    Future.microtask(() => notifyListeners());

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
    final isCurrentlyLiked = twizz.isLiked;
    final newLikeCount =
        (twizz.likes ?? 0) + (isCurrentlyLiked ? -1 : 1);

    // Create updated twizz
    final updatedTwizz = twizz.copyWith(
      isLiked: !isCurrentlyLiked,
      likes: newLikeCount,
    );

    // Update twizz in all tabs (top-level or nested)
    _updateTwizzInAllTabs(twizz.id, updatedTwizz);

    // Handle Liked tab specifically
    final likedTwizzs = _twizzsByTab[tabLiked] ?? [];
    if (isCurrentlyLiked) {
      // Unlike: remove from liked tab
      likedTwizzs.removeWhere((t) => t.id == twizz.id);
      _twizzsByTab[tabLiked] = likedTwizzs;
    } else {
      // Like: add to liked tab
      if (!likedTwizzs.any((t) => t.id == twizz.id)) {
        likedTwizzs.insert(0, updatedTwizz);
        _twizzsByTab[tabLiked] = likedTwizzs;
      }
    }

    notifyListeners();

    try {
      if (isCurrentlyLiked) {
        await _likeService.unlikeTwizz(twizz.id);
      } else {
        await _likeService.likeTwizz(twizz.id);
      }
    } catch (e) {
      // Revert in all tabs
      _updateTwizzInAllTabs(twizz.id, twizz);

      // Revert liked tab
      final currentLikedTwizzs = _twizzsByTab[tabLiked] ?? [];
      if (isCurrentlyLiked) {
        if (!currentLikedTwizzs.any((t) => t.id == twizz.id)) {
          currentLikedTwizzs.insert(0, twizz);
          _twizzsByTab[tabLiked] = currentLikedTwizzs;
        }
      } else {
        currentLikedTwizzs.removeWhere((t) => t.id == twizz.id);
        _twizzsByTab[tabLiked] = currentLikedTwizzs;
      }

      notifyListeners();
      debugPrint('Error toggling like: $e');
    }
  }

  /// Toggle bookmark for a twizz
  Future<void> toggleBookmark(Twizz twizz, int tabIndex) async {
    final isBookmarked = twizz.isBookmarked;

    final newBookmarkCount =
        (twizz.bookmarks ?? 0) + (isBookmarked ? -1 : 1);

    // Create updated twizz
    final updatedTwizz = twizz.copyWith(
      isBookmarked: !isBookmarked,
      bookmarks: newBookmarkCount,
    );

    // Update globally
    _updateTwizzInAllTabs(twizz.id, updatedTwizz);

    // Handle bookmarked tab
    final bookmarkedTwizzs = _twizzsByTab[tabBookmarked] ?? [];
    if (isBookmarked) {
      bookmarkedTwizzs.removeWhere((t) => t.id == twizz.id);
      _twizzsByTab[tabBookmarked] = bookmarkedTwizzs;
    } else {
      if (!bookmarkedTwizzs.any((t) => t.id == twizz.id)) {
        bookmarkedTwizzs.insert(0, updatedTwizz);
        _twizzsByTab[tabBookmarked] = bookmarkedTwizzs;
      }
    }

    notifyListeners();

    try {
      if (isBookmarked) {
        await _bookmarkService.unbookmarkTwizz(twizz.id);
      } else {
        await _bookmarkService.bookmarkTwizz(twizz.id);
      }
    } catch (e) {
      // Revert globally
      _updateTwizzInAllTabs(twizz.id, twizz);

      // Revert bookmarked tab
      final currentBookmarkedTwizzs =
          _twizzsByTab[tabBookmarked] ?? [];
      if (isBookmarked) {
        if (!currentBookmarkedTwizzs.any(
          (t) => t.id == twizz.id,
        )) {
          currentBookmarkedTwizzs.insert(0, twizz);
          _twizzsByTab[tabBookmarked] = currentBookmarkedTwizzs;
        }
      } else {
        currentBookmarkedTwizzs.removeWhere(
          (t) => t.id == twizz.id,
        );
        _twizzsByTab[tabBookmarked] = currentBookmarkedTwizzs;
      }

      notifyListeners();
      debugPrint('Error toggling bookmark: $e');
    }
  }

  /// Delete a twizz
  Future<bool> deleteTwizz(Twizz twizz) async {
    try {
      await _twizzService.deleteTwizz(twizz.id);

      // Remove from all tabs
      for (final entry in _twizzsByTab.entries) {
        final tabIndex = entry.key;
        final list = entry.value;
        list.removeWhere((t) => t.id == twizz.id);
        _twizzsByTab[tabIndex] = list;
      }

      // Broadcast delete
      _syncService.emitDelete(twizz.id);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  void _updateTwizzInAllTabs(
    String twizzId,
    Twizz updatedTwizz, {
    bool broadcast = true,
  }) {
    bool modified = false;
    for (final entry in _twizzsByTab.entries) {
      final tabIndex = entry.key;
      final twizzs = entry.value;
      for (int i = 0; i < twizzs.length; i++) {
        // Update top-level
        if (twizzs[i].id == twizzId) {
          twizzs[i] = updatedTwizz;
          modified = true;

          if (broadcast) {
            _syncService.emitUpdate(twizzs[i]);
          }
        }
        // Update nested parentTwizz
        if (twizzs[i].parentTwizz?.id == twizzId) {
          twizzs[i] = twizzs[i].copyWith(
            parentTwizz: updatedTwizz,
          );
          modified = true;

          if (broadcast) {
            _syncService.emitUpdate(twizzs[i].parentTwizz!);
          }
        }
      }
      _twizzsByTab[tabIndex] = twizzs;
    }

    if (modified) {
      notifyListeners();
    }
  }

  /// Add a new twizz to the profile
  void addTwizz(Twizz twizz) {
    final twizzs = _twizzsByTab[tabTwizz] ?? [];
    if (!twizzs.any((t) => t.id == twizz.id)) {
      twizzs.insert(0, twizz);
      _twizzsByTab[tabTwizz] = twizzs;

      _totalPageByTab[tabTwizz] = 1;
      _currentPageByTab[tabTwizz] = 1;
      _isLoadingByTab[tabTwizz] = false;
      _isLoadingMoreByTab[tabTwizz] = false;
      _errorByTab[tabTwizz] = null;

      _syncService.emitCreate(twizz);
      notifyListeners();
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
