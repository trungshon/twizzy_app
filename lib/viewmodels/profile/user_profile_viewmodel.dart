import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../services/auth_service/auth_service.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';
import '../../services/twizz_service/twizz_sync_service.dart';

/// User Profile ViewModel
///
/// ViewModel quản lý state của user profile screen (viewing other users)
class UserProfileViewModel extends ChangeNotifier {
  final AuthService _authService;
  final TwizzService _twizzService;
  final LikeService _likeService;
  final BookmarkService _bookmarkService;
  final TwizzSyncService _syncService;
  StreamSubscription<TwizzSyncEvent>? _syncSubscription;

  UserProfileViewModel(
    this._authService,
    this._twizzService,
    this._likeService,
    this._bookmarkService,
    this._syncService,
  ) {
    // Listen for sync events
    _syncSubscription = _syncService.eventStream.listen(
      _handleSyncEvent,
    );
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  void _handleSyncEvent(TwizzSyncEvent event) {
    if (event.type == TwizzSyncEventType.update &&
        event.twizz != null) {
      final updatedTwizz = event.twizz!;
      _updateTwizzInAllTabs(
        updatedTwizz.id,
        updatedTwizz,
        broadcast: false,
      );
    } else if (event.type == TwizzSyncEventType.delete &&
        event.twizzId != null) {
      for (final entry in _twizzsByTab.entries) {
        final tabIndex = entry.key;
        final list = entry.value;
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

  // User state
  User? _user;
  bool _isLoadingProfile = false;
  String? _profileError;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  // State for each tab
  final Map<int, List<Twizz>> _twizzsByTab = {};
  final Map<int, bool> _isLoadingByTab = {};
  final Map<int, bool> _isLoadingMoreByTab = {};
  final Map<int, String?> _errorByTab = {};
  final Map<int, int> _currentPageByTab = {};
  final Map<int, int> _totalPageByTab = {};
  final Map<int, bool> _hasLoadedByTab = {};
  static const int _limit = 10;

  // Tab indices (only 3 tabs for user profile)
  static const int tabTwizz = 0;
  static const int tabRetwizz = 1;
  static const int tabQuoteTwizz = 2;

  // Getters
  User? get user => _user;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;
  bool get isFollowing => _isFollowing;
  bool get isLoadingFollow => _isLoadingFollow;

  List<Twizz> getTwizzs(int tabIndex) =>
      _twizzsByTab[tabIndex] ?? [];
  bool isLoading(int tabIndex) =>
      _isLoadingByTab[tabIndex] ?? false;
  bool isLoadingMore(int tabIndex) =>
      _isLoadingMoreByTab[tabIndex] ?? false;
  String? getError(int tabIndex) => _errorByTab[tabIndex];
  bool hasLoaded(int tabIndex) =>
      _hasLoadedByTab[tabIndex] ?? false;
  bool hasMore(int tabIndex) {
    final currentPage = _currentPageByTab[tabIndex] ?? 1;
    final totalPage = _totalPageByTab[tabIndex] ?? 1;
    return currentPage < totalPage;
  }

  /// Load user profile by username
  Future<void> loadProfile(String username) async {
    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();

    try {
      _user = await _authService.getUserProfile(username);
      _isFollowing = _user?.isFollowing ?? false;
      _isLoadingProfile = false;
      notifyListeners();
    } catch (e) {
      _isLoadingProfile = false;
      if (e is ApiErrorResponse) {
        _profileError = e.message;
      } else {
        _profileError = 'Lỗi tải thông tin người dùng';
      }
      notifyListeners();
    }
  }

  /// Follow the user
  Future<void> follow() async {
    if (_user == null || _isLoadingFollow) return;

    _isLoadingFollow = true;
    notifyListeners();

    try {
      await _authService.followUser(_user!.id);
      _isFollowing = true;
      // Increment followers count locally
      if (_user != null) {
        _user = User(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          dateOfBirth: _user!.dateOfBirth,
          createdAt: _user!.createdAt,
          updatedAt: _user!.updatedAt,
          verify: _user!.verify,
          bio: _user!.bio,
          location: _user!.location,
          website: _user!.website,
          username: _user!.username,
          avatar: _user!.avatar,
          coverPhoto: _user!.coverPhoto,
          followersCount: (_user!.followersCount ?? 0) + 1,
          followingCount: _user!.followingCount,
          isFollowing: true,
        );
      }
      _isLoadingFollow = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFollow = false;
      debugPrint('Follow error: $e');
      notifyListeners();
    }
  }

  /// Unfollow the user
  Future<void> unfollow() async {
    if (_user == null || _isLoadingFollow) return;

    _isLoadingFollow = true;
    notifyListeners();

    try {
      await _authService.unfollowUser(_user!.id);
      _isFollowing = false;
      // Decrement followers count locally
      if (_user != null) {
        _user = User(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          dateOfBirth: _user!.dateOfBirth,
          createdAt: _user!.createdAt,
          updatedAt: _user!.updatedAt,
          verify: _user!.verify,
          bio: _user!.bio,
          location: _user!.location,
          website: _user!.website,
          username: _user!.username,
          avatar: _user!.avatar,
          coverPhoto: _user!.coverPhoto,
          followersCount: ((_user!.followersCount ?? 1) - 1)
              .clamp(0, 999999999),
          followingCount: _user!.followingCount,
          isFollowing: false,
        );
      }
      _isLoadingFollow = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFollow = false;
      debugPrint('Unfollow error: $e');
      notifyListeners();
    }
  }

  /// Toggle follow/unfollow
  Future<void> toggleFollow() async {
    if (_isFollowing) {
      await unfollow();
    } else {
      await follow();
    }
  }

  /// Load twizzs for a tab
  Future<void> loadTwizzs({
    required int tabIndex,
    bool refresh = false,
  }) async {
    if (_user == null) return;

    if (refresh) {
      _currentPageByTab[tabIndex] = 1;
      _twizzsByTab[tabIndex] = [];
    }

    final currentPage = _currentPageByTab[tabIndex] ?? 1;

    if (currentPage == 1) {
      _isLoadingByTab[tabIndex] = true;
    } else {
      _isLoadingMoreByTab[tabIndex] = true;
    }
    _errorByTab[tabIndex] = null;
    notifyListeners();

    try {
      int? type;
      switch (tabIndex) {
        case tabTwizz:
          type = TwizzType.twizz.index;
          break;
        case tabRetwizz:
          type = TwizzType.retwizz.index;
          break;
        case tabQuoteTwizz:
          type = TwizzType.quoteTwizz.index;
          break;
      }

      final response = await _twizzService.getUserTwizzs(
        userId: _user!.id,
        page: currentPage,
        limit: _limit,
        type: type,
      );

      final currentTwizzs = _twizzsByTab[tabIndex] ?? [];
      if (refresh || currentPage == 1) {
        _twizzsByTab[tabIndex] = response.twizzs;
      } else {
        currentTwizzs.addAll(response.twizzs);
        _twizzsByTab[tabIndex] = currentTwizzs;
      }

      _totalPageByTab[tabIndex] = response.totalPage;
      _currentPageByTab[tabIndex] = currentPage;
      _isLoadingByTab[tabIndex] = false;
      _isLoadingMoreByTab[tabIndex] = false;
      _hasLoadedByTab[tabIndex] = true;
      notifyListeners();
    } catch (e) {
      _isLoadingByTab[tabIndex] = false;
      _isLoadingMoreByTab[tabIndex] = false;
      _hasLoadedByTab[tabIndex] = true;
      if (e is ApiErrorResponse) {
        _errorByTab[tabIndex] = e.message;
      } else {
        _errorByTab[tabIndex] = 'Lỗi tải bài viết';
      }
      notifyListeners();
    }
  }

  /// Load more twizzs
  Future<void> loadMore({required int tabIndex}) async {
    if (isLoadingMore(tabIndex) || !hasMore(tabIndex)) return;

    final currentPage = _currentPageByTab[tabIndex] ?? 1;
    _currentPageByTab[tabIndex] = currentPage + 1;
    await loadTwizzs(tabIndex: tabIndex);
  }

  /// Refresh twizzs
  Future<void> refresh({required int tabIndex}) async {
    await loadTwizzs(tabIndex: tabIndex, refresh: true);
  }

  /// Toggle like
  Future<void> toggleLike(Twizz twizz, int tabIndex) async {
    // Get the original twizz for engagement actions
    final targetTwizz = twizz.parentTwizz ?? twizz;
    final targetId = targetTwizz.id;
    final isCurrentlyLiked = targetTwizz.isLiked;
    final currentLikes = targetTwizz.likes ?? 0;

    // Optimistic update
    _updateTwizzState(
      targetId,
      isLiked: !isCurrentlyLiked,
      likes:
          isCurrentlyLiked ? currentLikes - 1 : currentLikes + 1,
    );

    try {
      if (isCurrentlyLiked) {
        await _likeService.unlikeTwizz(targetId);
      } else {
        await _likeService.likeTwizz(targetId);
      }
    } catch (e) {
      // Revert on error
      _updateTwizzState(
        targetId,
        isLiked: isCurrentlyLiked,
        likes: currentLikes,
      );
      debugPrint('Toggle like error: $e');
    }
  }

  /// Toggle bookmark
  Future<void> toggleBookmark(Twizz twizz, int tabIndex) async {
    final targetTwizz = twizz.parentTwizz ?? twizz;
    final targetId = targetTwizz.id;
    final isCurrentlyBookmarked = targetTwizz.isBookmarked;
    final currentBookmarks = targetTwizz.bookmarks ?? 0;

    _updateTwizzState(
      targetId,
      isBookmarked: !isCurrentlyBookmarked,
      bookmarks:
          isCurrentlyBookmarked
              ? currentBookmarks - 1
              : currentBookmarks + 1,
    );

    try {
      if (isCurrentlyBookmarked) {
        await _bookmarkService.unbookmarkTwizz(targetId);
      } else {
        await _bookmarkService.bookmarkTwizz(targetId);
      }
    } catch (e) {
      _updateTwizzState(
        targetId,
        isBookmarked: isCurrentlyBookmarked,
        bookmarks: currentBookmarks,
      );
      debugPrint('Toggle bookmark error: $e');
    }
  }

  /// Retwizz
  Future<void> retwizz(Twizz twizz, int tabIndex) async {
    final targetTwizz = twizz.parentTwizz ?? twizz;
    final targetId = targetTwizz.id;

    try {
      final response = await _twizzService.createTwizz(
        CreateTwizzRequest(
          content: '',
          parentId: targetId,
          type: TwizzType.retwizz,
          audience: TwizzAudience.everyone,
        ),
      );

      final currentRetwizzCount = targetTwizz.retwizzCount ?? 0;
      _updateTwizzState(
        targetId,
        isRetwizzed: true,
        userRetwizzId: response.result.id,
        retwizzCount: currentRetwizzCount + 1,
      );

      _syncService.emitUpdate(
        targetTwizz.copyWith(
          isRetwizzed: true,
          userRetwizzId: response.result.id,
          retwizzCount: currentRetwizzCount + 1,
        ),
      );
    } catch (e) {
      debugPrint('Retwizz error: $e');
    }
  }

  /// Unretwizz
  Future<void> unretwizz(Twizz twizz, int tabIndex) async {
    final targetTwizz = twizz.parentTwizz ?? twizz;
    final targetId = targetTwizz.id;
    final userRetwizzId = targetTwizz.userRetwizzId;

    if (userRetwizzId == null) return;

    try {
      await _twizzService.deleteTwizz(userRetwizzId);

      final currentRetwizzCount = targetTwizz.retwizzCount ?? 1;
      _updateTwizzState(
        targetId,
        isRetwizzed: false,
        userRetwizzId: null,
        retwizzCount: (currentRetwizzCount - 1).clamp(
          0,
          999999999,
        ),
      );

      _syncService.emitUpdate(
        targetTwizz.copyWith(
          isRetwizzed: false,
          retwizzCount: (currentRetwizzCount - 1).clamp(
            0,
            999999999,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Unretwizz error: $e');
    }
  }

  /// Delete twizz
  Future<bool> deleteTwizz(Twizz twizz) async {
    try {
      await _twizzService.deleteTwizz(twizz.id);

      // Remove from all tabs
      for (final entry in _twizzsByTab.entries) {
        entry.value.removeWhere((t) => t.id == twizz.id);
      }
      notifyListeners();

      _syncService.emitDelete(twizz.id);
      return true;
    } catch (e) {
      debugPrint('Delete twizz error: $e');
      return false;
    }
  }

  /// Update twizz state
  void _updateTwizzState(
    String twizzId, {
    bool? isLiked,
    int? likes,
    bool? isBookmarked,
    int? bookmarks,
    bool? isRetwizzed,
    String? userRetwizzId,
    int? retwizzCount,
    bool broadcast = true,
  }) {
    Twizz? updatedTwizz;

    for (final entry in _twizzsByTab.entries) {
      final list = entry.value;
      for (int i = 0; i < list.length; i++) {
        final twizz = list[i];
        if (twizz.id == twizzId ||
            twizz.parentTwizz?.id == twizzId) {
          final target =
              twizz.parentTwizz?.id == twizzId
                  ? twizz.parentTwizz!
                  : twizz;

          final updated = target.copyWith(
            isLiked: isLiked ?? target.isLiked,
            likes: likes ?? target.likes,
            isBookmarked: isBookmarked ?? target.isBookmarked,
            bookmarks: bookmarks ?? target.bookmarks,
            isRetwizzed: isRetwizzed ?? target.isRetwizzed,
            userRetwizzId: userRetwizzId,
            retwizzCount: retwizzCount ?? target.retwizzCount,
          );

          if (twizz.parentTwizz?.id == twizzId) {
            list[i] = twizz.copyWith(parentTwizz: updated);
          } else {
            list[i] = updated;
          }
          updatedTwizz = updated;
        }
      }
    }

    notifyListeners();

    if (broadcast && updatedTwizz != null) {
      _syncService.emitUpdate(updatedTwizz);
    }
  }

  void _updateTwizzInAllTabs(
    String twizzId,
    Twizz updatedTwizz, {
    bool broadcast = true,
  }) {
    _updateTwizzState(
      twizzId,
      isLiked: updatedTwizz.isLiked,
      likes: updatedTwizz.likes,
      isBookmarked: updatedTwizz.isBookmarked,
      bookmarks: updatedTwizz.bookmarks,
      isRetwizzed: updatedTwizz.isRetwizzed,
      userRetwizzId: updatedTwizz.userRetwizzId,
      retwizzCount: updatedTwizz.retwizzCount,
      broadcast: broadcast,
    );
  }

  /// Clear all data
  void clear() {
    _user = null;
    _isLoadingProfile = false;
    _profileError = null;
    _isFollowing = false;
    _isLoadingFollow = false;
    _twizzsByTab.clear();
    _isLoadingByTab.clear();
    _isLoadingMoreByTab.clear();
    _errorByTab.clear();
    _currentPageByTab.clear();
    _totalPageByTab.clear();
    _hasLoadedByTab.clear();
    notifyListeners();
  }
}
