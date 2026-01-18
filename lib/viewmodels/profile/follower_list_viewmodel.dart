import 'package:flutter/foundation.dart';
import '../../models/auth/auth_models.dart';
import '../../services/auth_service/auth_service.dart';

class FollowerListViewModel extends ChangeNotifier {
  final AuthService _authService;

  FollowerListViewModel(this._authService);

  // Users lists
  List<User> _followers = [];
  List<User> _following = [];

  List<User> get followers => _followers;
  List<User> get following => _following;

  // Loading states
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;
  bool _isLoadingMoreFollowers = false;
  bool _isLoadingMoreFollowing = false;

  bool get isLoadingFollowers => _isLoadingFollowers;
  bool get isLoadingFollowing => _isLoadingFollowing;
  bool get isLoadingMoreFollowers => _isLoadingMoreFollowers;
  bool get isLoadingMoreFollowing => _isLoadingMoreFollowing;

  // Pagination
  int _followersPage = 1;
  int _followingPage = 1;
  bool _hasMoreFollowers = true;
  bool _hasMoreFollowing = true;

  bool get hasMoreFollowers => _hasMoreFollowers;
  bool get hasMoreFollowing => _hasMoreFollowing;

  // Errors
  String? _followersError;
  String? _followingError;

  String? get followersError => _followersError;
  String? get followingError => _followingError;

  // Initial load check
  bool _followersLoaded = false;
  bool _followingLoaded = false;

  bool get followersLoaded => _followersLoaded;
  bool get followingLoaded => _followingLoaded;

  Future<void> loadFollowers(
    String userId, {
    bool refresh = false,
  }) async {
    if (refresh) {
      _followersPage = 1;
      _hasMoreFollowers = true;
      _followers.clear();
      _isLoadingFollowers = true;
      _followersError = null;
    } else {
      if (!_hasMoreFollowers || _isLoadingMoreFollowers) return;
      _isLoadingMoreFollowers = true;
    }
    notifyListeners();

    try {
      final users = await _authService.getFollowers(
        userId,
        page: _followersPage,
        limit: 10,
      );

      if (refresh) {
        _followers = users;
      } else {
        _followers.addAll(users);
      }

      if (users.length < 10) {
        _hasMoreFollowers = false;
      } else {
        _followersPage++;
      }
      _followersLoaded = true;
    } catch (e) {
      if (e is ApiErrorResponse) {
        _followersError = e.message;
      } else {
        _followersError = e.toString();
      }
    } finally {
      _isLoadingFollowers = false;
      _isLoadingMoreFollowers = false;
      notifyListeners();
    }
  }

  Future<void> loadFollowing(
    String userId, {
    bool refresh = false,
  }) async {
    if (refresh) {
      _followingPage = 1;
      _hasMoreFollowing = true;
      _following.clear();
      _isLoadingFollowing = true;
      _followingError = null;
    } else {
      if (!_hasMoreFollowing || _isLoadingMoreFollowing) return;
      _isLoadingMoreFollowing = true;
    }
    notifyListeners();

    try {
      final users = await _authService.getFollowing(
        userId,
        page: _followingPage,
        limit: 10,
      );

      if (refresh) {
        _following = users;
      } else {
        _following.addAll(users);
      }

      if (users.length < 10) {
        _hasMoreFollowing = false;
      } else {
        _followingPage++;
      }
      _followingLoaded = true;
    } catch (e) {
      if (e is ApiErrorResponse) {
        _followingError = e.message;
      } else {
        _followingError = e.toString();
      }
    } finally {
      _isLoadingFollowing = false;
      _isLoadingMoreFollowing = false;
      notifyListeners();
    }
  }

  Future<void> followUser(User user) async {
    _updateUserStatus(user.id, true);
    notifyListeners();
    try {
      await _authService.followUser(user.id);
    } catch (e) {
      _updateUserStatus(user.id, false);
      notifyListeners();
      // Rethrow or handle error? For now silent fail visually but revert
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
    // Update in followers list
    final followerIndex = _followers.indexWhere(
      (u) => u.id == userId,
    );
    if (followerIndex != -1) {
      _followers[followerIndex] = _reconstructUser(
        _followers[followerIndex],
        isFollowing,
      );
    }

    // Update in following list
    final followingIndex = _following.indexWhere(
      (u) => u.id == userId,
    );
    if (followingIndex != -1) {
      _following[followingIndex] = _reconstructUser(
        _following[followingIndex],
        isFollowing,
      );
    }
  }

  User _reconstructUser(User user, bool isFollowing) {
    return User(
      id: user.id,
      name: user.name,
      email: user.email,
      dateOfBirth: user.dateOfBirth,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      verify: user.verify,
      bio: user.bio,
      location: user.location,
      website: user.website,
      username: user.username,
      avatar: user.avatar,
      coverPhoto: user.coverPhoto,
      followersCount: user.followersCount,
      followingCount: user.followingCount,
      isFollowing: isFollowing,
    );
  }
}
