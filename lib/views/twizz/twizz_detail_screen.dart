import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/twizz/twizz_models.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';
import '../../viewmodels/twizz/twizz_detail_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/twizz/twizz_item.dart';
import '../../routes/route_names.dart';
import '../../widgets/twizz/twizz_create_media_preview.dart';
import '../../services/twizz_service/twizz_sync_service.dart';
import '../../services/search_service/search_service.dart';
import '../../widgets/twizz/twizz_text_input_utils.dart';
import '../../models/auth/auth_models.dart';

class TwizzDetailScreenArgs {
  final String twizzId;
  final bool focusComment;

  TwizzDetailScreenArgs({
    required this.twizzId,
    this.focusComment = false,
  });
}

class TwizzDetailScreen extends StatefulWidget {
  final TwizzDetailScreenArgs args;

  const TwizzDetailScreen({super.key, required this.args});

  @override
  State<TwizzDetailScreen> createState() =>
      _TwizzDetailScreenState();
}

class _TwizzDetailScreenState extends State<TwizzDetailScreen> {
  late TwizzDetailViewModel _viewModel;
  late final HighlightTextController _replyController;
  final FocusNode _replyFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  // Mention state
  bool _showMentionSuggestions = false;
  String _mentionQuery = '';
  int _mentionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    _viewModel = TwizzDetailViewModel(
      Provider.of<TwizzService>(context, listen: false),
      Provider.of<LikeService>(context, listen: false),
      Provider.of<BookmarkService>(context, listen: false),
      Provider.of<TwizzSyncService>(context, listen: false),
      Provider.of<SearchService>(context, listen: false),
    );
    _replyController = HighlightTextController();
    _replyController.addListener(_onTextChanged);

    // Load fresh detail from API
    _viewModel.loadTwizzDetail(widget.args.twizzId);
    _viewModel.loadComments(widget.args.twizzId, refresh: true);

