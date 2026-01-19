import 'package:flutter/foundation.dart';
import '../../models/twizz/twizz_models.dart';
import '../../models/auth/auth_models.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/auth_service/auth_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';

class TwizzInteractionViewModel extends ChangeNotifier {
  final TwizzService _twizzService;
  final AuthService _authService;
  final LikeService _likeService;
  final BookmarkService _bookmarkService;

  TwizzInteractionViewModel(
    this._twizzService,
    this._authService,
    this._likeService,
    this._bookmarkService,
  );

  // Data lists
  List<Twizz> _quotes = [];
  List<User> _likedByUsers = [];
  List<User> _bookmarkedByUsers = [];

  List<Twizz> get quotes => _quotes;
  List<User> get likedByUsers => _likedByUsers;
  List<User> get bookmarkedByUsers => _bookmarkedByUsers;

  // Loading states
  bool _isLoadingQuotes = false;
  bool _isLoadingMoreQuotes = false;
  bool _isLoadingLikes = false;
  bool _isLoadingMoreLikes = false;
  bool _isLoadingBookmarks = false;
  bool _isLoadingMoreBookmarks = false;

  bool get isLoadingQuotes => _isLoadingQuotes;
  bool get isLoadingMoreQuotes => _isLoadingMoreQuotes;
  bool get isLoadingLikes => _isLoadingLikes;
  bool get isLoadingMoreLikes => _isLoadingMoreLikes;
  bool get isLoadingBookmarks => _isLoadingBookmarks;
  bool get isLoadingMoreBookmarks => _isLoadingMoreBookmarks;

  // Pagination
  int _quotesPage = 1;
  bool _hasMoreQuotes = true;
  int _likesPage = 1;
  bool _hasMoreLikes = true;
  int _bookmarksPage = 1;
  bool _hasMoreBookmarks = true;

  bool get hasMoreQuotes => _hasMoreQuotes;
  bool get hasMoreLikes => _hasMoreLikes;
  bool get hasMoreBookmarks => _hasMoreBookmarks;

  // Errors
  String? _quotesError;
  String? _likesError;
  String? _bookmarksError;

  String? get quotesError => _quotesError;
  String? get likesError => _likesError;
  String? get bookmarksError => _bookmarksError;

  Future<void> loadQuotes(
    String twizzId, {
    bool refresh = false,
  }) async {
    if (refresh) {
      _quotesPage = 1;
      _hasMoreQuotes = true;
      _quotes.clear();
      _isLoadingQuotes = true;
      _quotesError = null;
    } else {
      if (!_hasMoreQuotes || _isLoadingMoreQuotes) return;
      _isLoadingMoreQuotes = true;
    }
    notifyListeners();

    try {
      final response = await _twizzService.getTwizzChildren(
        twizzId: twizzId,
        type: TwizzType.quoteTwizz,
        page: _quotesPage,
        limit: 10,
      );

      if (refresh) {
        _quotes = response.twizzs;
      } else {
        _quotes.addAll(response.twizzs);
      }

      if (response.twizzs.length < 10) {
        _hasMoreQuotes = false;
      } else {
        _quotesPage++;
      }
    } catch (e) {
      if (e is ApiErrorResponse) {
        _quotesError = e.message;
      } else {
        _quotesError = e.toString();
      }
    } finally {
      _isLoadingQuotes = false;
      _isLoadingMoreQuotes = false;
      notifyListeners();
    }
  }

  Future<void> loadLikedByUsers(
    String twizzId, {
    bool refresh = false,
  }) async {
    if (refresh) {
      _likesPage = 1;
      _hasMoreLikes = true;
      _likedByUsers.clear();
      _isLoadingLikes = true;
      _likesError = null;
    } else {
      if (!_hasMoreLikes || _isLoadingMoreLikes) return;
      _isLoadingMoreLikes = true;
    }
    notifyListeners();

    try {
      final response = await _likeService.getUsersWhoLikedTwizz(
        twizzId: twizzId,
        page: _likesPage,
        limit: 10,
      );

      if (refresh) {
        _likedByUsers = response.result.users;
      } else {
        _likedByUsers.addAll(response.result.users);
      }

      if (response.result.users.length < 10) {
        _hasMoreLikes = false;
      } else {
        _likesPage++;
      }
    } catch (e) {
      if (e is ApiErrorResponse) {
        _likesError = e.message;
      } else {
        _likesError = e.toString();
      }
    } finally {
      _isLoadingLikes = false;
      _isLoadingMoreLikes = false;
      notifyListeners();
    }
  }

  Future<void> loadBookmarkedByUsers(
    String twizzId, {
    bool refresh = false,
  }) async {
    if (refresh) {
      _bookmarksPage = 1;
      _hasMoreBookmarks = true;
      _bookmarkedByUsers.clear();
      _isLoadingBookmarks = true;
      _bookmarksError = null;
    } else {
      if (!_hasMoreBookmarks || _isLoadingMoreBookmarks) return;
      _isLoadingMoreBookmarks = true;
    }
    notifyListeners();

    try {
      final response = await _bookmarkService
          .getUsersWhoBookmarkedTwizz(
            twizzId: twizzId,
            page: _bookmarksPage,
            limit: 10,
          );

      if (refresh) {
        _bookmarkedByUsers = response.result.users;
      } else {
        _bookmarkedByUsers.addAll(response.result.users);
      }

      if (response.result.users.length < 10) {
        _hasMoreBookmarks = false;
      } else {
        _bookmarksPage++;
      }
    } catch (e) {
      if (e is ApiErrorResponse) {
        _bookmarksError = e.message;
      } else {
        _bookmarksError = e.toString();
      }
    } finally {
      _isLoadingBookmarks = false;
      _isLoadingMoreBookmarks = false;
      notifyListeners();
    }
  }

  // Follow/Unfollow logic
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

  void _updateUserStatus(String userId, bool isFollowing) {
    // Update quotes list (if the author of any quote is this user)
    for (int i = 0; i < _quotes.length; i++) {
      if (_quotes[i].user?.id == userId) {
        _quotes[i] = _quotes[i].copyWith(
          user: _quotes[i].user?.copyWith(
            isFollowing: isFollowing,
          ),
        );
      }
    }

    // Update liked by users list
    for (int i = 0; i < _likedByUsers.length; i++) {
      if (_likedByUsers[i].id == userId) {
        _likedByUsers[i] = _likedByUsers[i].copyWith(
          isFollowing: isFollowing,
        );
      }
    }

    // Update bookmarked by users list
    for (int i = 0; i < _bookmarkedByUsers.length; i++) {
      if (_bookmarkedByUsers[i].id == userId) {
        _bookmarkedByUsers[i] = _bookmarkedByUsers[i].copyWith(
          isFollowing: isFollowing,
        );
      }
    }
  }
}
