import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/twizz/twizz_models.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';
import '../../services/twizz_service/twizz_sync_service.dart';
import '../../services/search_service/search_service.dart';

class TwizzDetailViewModel extends ChangeNotifier {
  final TwizzService _twizzService;
  final LikeService _likeService;
  final BookmarkService _bookmarkService;
  final TwizzSyncService _syncService;
  final SearchService _searchService;

  TwizzDetailViewModel(
    this._twizzService,
    this._likeService,
    this._bookmarkService,
    this._syncService,
    this._searchService,
  ) {
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
        broadcast: false,
      );
    } else if (event.type == TwizzSyncEventType.delete &&
        event.twizzId != null) {
      if (_twizz?.id == event.twizzId ||
          _twizz?.parentTwizz?.id == event.twizzId) {
        // Main post deleted - maybe navigate back?
        // For now just clear it
        _twizz = null;
      }
      _comments.removeWhere(
        (t) =>
            t.id == event.twizzId ||
            t.parentTwizz?.id == event.twizzId,
      );
      notifyListeners();
    }
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

    // Update main twizz
    if (_twizz?.id == id) {
      _twizz = _twizz!.copyWith(
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
      if (broadcast) _syncService.emitUpdate(_twizz!);
    }

    // Update comments
    for (int i = 0; i < _comments.length; i++) {
      if (_comments[i].id == id) {
        _comments[i] = _comments[i].copyWith(
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
        if (broadcast) _syncService.emitUpdate(_comments[i]);
      }
    }

    if (modified) notifyListeners();
  }

  Twizz? _twizz;
  final List<Twizz> _comments = [];
  bool _isLoadingTwizz = false;
  bool _isLoadingComments = false;
  bool _isLoadingMoreComments = false;
  bool _isPostingComment = false;
  String? _error;
  int _commentsPage = 1;
  bool _hasMoreComments = true;

  // Reply-to state
  Twizz? _replyingTo;

  // Nested replies storage (key = comment ID, value = list of replies)
  final Map<String, List<Twizz>> _repliesMap = {};
  final Map<String, bool> _loadingRepliesMap = {};

  // Media state
  final List<File> _selectedImages = [];
  File? _selectedVideo;
  bool _isUploading = false;
  static const int maxImages = 4;

  Twizz? get twizz => _twizz;
  List<Twizz> get comments => _comments;
  bool get isLoadingTwizz => _isLoadingTwizz;
  bool get isLoadingComments => _isLoadingComments;
  bool get isLoadingMoreComments => _isLoadingMoreComments;
  bool get isPostingComment => _isPostingComment;
  String? get error => _error;
  bool get hasMoreComments => _hasMoreComments;

  Map<String, List<Twizz>> get repliesMap => _repliesMap;
  bool isLoadingReplies(String commentId) =>
      _loadingRepliesMap[commentId] ?? false;

  List<File> get selectedImages => _selectedImages;
  File? get selectedVideo => _selectedVideo;
  bool get isUploading => _isUploading;
  bool get canPost =>
      _isPostingComment || _isUploading || _isSearchingUsers
          ? false
          : true;

  // Mention search state
  bool _isSearchingUsers = false;
  List<SearchUserResult> _searchResults = [];
  final List<SearchUserResult> _mentionedUsers = [];

  bool get isSearchingUsers => _isSearchingUsers;
  List<SearchUserResult> get searchResults => _searchResults;
  List<SearchUserResult> get mentionedUsers => _mentionedUsers;

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

  /// Add mentioned user
  void addMention(SearchUserResult user) {
    if (_mentionedUsers.any((u) => u.id == user.id)) {
      return;
    }
    _mentionedUsers.add(user);
    _searchResults = [];
    notifyListeners();
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  /// Extract hashtags from content
  List<String> _extractHashtags(String content) {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }

  Twizz? get replyingTo => _replyingTo;

  void setReplyingTo(Twizz? comment) {
    _replyingTo = comment;
    notifyListeners();
  }

  void clearReplyingTo() {
    _replyingTo = null;
    notifyListeners();
  }

  Future<void> addImages(List<File> files) async {
    if (_selectedVideo != null) {
      _error = 'Không thể thêm ảnh khi đã chọn video';
      notifyListeners();
      return;
    }

    if (_selectedImages.length + files.length > maxImages) {
      _error = 'Bạn chỉ có thể chọn tối đa $maxImages ảnh';
      notifyListeners();
      return;
    }

    _selectedImages.addAll(files);
    _error = null;
    notifyListeners();
  }

  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> setVideo(File file) async {
    if (_selectedImages.isNotEmpty) {
      _error = 'Không thể thêm video khi đã chọn ảnh';
      notifyListeners();
      return;
    }

    _selectedVideo = file;
    _error = null;
    notifyListeners();
  }

  void removeVideo() {
    _selectedVideo = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadTwizzDetail(String twizzId) async {
    _isLoadingTwizz = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _twizzService.getTwizz(twizzId);
      _twizz = response.result;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingTwizz = false;
      notifyListeners();
    }
  }

  void setTwizz(Twizz twizz) {
    _twizz = twizz;
    notifyListeners();
  }

  Future<void> loadComments(
    String twizzId, {
    bool refresh = false,
  }) async {
    if (refresh) {
      _commentsPage = 1;
      _hasMoreComments = true;
      _comments.clear();
      _isLoadingComments = true;
    } else {
      if (!_hasMoreComments || _isLoadingMoreComments) return;
      _isLoadingMoreComments = true;
    }
    _error = null;
    notifyListeners();

    try {
      final response = await _twizzService.getTwizzChildren(
        twizzId: twizzId,
        type: TwizzType.comment,
        page: _commentsPage,
        limit: 10,
      );

      _comments.addAll(response.twizzs);
      if (response.twizzs.length < 10) {
        _hasMoreComments = false;
      } else {
        _commentsPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingComments = false;
      _isLoadingMoreComments = false;
      notifyListeners();
    }
  }

  /// Load replies for a specific comment
  Future<void> loadRepliesForComment(
    String commentId, {
    int limit = 3,
  }) async {
    if (_loadingRepliesMap[commentId] == true) return;

    _loadingRepliesMap[commentId] = true;
    notifyListeners();

    try {
      final response = await _twizzService.getTwizzChildren(
        twizzId: commentId,
        type: TwizzType.comment,
        page: 1,
        limit: limit,
      );

      _repliesMap[commentId] = response.twizzs;
    } catch (e) {
      // Silently fail for nested replies
      _repliesMap[commentId] = [];
    } finally {
      _loadingRepliesMap[commentId] = false;
      notifyListeners();
    }
  }

  /// Load replies for all loaded comments
  Future<void> loadRepliesForAllComments({int limit = 3}) async {
    for (final comment in _comments) {
      if (comment.commentCount != null &&
          comment.commentCount! > 0) {
        await loadRepliesForComment(comment.id, limit: limit);
      }
    }
  }

  Future<bool> postComment(
    String parentId,
    String content,
  ) async {
    _isPostingComment = true;
    _isUploading = true;
    _error = null;
    notifyListeners();

    try {
      List<Media> uploadedMedias = [];

      // Upload media if any
      if (_selectedImages.isNotEmpty) {
        uploadedMedias = await _twizzService.uploadImages(
          _selectedImages,
        );
      } else if (_selectedVideo != null) {
        uploadedMedias = await _twizzService.uploadVideo(
          _selectedVideo!,
        );
      }

      // Extract hashtags
      final hashtags = _extractHashtags(content);

      // Get mention user IDs
      final mentionIds =
          _mentionedUsers.map((u) => u.id).toList();

      final request = CreateTwizzRequest(
        content: content,
        type: TwizzType.comment,
        parentId: parentId,
        audience: TwizzAudience.everyone,
        medias: uploadedMedias,
        hashtags: hashtags,
        mentions: mentionIds,
      );

      final response = await _twizzService.createTwizz(request);

      // Check if replying to a comment (nested reply) or to main post
      if (_replyingTo != null) {
        // Add to nested replies map
        final replyToId = _replyingTo!.id;
        if (_repliesMap.containsKey(replyToId)) {
          _repliesMap[replyToId]!.insert(0, response.result);
        } else {
          _repliesMap[replyToId] = [response.result];
        }

        // Update the parent comment's comment count
        for (int i = 0; i < _comments.length; i++) {
          if (_comments[i].id == replyToId) {
            _comments[i] = _comments[i].copyWith(
              commentCount: (_comments[i].commentCount ?? 0) + 1,
            );
            break;
          }
        }
      } else {
        // Add to main comments list
        _comments.insert(0, response.result);

        // Update main twizz comment count
        if (_twizz != null) {
          _twizz = _twizz!.copyWith(
            commentCount: (_twizz!.commentCount ?? 0) + 1,
          );
        }
      }

      // Clear selections
      _selectedImages.clear();
      _selectedVideo = null;
      _mentionedUsers.clear();
      _searchResults.clear();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isPostingComment = false;
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Update reply state in _repliesMap
  void _updateReplyState(
    String replyId, {
    bool? isLiked,
    int? likes,
    bool? isBookmarked,
    int? bookmarks,
  }) {
    for (final commentId in _repliesMap.keys) {
      final replies = _repliesMap[commentId]!;
      for (int i = 0; i < replies.length; i++) {
        if (replies[i].id == replyId) {
          _repliesMap[commentId]![i] = replies[i].copyWith(
            isLiked: isLiked,
            likes: likes,
            isBookmarked: isBookmarked,
            bookmarks: bookmarks,
          );
          return;
        }
      }
    }
  }

  // Interaction logic
  Future<void> toggleLike([Twizz? target]) async {
    final tw = target ?? _twizz;
    if (tw == null) return;

    final originalState = tw.isLiked;
    final originalCount = tw.likes ?? 0;
    final newState = !originalState;
    final newCount =
        originalState ? originalCount - 1 : originalCount + 1;

    // Local update
    if (target == null) {
      _twizz = _twizz!.copyWith(
        isLiked: newState,
        likes: newCount,
      );
    } else {
      // Try to update in comments first
      final index = _comments.indexWhere(
        (c) => c.id == target.id,
      );
      if (index != -1) {
        _comments[index] = _comments[index].copyWith(
          isLiked: newState,
          likes: newCount,
        );
      } else {
        // Try to update in replies
        _updateReplyState(
          target.id,
          isLiked: newState,
          likes: newCount,
        );
      }
    }
    notifyListeners();

    try {
      if (originalState) {
        await _likeService.unlikeTwizz(tw.id);
      } else {
        await _likeService.likeTwizz(tw.id);
      }
    } catch (e) {
      // Rollback
      if (target == null) {
        _twizz = _twizz!.copyWith(
          isLiked: originalState,
          likes: originalCount,
        );
      } else {
        final index = _comments.indexWhere(
          (c) => c.id == target.id,
        );
        if (index != -1) {
          _comments[index] = _comments[index].copyWith(
            isLiked: originalState,
            likes: originalCount,
          );
        } else {
          // Rollback in replies
          _updateReplyState(
            target.id,
            isLiked: originalState,
            likes: originalCount,
          );
        }
      }
      notifyListeners();
    }
  }

  Future<void> toggleBookmark([Twizz? target]) async {
    final tw = target ?? _twizz;
    if (tw == null) return;

    final originalState = tw.isBookmarked;
    final originalCount = tw.bookmarks ?? 0;
    final newState = !originalState;
    final newCount =
        originalState ? originalCount - 1 : originalCount + 1;

    // Local update
    if (target == null) {
      _twizz = _twizz!.copyWith(
        isBookmarked: newState,
        bookmarks: newCount,
      );
    } else {
      // Try to update in comments first
      final index = _comments.indexWhere(
        (c) => c.id == target.id,
      );
      if (index != -1) {
        _comments[index] = _comments[index].copyWith(
          isBookmarked: newState,
          bookmarks: newCount,
        );
      } else {
        // Try to update in replies
        _updateReplyState(
          target.id,
          isBookmarked: newState,
          bookmarks: newCount,
        );
      }
    }
    notifyListeners();

    try {
      if (originalState) {
        await _bookmarkService.unbookmarkTwizz(tw.id);
      } else {
        await _bookmarkService.bookmarkTwizz(tw.id);
      }
    } catch (e) {
      // Rollback
      if (target == null) {
        _twizz = _twizz!.copyWith(
          isBookmarked: originalState,
          bookmarks: originalCount,
        );
      } else {
        final index = _comments.indexWhere(
          (c) => c.id == target.id,
        );
        if (index != -1) {
          _comments[index] = _comments[index].copyWith(
            isBookmarked: originalState,
            bookmarks: originalCount,
          );
        } else {
          // Rollback in replies
          _updateReplyState(
            target.id,
            isBookmarked: originalState,
            bookmarks: originalCount,
          );
        }
      }
      notifyListeners();
    }
  }

  /// Delete a twizz (main post, comment, or reply)
  /// Returns true if the main post was deleted (caller should navigate back)
  Future<bool> deleteTwizz(Twizz twizz) async {
    try {
      await _twizzService.deleteTwizz(twizz.id);

      // Emit delete event for sync
      _syncService.emitDelete(twizz.id);

      // Check if deleting the main post
      if (twizz.id == _twizz?.id) {
        // Main post deleted - return true so UI can navigate back
        _twizz = null;
        _comments.clear();
        _repliesMap.clear();
        notifyListeners();
        return true;
      }

      // Check if it's a direct comment
      final commentIndex = _comments.indexWhere(
        (c) => c.id == twizz.id,
      );
      if (commentIndex != -1) {
        _comments.removeAt(commentIndex);
        // Also remove its replies from the map
        _repliesMap.remove(twizz.id);

        // Update main twizz comment count
        if (_twizz != null) {
          _twizz = _twizz!.copyWith(
            commentCount: (_twizz!.commentCount ?? 1) - 1,
          );
        }
        notifyListeners();
        return false;
      }

      // Check if it's a nested reply
      for (final commentId in _repliesMap.keys) {
        final replies = _repliesMap[commentId]!;
        final replyIndex = replies.indexWhere(
          (r) => r.id == twizz.id,
        );
        if (replyIndex != -1) {
          replies.removeAt(replyIndex);

          // Update parent comment's comment count
          final parentIndex = _comments.indexWhere(
            (c) => c.id == commentId,
          );
          if (parentIndex != -1) {
            _comments[parentIndex] = _comments[parentIndex]
                .copyWith(
                  commentCount:
                      (_comments[parentIndex].commentCount ??
                          1) -
                      1,
                );
          }
          notifyListeners();
          return false;
        }
      }

      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