    // Auto focus if requested
    if (widget.args.focusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _replyFocusNode.requestFocus();
      });
    }
  }

  /// Pick images from gallery
  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images.isNotEmpty) {
        final files =
            images.map((xFile) => File(xFile.path)).toList();
        await _viewModel.addImages(files);
      }
    } catch (e) {
      debugPrint('Pick images error: $e');
    }
  }

  /// Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        await _viewModel.addImages([File(image.path)]);
      }
    } catch (e) {
      debugPrint('Take photo error: $e');
    }
  }

  /// Pick video from gallery
  Future<void> _pickVideo() async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        await _viewModel.setVideo(File(video.path));
      }
    } catch (e) {
      debugPrint('Pick video error: $e');
    }
  }

  @override
  void dispose() {
    _replyController.removeListener(_onTextChanged);
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _replyController.text;
    final selection = _replyController.selection;

    if (!selection.isValid || selection.baseOffset <= 0) {
      _hideMentionSuggestions();
      return;
    }

    final cursorPosition = selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);

    // Find the last '@' before the cursor
    final lastAtSymbol = textBeforeCursor.lastIndexOf('@');

    if (lastAtSymbol != -1) {
      // Check if there's a space or another '@' between the last '@' and cursor
      final textBetween = textBeforeCursor.substring(
        lastAtSymbol + 1,
      );
      if (!textBetween.contains(' ') &&
          !textBetween.contains('@')) {
        setState(() {
          _showMentionSuggestions = true;
          _mentionQuery = textBetween;
          _mentionStartIndex = lastAtSymbol;
        });
        _viewModel.searchUsers(_mentionQuery);
        return;
      }
    }

    _hideMentionSuggestions();
  }

  void _hideMentionSuggestions() {
    if (_showMentionSuggestions) {
      setState(() {
        _showMentionSuggestions = false;
        _mentionQuery = '';
        _mentionStartIndex = -1;
      });
      _viewModel.clearSearchResults();
    }
  }

  void _insertMention(SearchUserResult user) {
    final text = _replyController.text;
    final selection = _replyController.selection;

    if (!selection.isValid || _mentionStartIndex == -1) return;

    final cursorPosition = selection.baseOffset;

    final newText =
        '${text.substring(0, _mentionStartIndex)}@${user.username} ${text.substring(cursorPosition)}';

    _replyController.text = newText;
    _replyController.selection = TextSelection.fromPosition(
      TextPosition(
        offset: _mentionStartIndex + user.username.length + 2,
      ),
    );

    _viewModel.addMention(user);
    _hideMentionSuggestions();
  }

  void _handlePostComment() async {
    if (_replyController.text.trim().isEmpty) return;

    // Use replyingTo.id if replying to a comment, otherwise use main twizz id
    final parentId =
        _viewModel.replyingTo?.id ?? widget.args.twizzId;

    final success = await _viewModel.postComment(
      parentId,
      _replyController.text.trim(),
    );

    if (success) {
      _replyController.clear();
      _replyFocusNode.unfocus();
      _viewModel.clearReplyingTo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng câu trả lời')),
        );
      }
    }
  }

  void _handleQuote(Twizz twizz) {
    Navigator.pushNamed(
      context,
      RouteNames.createTwizz,
      arguments: twizz,
    );
  }

  /// Handle delete action for twizz/comment/reply
  void _handleDelete(
    Twizz twizz,
    TwizzDetailViewModel viewModel,
  ) async {
    final wasMainPost = await viewModel.deleteTwizz(twizz);

    if (wasMainPost && mounted) {
      // Main post was deleted, navigate back
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bài viết')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bình luận')),
      );
    }
  }

  void _navigateToProfile(User? user) {
    if (user == null) return;

    final authViewModel = context.read<AuthViewModel>();
    final currentUserId = authViewModel.currentUser?.id;

    if (user.id == currentUserId) {
      Navigator.pushNamed(context, RouteNames.myProfile);
    } else if (user.username != null &&
        user.username!.isNotEmpty) {
      Navigator.pushNamed(
        context,
        RouteNames.userProfile,
        arguments: user.username,
      );
    }
  }

  /// Build a nested reply item with visual thread indicator
  Widget _buildReplyItem(
    Twizz reply,
    String? currentUserId,
    TwizzDetailViewModel viewModel,
  ) {
    final themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 1,
              color: themeData.colorScheme.outline,
            ),
          ),
        ),
        child: TwizzItem(
          twizz: reply,
          currentUserId: currentUserId,
          onLike: (t) => viewModel.toggleLike(t),
          onComment: (t) {
            viewModel.setReplyingTo(t);
            _replyFocusNode.requestFocus();
          },
          onQuote: _handleQuote,
          onBookmark: (t) => viewModel.toggleBookmark(t),
          onDelete: (t) => _handleDelete(t, viewModel),
          onUserTap: () => _navigateToProfile(reply.user),
          onTap: () {
            Navigator.pushNamed(
              context,
              RouteNames.twizzDetail,
              arguments: TwizzDetailScreenArgs(
                twizzId: reply.id,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUserId = authViewModel.currentUser?.id;

    return ChangeNotifierProvider<TwizzDetailViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Chi tiết',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<TwizzDetailViewModel>(
                builder: (context, viewModel, child) {
                  return NotificationListener<
                    ScrollNotification
                  >(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels ==
                              scrollInfo
                                  .metrics
                                  .maxScrollExtent &&
                          !viewModel.isLoadingMoreComments &&
                          viewModel.hasMoreComments) {
                        viewModel.loadComments(
                          widget.args.twizzId,
                        );
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh:
                          () => viewModel.loadComments(
                            widget.args.twizzId,
                            refresh: true,
                          ),
                      child: ListView.builder(
                        itemCount:
                            viewModel.comments.length +
                            2, // 1 for main post, 1 for divider/interaction header
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Main Twizz Post
                            final mainTwizz = viewModel.twizz;

                            if (mainTwizz == null) {
                              return const SizedBox(
                                height: 200,
                                child: Center(
                                  child:
                                      CircularProgressIndicator(),
                                ),
                              );
                            }

                            final hasParent =
                                mainTwizz.type ==
                                    TwizzType.comment &&
                                mainTwizz.parentTwizz != null;

                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (hasParent) ...[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                          16,
                                          12,
                                          16,
                                          4,
                                        ),
                                    child: Text(
                                      'Đang bình luận:',
                                      style: themeData
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: themeData
                                                .colorScheme
                                                .onSurface
                                                .withValues(
                                                  alpha: 0.6,
                                                ),
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  TwizzItem(
                                    twizz:
                                        mainTwizz.parentTwizz!,
                                    currentUserId: currentUserId,
                                    isEmbedded: true,
                                    showToolbar: false,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.twizzDetail,
                                        arguments:
                                            TwizzDetailScreenArgs(
                                              twizzId:
                                                  mainTwizz
                                                      .parentTwizz!
                                                      .id,
                                            ),
                                      );
                                    },
                                    onUserTap:
                                        () => _navigateToProfile(
                                          mainTwizz
                                              .parentTwizz!
                                              .user,
                                        ),
                                  ),
                                  // Thread line indicator effect
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left:
                                          36, // Centered for 4 width (38 - 2)
                                    ),
                                    child: Container(
                                      width: 4,
                                      height: 12,
                                      color: themeData
                                          .dividerColor
                                          .withValues(
                                            alpha: 0.4,
                                          ),
                                    ),
                                  ),
                                ],
                                Padding(
                                  padding:
                                      mainTwizz.type ==
                                              TwizzType.comment
                                          ? const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          )
                                          : EdgeInsets.zero,
                                  child: TwizzItem(
                                    twizz: mainTwizz,
                                    currentUserId: currentUserId,
                                    isEmbedded:
                                        mainTwizz.type ==
                                        TwizzType.comment,
                                    isHighlighted:
                                        mainTwizz.type ==
                                        TwizzType.comment,
                                    showToolbar: true,
                                    onLike:
                                        (t) =>
                                            viewModel
                                                .toggleLike(),
                                    onComment: (t) {
                                      viewModel
                                          .clearReplyingTo();
                                      _replyFocusNode
                                          .requestFocus();
                                    },
                                    onQuote: _handleQuote,
                                    onBookmark:
                                        (t) =>
                                            viewModel
                                                .toggleBookmark(),
                                    onDelete:
                                        (t) => _handleDelete(
                                          t,
                                          viewModel,
                                        ),
                                    onUserTap:
                                        () => _navigateToProfile(
                                          mainTwizz.user,
                                        ),
                                  ),
                                ),
                                const Divider(),
                              ],
                            );
                          }

                          if (index ==
                              viewModel.comments.length + 1) {
                            if (viewModel
                                .isLoadingMoreComments) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                  child:
                                      CircularProgressIndicator(),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          // Comments
                          final comment =
                              viewModel.comments[index - 1];

                          // Load replies for this comment if not loaded yet
                          if (comment.commentCount != null &&
                              comment.commentCount! > 0 &&
                              !viewModel.repliesMap.containsKey(
                                comment.id,
                              ) &&
                              !viewModel.isLoadingReplies(
                                comment.id,
                              )) {
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) {
                                  viewModel
                                      .loadRepliesForComment(
                                        comment.id,
                                      );
                                });
                          }

                          final replies =
                              viewModel.repliesMap[comment.id] ??
                              [];

                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // Main comment
                              TwizzItem(
                                twizz: comment,
                                currentUserId: currentUserId,
                                onLike:
                                    (t) =>
                                        viewModel.toggleLike(t),
                                onComment: (t) {
                                  viewModel.setReplyingTo(t);
                                  _replyFocusNode.requestFocus();
                                },
                                onQuote: _handleQuote,
                                onBookmark:
                                    (t) => viewModel
                                        .toggleBookmark(t),
                                onDelete:
                                    (t) => _handleDelete(
                                      t,
                                      viewModel,
                                    ),
                                onUserTap:
                                    () => _navigateToProfile(
                                      comment.user,
                                    ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.twizzDetail,
                                    arguments:
                                        TwizzDetailScreenArgs(
                                          twizzId: comment.id,
                                        ),
                                  );
                                },
                              ),

                              // Nested replies
                              if (replies.isNotEmpty)
                                ...replies.map(
                                  (reply) => _buildReplyItem(
                                    reply,
                                    currentUserId,
                                    viewModel,
                                  ),
                                ),

                              // Loading indicator for replies
                              if (viewModel.isLoadingReplies(
                                comment.id,
                              ))
                                const Padding(
                                  padding: EdgeInsets.only(
                                    left: 32,
                                    top: 4,
                                    bottom: 8,
                                  ),
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child:
                                        CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                  ),
                                ),

                              // View more replies link
                              if (comment.commentCount != null &&
                                  comment.commentCount! >
                                      replies.length &&
                                  replies.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 48,
                                    bottom: 8,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.twizzDetail,
                                        arguments:
                                            TwizzDetailScreenArgs(
                                              twizzId:
                                                  comment.id,
                                            ),
                                      );
                                    },
                                    child: Text(
                                      'Xem thêm ${comment.commentCount! - replies.length} trả lời',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            // Reply Input field
            _buildReplyInput(currentUserId),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput(String? currentUserId) {
    final themeData = Theme.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;
    final avatar = user?.avatar;
    final name = user?.name ?? 'U';

    return Consumer<TwizzDetailViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: themeData.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: themeData.colorScheme.onSurface
                    .withValues(alpha: 0.1),
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Media preview area
                if (viewModel.selectedImages.isNotEmpty)
                  TwizzCreateMediaPreview(
                    images: viewModel.selectedImages,
                    onRemove: viewModel.removeImage,
                    isLoading: viewModel.isPostingComment,
                  ),
                if (viewModel.selectedVideo != null)
                  TwizzCreateVideoPreview(
                    video: viewModel.selectedVideo!,
                    onRemove: viewModel.removeVideo,
                    isLoading: viewModel.isPostingComment,
                  ),
                if (viewModel.selectedImages.isNotEmpty ||
                    viewModel.selectedVideo != null)
                  const SizedBox(height: 12),

                // Replying to header
                if (viewModel.replyingTo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.reply,
                          size: 16,
                          color: themeData.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Đang trả lời @${viewModel.replyingTo!.user?.username ?? 'user'}',
                          style: themeData.textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    themeData
                                        .colorScheme
                                        .primary,
                              ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap:
                              () => viewModel.clearReplyingTo(),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: themeData
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToProfile(user),
                      child:
                          avatar != null
                              ? CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                  avatar,
                                ),
                                onBackgroundImageError:
                                    (e, s) {},
                              )
                              : CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    themeData
                                        .colorScheme
                                        .primary,
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        themeData
                                            .colorScheme
                                            .onPrimary,
                                  ),
                                ),
                              ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: _replyController,
                            focusNode: _replyFocusNode,
                            decoration: InputDecoration(
                              fillColor:
                                  themeData.colorScheme.surface,
                              hintText:
                                  'Đăng câu trả lời của bạn',
                              hintStyle: themeData
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: themeData
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                          ),

                          // Mention suggestions
                          if (_showMentionSuggestions)
                            MentionSuggestions(
                              query: _mentionQuery,
                              results: viewModel.searchResults,
                              isLoading:
                                  viewModel.isSearchingUsers,
                              onSelect: _insertMention,
                            ),
                          // Toolbar
                          Row(
                            children: [
                              IconButton(
                                onPressed:
                                    viewModel.isPostingComment ||
                                            viewModel
                                                    .selectedVideo !=
                                                null ||
                                            viewModel
                                                    .selectedImages
                                                    .length >=
                                                TwizzDetailViewModel
                                                    .maxImages
                                        ? null
                                        : _pickImages,
                                icon: Icon(
                                  Icons.photo_library_outlined,
                                  color:
                                      viewModel.isPostingComment ||
                                              viewModel
                                                      .selectedVideo !=
                                                  null ||
                                              viewModel
                                                      .selectedImages
                                                      .length >=
                                                  TwizzDetailViewModel
                                                      .maxImages
                                          ? themeData
                                              .colorScheme
                                              .onSurface
                                              .withValues(
                                                alpha: 0.3,
                                              )
                                          : themeData
                                              .colorScheme
                                              .primary,
                                  size: 20,
                                ),
                                constraints:
                                    const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                              IconButton(
                                onPressed:
                                    viewModel.isPostingComment ||
                                            viewModel
                                                    .selectedVideo !=
                                                null ||
                                            viewModel
                                                    .selectedImages
                                                    .length >=
                                                TwizzDetailViewModel
                                                    .maxImages
                                        ? null
                                        : _takePhoto,
                                icon: Icon(
                                  Icons.camera_alt_outlined,
                                  color:
                                      viewModel.isPostingComment ||
                                              viewModel
                                                      .selectedVideo !=
                                                  null ||
                                              viewModel
                                                      .selectedImages
                                                      .length >=
                                                  TwizzDetailViewModel
                                                      .maxImages
                                          ? themeData
                                              .colorScheme
                                              .onSurface
                                              .withValues(
                                                alpha: 0.3,
                                              )
                                          : themeData
                                              .colorScheme
                                              .primary,
                                  size: 20,
                                ),
                                constraints:
                                    const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                              IconButton(
                                onPressed:
                                    viewModel.isPostingComment ||
                                            viewModel
                                                .selectedImages
                                                .isNotEmpty ||
                                            viewModel
                                                    .selectedVideo !=
                                                null
                                        ? null
                                        : _pickVideo,
                                icon: Icon(
                                  Icons.videocam_outlined,
                                  color:
                                      viewModel.isPostingComment ||
                                              viewModel
                                                  .selectedImages
                                                  .isNotEmpty ||
                                              viewModel
                                                      .selectedVideo !=
                                                  null
                                          ? themeData
                                              .colorScheme
                                              .onSurface
                                              .withValues(
                                                alpha: 0.3,
                                              )
                                          : themeData
                                              .colorScheme
                                              .primary,
                                  size: 20,
                                ),
                                constraints:
                                    const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                              if (viewModel
                                  .selectedImages
                                  .isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                  decoration: BoxDecoration(
                                    color: themeData
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(
                                          12,
                                        ),
                                  ),
                                  child: Text(
                                    '${viewModel.selectedImages.length}/${TwizzDetailViewModel.maxImages} ảnh',
                                    style: TextStyle(
                                      color:
                                          themeData
                                              .colorScheme
                                              .primary,
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ] else if (viewModel
                                      .selectedVideo !=
                                  null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                  decoration: BoxDecoration(
                                    color: themeData
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(
                                          12,
                                        ),
                                  ),
                                  child: Text(
                                    '1 video',
                                    style: TextStyle(
                                      color:
                                          themeData
                                              .colorScheme
                                              .primary,
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              ValueListenableBuilder<
                                TextEditingValue
                              >(
                                valueListenable:
                                    _replyController,
                                builder: (
                                  context,
                                  textValue,
                                  _,
                                ) {
                                  final bool canPost =
                                      textValue.text
                                          .trim()
                                          .isNotEmpty &&
                                      !viewModel
                                          .isPostingComment;

                                  return TextButton(
                                    onPressed:
                                        canPost
                                            ? _handlePostComment
                                            : null,
                                    style: TextButton.styleFrom(
                                      backgroundColor:
                                          themeData
                                              .colorScheme
                                              .primary,
                                      foregroundColor:
                                          themeData
                                              .colorScheme
                                              .onPrimary,
                                      disabledBackgroundColor:
                                          themeData
                                              .colorScheme
                                              .primary
                                              .withValues(
                                                alpha: 0.3,
                                              ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                              20,
                                            ),
                                      ),
                                      padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                    ),
                                    child:
                                        viewModel
                                                .isPostingComment
                                            ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      Colors
                                                          .white,
                                                    ),
                                              ),
                                            )
                                            : const Text(
                                              'Trả lời',
                                              style: TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                              ),
                                            ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
