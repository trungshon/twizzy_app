import 'package:flutter/foundation.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../services/search_service/search_service.dart';
import '../../services/auth_service/auth_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/twizz_service/twizz_sync_service.dart';

enum SearchTab { posts, users, videos, photos }

class SearchViewModel extends ChangeNotifier {
  final SearchService _searchService;
  final AuthService _authService;
  final LikeService _likeService;
  final BookmarkService _bookmarkService;
  final TwizzService _twizzService;
  final TwizzSyncService _syncService;

  SearchViewModel(
    this._searchService,
    this._authService,
    this._likeService,
    this._bookmarkService,
    this._twizzService,
    this._syncService,
  ) {
    _syncService.eventStream.listen(_handleSyncEvent);
  }

  void _handleSyncEvent(TwizzSyncEvent event) {
    if (event.type == TwizzSyncEventType.update &&
        event.twizz != null) {
      _updateTwizzState(event.twizz!, broadcast: false);
    } else if (event.type == TwizzSyncEventType.delete &&
        event.twizzId != null) {
      _removeTwizzFromAll(event.twizzId!);
      notifyListeners();
    }
  }

  String _query = '';
  String get query => _query;

  SearchTab _currentTab = SearchTab.posts;
  SearchTab get currentTab => _currentTab;

  bool _isFollowOnly = false;
  bool get isFollowOnly => _isFollowOnly;

  // Results
  final Map<SearchTab, List<dynamic>> _results = {
    SearchTab.posts: <Twizz>[],
    SearchTab.users: <User>[],
    SearchTab.videos: <Twizz>[],
    SearchTab.photos: <Twizz>[],
  };

  List<Twizz> get posts =>
      _results[SearchTab.posts]!.cast<Twizz>();
  List<User> get users =>
      _results[SearchTab.users]!.cast<User>();
  List<Twizz> get videos =>
      _results[SearchTab.videos]!.cast<Twizz>();
  List<Twizz> get photos =>
      _results[SearchTab.photos]!.cast<Twizz>();

  // Pagination & Loading
  final Map<SearchTab, int> _currentPage = {
    SearchTab.posts: 1,
    SearchTab.users: 1,
    SearchTab.videos: 1,
    SearchTab.photos: 1,
  };

  final Map<SearchTab, bool> _hasMore = {
    SearchTab.posts: true,
    SearchTab.users: true,
    SearchTab.videos: true,
    SearchTab.photos: true,
  };

  final Map<SearchTab, bool> _isLoading = {
    SearchTab.posts: false,
    SearchTab.users: false,
    SearchTab.videos: false,
    SearchTab.photos: false,
  };

  final Map<SearchTab, bool> _isLoadingMore = {
    SearchTab.posts: false,
    SearchTab.users: false,
    SearchTab.videos: false,
    SearchTab.photos: false,
  };

  final Map<SearchTab, String?> _error = {
    SearchTab.posts: null,
    SearchTab.users: null,
    SearchTab.videos: null,
    SearchTab.photos: null,
  };

  bool isLoading(SearchTab tab) => _isLoading[tab] ?? false;
  bool isLoadingMore(SearchTab tab) =>
      _isLoadingMore[tab] ?? false;
  bool hasMore(SearchTab tab) => _hasMore[tab] ?? false;
  String? error(SearchTab tab) => _error[tab];

  void setTab(SearchTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners();
  }

  void toggleFollowOnly() {
    _isFollowOnly = !_isFollowOnly;
    if (_query.isNotEmpty) {
      search(_query);
    } else {
      notifyListeners();
    }
  }

