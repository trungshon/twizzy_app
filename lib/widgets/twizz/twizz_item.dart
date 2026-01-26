import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/twizz/twizz_models.dart';
import '../../routes/route_names.dart';
import '../../viewmodels/main/main_viewmodel.dart';
import '../../viewmodels/search/search_viewmodel.dart';
import '../../views/twizz/twizz_interaction_screen.dart';
import '../../views/twizz/twizz_detail_screen.dart';
import '../common/twizz_video_player.dart';

/// TwizzItem Widget
///
/// Widget hiển thị một bài twizz
class TwizzItem extends StatelessWidget {
  final Twizz twizz;
  final String?
  currentUserId; // Current user ID to check if "Bạn đã đăng lại"
  final VoidCallback? onTap;
  final VoidCallback? onUserTap;
  final void Function(Twizz)? onLike;
  final void Function(Twizz)? onComment;
  final void Function(Twizz)? onQuote;
  final void Function(Twizz)? onBookmark;
  final void Function(Twizz)? onDelete;

  final bool isEmbedded;
  final bool showToolbar;

  const TwizzItem({
    super.key,
    required this.twizz,
    this.currentUserId,
    this.onTap,
    this.onUserTap,
    this.onLike,
    this.onComment,
    this.onQuote,
    this.onBookmark,
    this.onDelete,
    this.isEmbedded = false,
    this.showToolbar = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    final isQuoteTwizz = twizz.type == TwizzType.quoteTwizz;
    final displayTwizz = twizz;
    final user = displayTwizz.user;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            isEmbedded
                ? const EdgeInsets.all(12)
                : const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
        decoration:
            isEmbedded
                ? BoxDecoration(
                  border: Border.all(
                    color: themeData.dividerColor.withValues(
                      alpha: 0.2,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                )
                : BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: themeData.dividerColor.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                GestureDetector(
                  onTap: onUserTap,
                  child: _buildAvatar(themeData, user),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: name, username, time
                      _buildHeader(
                        context,
                        themeData,
                        user,
                        displayTwizz,
                      ),
                      const SizedBox(height: 4),
                      // Content text
                      if (displayTwizz.content.isNotEmpty)
                        _TwizzContent(
                          content: displayTwizz.content,
                          onMentionTap: (username) {
                            if (username.isNotEmpty) {
                              Navigator.pushNamed(
                                context,
                                RouteNames.userProfile,
                                arguments: username,
                              );
                            }
                          },
                          onHashtagTap: (hashtag) {
                            if (hashtag.isNotEmpty) {
                              context
                                  .read<SearchViewModel>()
                                  .search(hashtag);
                              context
                                  .read<MainViewModel>()
                                  .goToSearch();
                            }
                          },
                        ),
                      // Media
                      if (displayTwizz.medias.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 12,
                          ),
                          child: _TwizzMedia(
                            medias: displayTwizz.medias,
                          ),
                        ),
                      // Embedded parent for quote twizz
                      if ((isQuoteTwizz ||
                              displayTwizz.type ==
                                  TwizzType.twizz) &&
                          twizz.parentTwizz != null) ...[
                        if ((twizz.parentTwizz!.audience ==
                                    TwizzAudience.twizzCircle &&
                                currentUserId !=
                                    twizz.parentTwizz!.userId &&
                                (twizz
                                            .parentTwizz!
                                            .user
                                            ?.twizzCircleIds ==
                                        null ||
                                    !twizz
                                        .parentTwizz!
                                        .user!
                                        .twizzCircleIds!
                                        .contains(
                                          currentUserId,
                                        ))) ||
                            (twizz.parentTwizz!.audience ==
                                    TwizzAudience.onlyMe &&
                                currentUserId !=
                                    twizz.parentTwizz!.userId))
                          Container(
                            margin: const EdgeInsets.only(
                              top: 12,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: themeData.dividerColor
                                    .withValues(alpha: 0.3),
                              ),
                              borderRadius:
                                  BorderRadius.circular(12),
                              color: themeData
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                            ),
                            width: double.infinity,
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Bạn không có quyền xem bài viết này',
                                  style: themeData
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color:
                                            themeData
                                                .disabledColor,
                                        fontStyle:
                                            FontStyle.italic,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 12,
                            ),
                            child: TwizzItem(
                              twizz: twizz.parentTwizz!,
                              isEmbedded: true,
                              showToolbar: false,
                              currentUserId: currentUserId,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.twizzDetail,
                                  arguments:
                                      TwizzDetailScreenArgs(
                                        twizz:
                                            twizz.parentTwizz!,
                                      ),
                                );
                              },
                              onUserTap: () {
                                final parentUser =
                                    twizz.parentTwizz!.user;
                                if (parentUser == null) return;

                                if (parentUser.id ==
                                    currentUserId) {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.myProfile,
                                  );
                                } else if (parentUser.username !=
                                        null &&
                                    parentUser
                                        .username!
                                        .isNotEmpty) {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.userProfile,
                                    arguments:
                                        parentUser.username,
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                      // Toolbar
                      if (showToolbar) ...[
                        const SizedBox(height: 12),
                        _TwizzToolbar(
                          commentCount:
                              displayTwizz.commentCount ?? 0,
                          quoteCount:
                              displayTwizz.quoteCount ?? 0,
                          likeCount: displayTwizz.likes ?? 0,
                          viewCount:
                              displayTwizz.userViews +
                              displayTwizz.guestViews,
                          isLiked: displayTwizz.isLiked,
                          isBookmarked:
                              displayTwizz.isBookmarked,
                          onComment:
                              () =>
                                  onComment?.call(displayTwizz),
                          onQuote:
                              (twizz.parentTwizz == null ||
                                      twizz
                                              .parentTwizz!
                                              .parentTwizz ==
                                          null)
                                  ? () =>
                                      onQuote?.call(displayTwizz)
                                  : null,
                          onLike:
                              () => onLike?.call(displayTwizz),
                          onBookmark:
                              () =>
                                  onBookmark?.call(displayTwizz),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData themeData, user) {
    final name = user?.name ?? 'U';
    final avatar = user?.avatar;

    if (avatar != null) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatar),
        onBackgroundImageError: (e, s) {},
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: themeData.colorScheme.secondary,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: themeData.colorScheme.onSecondary,
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData themeData,
    user,
    Twizz displayTwizz,
  ) {
    final name = user?.name ?? 'User';
    final username = user?.username ?? '';
    final isVerified = user?.verify == 'Verified';
    final timeAgo = _getTimeAgo(displayTwizz.createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: GestureDetector(
                      onTap: onUserTap,
                      child: Text(
                        name,
                        style: themeData.textTheme.bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Verified badge
                  if (isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: Color(0xFF1DA1F2),
                    ),
                  ],
                  const SizedBox(width: 4),

                  // Dot separator & Time combined and made flexible
                  Flexible(
                    flex: 1,
                    child: Text(
                      ' · $timeAgo',
                      style: themeData.textTheme.bodyMedium
                          ?.copyWith(
                            color: themeData
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Audience icon - Only show for non-embedded posts
                  if (!isEmbedded) ...[
                    const SizedBox(width: 4),
                    Icon(
                      displayTwizz.audience ==
                              TwizzAudience.everyone
                          ? Icons.public
                          : displayTwizz.audience ==
                              TwizzAudience.twizzCircle
                          ? Icons.people_alt
                          : Icons.lock,
                      size: 14,
                      color: themeData.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ],
                ],
              ),
              Text(
                '@$username',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // More button - Hide when embedded to save space
        if (!isEmbedded)
          GestureDetector(
            onTap: () {
              _showMoreOptions(context, displayTwizz);
            },
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.more_horiz,
                size: 24,
                color: themeData.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }

  void _showMoreOptions(BuildContext context, Twizz twizz) {
    final themeData = Theme.of(context);
    final isOwner =
        currentUserId != null && currentUserId == twizz.userId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeData.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (isOwner)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Xóa bài viết',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, twizz);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Xem tương tác'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    RouteNames.twizzInteraction,
                    arguments: TwizzInteractionScreenArgs(
                      twizzId: twizz.id,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Twizz twizz) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa ?'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa không? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDelete?.call(twizz);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inSeconds < 0) {
      return 'Vừa xong';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Twizz Content with highlighted mentions and hashtags
/// Twizz Content with highlighted mentions and hashtags
class _TwizzContent extends StatefulWidget {
  final String content;
  final Function(String) onMentionTap;
  final Function(String) onHashtagTap;

  const _TwizzContent({
    required this.content,
    required this.onMentionTap,
    required this.onHashtagTap,
  });

  @override
  State<_TwizzContent> createState() => _TwizzContentState();
}

class _TwizzContentState extends State<_TwizzContent> {
  final List<TapGestureRecognizer> _recognizers = [];
  bool _isExpanded = false;

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    const highlightColor = Color(0xFF1DA1F2);

    _clearRecognizers();
    final spans = _parseContent(
      widget.content,
      themeData,
      highlightColor,
    );

    final textSpan = TextSpan(
      style: themeData.textTheme.bodyLarge?.copyWith(
        height: 1.4,
      ),
      children: spans,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              textSpan,
              maxLines: _isExpanded ? null : 3,
              overflow:
                  _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
              textAlign: TextAlign.justify,
            ),
            if (isOverflowing)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isExpanded ? 'Thu gọn' : 'Xem thêm',
                    style: const TextStyle(
                      color: highlightColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<InlineSpan> _parseContent(
    String text,
    ThemeData themeData,
    Color highlightColor,
  ) {
    final List<InlineSpan> spans = [];
    final RegExp regex = RegExp(r'(@\w+|#\w+)');
    int currentIndex = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before match
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
          ),
        );
      }

      // Add highlighted match
      final matchText = match.group(0)!;
      final isMention = matchText.startsWith('@');

      final recognizer =
          TapGestureRecognizer()
            ..onTap = () {
              if (isMention) {
                widget.onMentionTap(matchText.substring(1));
              } else {
                widget.onHashtagTap(matchText);
              }
            };

      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: matchText,
          style: TextStyle(
            color: highlightColor,
            fontWeight: FontWeight.bold,
          ),
          recognizer: recognizer,
        ),
      );

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return spans;
  }
}

/// Twizz Media Grid
class _TwizzMedia extends StatelessWidget {
  final List<Media> medias;

  const _TwizzMedia({required this.medias});

  @override
  Widget build(BuildContext context) {
    if (medias.isEmpty) return const SizedBox.shrink();

    // Check if it's a video
    if (medias.length == 1 &&
        medias.first.type == MediaType.video) {
      return TwizzVideoPlayer(
        url: medias.first.url,
        height: 200,
      );
    }

    // Image grid
    return _buildImageGrid(context);
  }

  Widget _buildImageGrid(BuildContext context) {
    final count = medias.length;

    if (count == 1) {
      return _buildSingleImage(medias.first);
    } else if (count == 2) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: _buildGridImage(
                medias[0],
                const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildGridImage(
                medias[1],
                const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (count == 3) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: _buildGridImage(
                medias[0],
                const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _buildGridImage(
                      medias[1],
                      const BorderRadius.only(
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _buildGridImage(
                      medias[2],
                      const BorderRadius.only(
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // 4 images
      return SizedBox(
        height: 200,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildGridImage(
                      medias[0],
                      const BorderRadius.only(
                        topLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildGridImage(
                      medias[1],
                      const BorderRadius.only(
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildGridImage(
                      medias[2],
                      const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildGridImage(
                      medias[3],
                      const BorderRadius.only(
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSingleImage(Media media) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        media.url, // Backend returns full URL
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey[800],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.white54,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridImage(
    Media media,
    BorderRadius borderRadius,
  ) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        media.url, // Backend returns full URL
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[800],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.white54,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Twizz Action Toolbar
class _TwizzToolbar extends StatelessWidget {
  final int commentCount;
  final int quoteCount;
  final int likeCount;
  final int viewCount;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback? onComment;
  final VoidCallback? onQuote;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;

  const _TwizzToolbar({
    required this.commentCount,
    required this.quoteCount,
    required this.likeCount,
    required this.viewCount,
    this.isLiked = false,
    this.isBookmarked = false,
    this.onComment,
    this.onQuote,
    this.onLike,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final iconColor = themeData.colorScheme.onSurface.withValues(
      alpha: 0.6,
    );

    return Row(
      children: [
        // Comment
        Expanded(
          child: _ToolbarItem(
            icon: Icons.chat_bubble_outline,
            count: commentCount,
            color: iconColor,
            onTap: onComment,
          ),
        ),

        // Quote
        if (onQuote != null)
          Expanded(
            child: _ToolbarItem(
              icon: Icons.format_quote,
              count: quoteCount,
              color: iconColor,
              onTap: onQuote,
            ),
          ),

        // Like
        Expanded(
          child: _ToolbarItem(
            icon:
                isLiked ? Icons.favorite : Icons.favorite_border,
            count: likeCount,
            color: isLiked ? Colors.red : iconColor,
            onTap: onLike,
          ),
        ),

        // Bookmark
        Expanded(
          child: _ToolbarItem(
            icon:
                isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border,
            count: 0,
            color:
                isBookmarked
                    ? const Color(0xFF1DA1F2)
                    : iconColor,
            onTap: onBookmark,
          ),
        ),
      ],
    );
  }
}

class _ToolbarItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const _ToolbarItem({
    required this.icon,
    required this.count,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