  Future<void> search(
    String query, {
    bool isRefresh = true,
  }) async {
    _query = query;
    if (isRefresh) {
      _clearResultsForTab(_currentTab);
      _isLoading[_currentTab] = true;
      _error[_currentTab] = null;
    } else {
      if (!_hasMore[_currentTab]! ||
          _isLoadingMore[_currentTab]!)
        return;
      _isLoadingMore[_currentTab] = true;
    }
    notifyListeners();

    try {
      if (_currentTab == SearchTab.users) {
        final response = await _searchService.searchUsers(
          content: query,
          followOnly: _isFollowOnly,
          page: _currentPage[SearchTab.users]!,
          limit: 10,
        );
        final List<User> resultUsers =
            response.users
                .map(
                  (u) => User(
                    id: u.id,
                    name: u.name,
                    username: u.username,
                    avatar: u.avatar,
                    email: '', // Not needed for display
                    dateOfBirth: DateTime.now(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    verify:
                        u.isVerified ? 'Verified' : 'Unverified',
                    isFollowing: u.isFollowing,
                  ),
                )
                .toList();

        if (isRefresh) {
          _results[SearchTab.users] = resultUsers;
        } else {
          _results[SearchTab.users]!.addAll(resultUsers);
        }
        _hasMore[SearchTab.users] =
            _currentPage[SearchTab.users]! < response.totalPage;
      } else {
        MediaType? mediaType;
        if (_currentTab == SearchTab.videos) {
          mediaType = MediaType.video;
        } else if (_currentTab == SearchTab.photos) {
          mediaType = MediaType.image;
        }

        final response = await _searchService.searchTwizzs(
          content: query,
          mediaType: mediaType,
          followOnly: _isFollowOnly,
          page: _currentPage[_currentTab]!,
          limit: 10,
        );

        if (isRefresh) {
          _results[_currentTab] = response.twizzs;
        } else {
          _results[_currentTab]!.addAll(response.twizzs);
        }
        _hasMore[_currentTab] =
            _currentPage[_currentTab]! < response.totalPage;
      }

      if (_hasMore[_currentTab]!) {
        _currentPage[_currentTab] =
            _currentPage[_currentTab]! + 1;
      }
    } catch (e) {
      _error[_currentTab] = e.toString();
    } finally {
      if (isRefresh) {
        _isLoading[_currentTab] = false;
      } else {
        _isLoadingMore[_currentTab] = false;
      }
      notifyListeners();
    }
  }

  // Interaction methods
  Future<void> followUser(User user) async {
    _updateUserStatus(user.id, true);
    notifyListeners();
    try {
      await _authService.followUser(user.id);
    } catch (e) {
      _updateUserStatus(user.id, false);
      notifyListeners();
    }
  }

  Future<void> unfollowUser(User user) async {
    _updateUserStatus(user.id, false);
    notifyListeners();
    try {
      await _authService.unfollowUser(user.id);
    } catch (e) {
      _updateUserStatus(user.id, true);
      notifyListeners();
    }
  }

  Future<void> toggleLike(Twizz twizz) async {
    final originalStatus = twizz.isLiked;
    final originalLikes = twizz.likes ?? 0;

    _updateTwizzState(
      twizz.copyWith(
        isLiked: !originalStatus,
        likes:
            !originalStatus
                ? originalLikes + 1
                : originalLikes - 1,
      ),
    );

    try {
      if (originalStatus) {
        await _likeService.unlikeTwizz(twizz.id);
      } else {
        await _likeService.likeTwizz(twizz.id);
      }
    } catch (e) {
      _updateTwizzState(
        twizz.copyWith(
          isLiked: originalStatus,
          likes: originalLikes,
        ),
      );
    }
  }

  Future<void> toggleBookmark(Twizz twizz) async {
    final originalStatus = twizz.isBookmarked;
    final originalBookmarks = twizz.bookmarks ?? 0;

    _updateTwizzState(
      twizz.copyWith(
        isBookmarked: !originalStatus,
        bookmarks:
            !originalStatus
                ? originalBookmarks + 1
                : originalBookmarks - 1,
      ),
    );

    try {
      if (originalStatus) {
        await _bookmarkService.unbookmarkTwizz(twizz.id);
      } else {
        await _bookmarkService.bookmarkTwizz(twizz.id);
      }
    } catch (e) {
      _updateTwizzState(
        twizz.copyWith(
          isBookmarked: originalStatus,
          bookmarks: originalBookmarks,
        ),
      );
    }
  }

  Future<bool> deleteTwizz(Twizz twizz) async {
    try {
      await _twizzService.deleteTwizz(twizz.id);
      _removeTwizzFromAll(twizz.id);
      _syncService.emitDelete(twizz.id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _updateUserStatus(String userId, bool isFollowing) {
    final userList = _results[SearchTab.users]!.cast<User>();
    final index = userList.indexWhere((u) => u.id == userId);
    if (index != -1) {
      userList[index] = userList[index].copyWith(
        isFollowing: isFollowing,
      );
    }
  }

  void _updateTwizzState(
    Twizz updatedTwizz, {
    bool broadcast = true,
  }) {
    bool modified = false;
    for (var tab in [
      SearchTab.posts,
      SearchTab.videos,
      SearchTab.photos,
    ]) {
      final list = _results[tab]!.cast<Twizz>();
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == updatedTwizz.id) {
          list[i] = updatedTwizz;
          modified = true;
        } else if (list[i].parentTwizz?.id == updatedTwizz.id) {
          list[i] = list[i].copyWith(parentTwizz: updatedTwizz);
          modified = true;
        }
      }
    }
    if (modified) {
      if (broadcast) _syncService.emitUpdate(updatedTwizz);
      notifyListeners();
    }
  }

  void _removeTwizzFromAll(String twizzId) {
    for (var tab in [
      SearchTab.posts,
      SearchTab.videos,
      SearchTab.photos,
    ]) {
      _results[tab]!.removeWhere((t) => t.id == twizzId);
    }
  }

  void clearSearch() {
    _query = '';
    for (var tab in SearchTab.values) {
      _clearResultsForTab(tab);
    }
    notifyListeners();
  }

  void _clearResultsForTab(SearchTab tab) {
    _results[tab] = [];
    _currentPage[tab] = 1;
    _hasMore[tab] = true;
    _isLoading[tab] = false;
    _isLoadingMore[tab] = false;
    _error[tab] = null;
  }
}
