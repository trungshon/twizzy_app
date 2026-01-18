import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/twizz/twizz_models.dart';

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
  final void Function(Twizz)? onRetwizz;
  final void Function(Twizz)? onQuote;
  final void Function(Twizz)? onBookmark;
  final void Function(Twizz)? onDelete;

  const TwizzItem({
    super.key,
    required this.twizz,
    this.currentUserId,
    this.onTap,
    this.onUserTap,
    this.onLike,
    this.onComment,
    this.onRetwizz,
    this.onQuote,
    this.onBookmark,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    // For retwizz, show parent twizz content
    final isRetwizz = twizz.type == TwizzType.retwizz;
    final displayTwizz =
        (isRetwizz && twizz.parentTwizz != null)
            ? twizz.parentTwizz!
            : twizz;
    final user = displayTwizz.user;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
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
            // Retwizz header
            if (isRetwizz)
              _buildRetwizzHeader(context, themeData),
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
                            // TODO: Navigate to user profile
                          },
                          onHashtagTap: (hashtag) {
                            // TODO: Navigate to hashtag search
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
                      // Toolbar
                      const SizedBox(height: 12),
                      _TwizzToolbar(
                        commentCount:
                            displayTwizz.commentCount ?? 0,
                        retwizzCount:
                            displayTwizz.retwizzCount ?? 0,
                        quoteCount: displayTwizz.quoteCount ?? 0,
                        likeCount: displayTwizz.likes ?? 0,
                        viewCount:
                            displayTwizz.userViews +
                            displayTwizz.guestViews,
                        isLiked: displayTwizz.isLiked,
                        isBookmarked: displayTwizz.isBookmarked,
                        isRetwizzed: displayTwizz.isRetwizzed,
                        onComment:
                            () => onComment?.call(displayTwizz),
                        onRetwizz:
                            () => onRetwizz?.call(displayTwizz),
                        onQuote:
                            () => onQuote?.call(displayTwizz),
                        onLike: () => onLike?.call(displayTwizz),
                        onBookmark:
                            () => onBookmark?.call(displayTwizz),
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
  }

  /// Build retwizz header showing who retwizzed
  Widget _buildRetwizzHeader(
    BuildContext context,
    ThemeData themeData,
  ) {
    final retwizzUser = twizz.user;
    final isCurrentUser =
        currentUserId != null && currentUserId == twizz.userId;
    final displayName =
        isCurrentUser
            ? 'Bạn đã đăng lại'
            : '${retwizzUser?.name ?? 'Người dùng'} đã đăng lại';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 34),
      child: Row(
        children: [
          Icon(
            Icons.repeat,
            size: 14,
            color: themeData.colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            displayName,
            style: themeData.textTheme.bodySmall?.copyWith(
              color: themeData.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      children: [
        // Name
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: onUserTap,
                  child: Text(
                    name,
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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
              // Username
              Flexible(
                child: Text(
                  '@$username',
                  style: themeData.textTheme.bodyMedium
                      ?.copyWith(
                        color: themeData.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Dot separator
              Text(
                ' · ',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              // Time
              Text(
                timeAgo,
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        // More button
        GestureDetector(
          onTap: () {
            _showMoreOptions(context, displayTwizz);
          },
          child: Icon(
            Icons.more_horiz,
            size: 18,
            color: themeData.colorScheme.onSurface.withValues(
              alpha: 0.6,
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
                  // TODO: Implement View Interactions
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
          title: const Text('Xóa bài viết?'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.',
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
class _TwizzContent extends StatelessWidget {
  final String content;
  final Function(String) onMentionTap;
  final Function(String) onHashtagTap;

  const _TwizzContent({
    required this.content,
    required this.onMentionTap,
    required this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    const highlightColor = Color(0xFF1DA1F2);

    // Parse content for mentions and hashtags
    final spans = _parseContent(
      content,
      themeData,
      highlightColor,
    );

    return Text.rich(
      TextSpan(
        style: themeData.textTheme.bodyLarge?.copyWith(
          height: 1.4,
        ),
        children: spans,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
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
      spans.add(
        TextSpan(
          text: matchText,
          style: TextStyle(color: highlightColor),
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
      return _TwizzVideoPlayer(url: medias.first.url);
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

/// Video Player for Twizz
class _TwizzVideoPlayer extends StatefulWidget {
  final String url;

  const _TwizzVideoPlayer({required this.url});

  @override
  State<_TwizzVideoPlayer> createState() =>
      _TwizzVideoPlayerState();
}

class _TwizzVideoPlayerState extends State<_TwizzVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // Backend returns full URL for video
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    );
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        color: Colors.black,
        child: Stack(
          children: [
            if (_isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            else if (_hasError)
              const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white54,
                  size: 48,
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            // Play/Pause overlay
            if (_isInitialized)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _togglePlay,
                  child: AnimatedOpacity(
                    opacity:
                        _controller.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: 0.6,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Duration indicator
            if (_isInitialized)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(_controller.value.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// Twizz Action Toolbar
class _TwizzToolbar extends StatelessWidget {
  final int commentCount;
  final int retwizzCount;
  final int quoteCount;
  final int likeCount;
  final int viewCount;
  final bool isLiked;
  final bool isBookmarked;
  final bool isRetwizzed;
  final VoidCallback? onComment;
  final VoidCallback? onRetwizz;
  final VoidCallback? onQuote;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;

  const _TwizzToolbar({
    required this.commentCount,
    required this.retwizzCount,
    required this.quoteCount,
    required this.likeCount,
    required this.viewCount,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isRetwizzed = false,
    this.onComment,
    this.onRetwizz,
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Comment
        _ToolbarItem(
          icon: Icons.chat_bubble_outline,
          count: commentCount,
          color: iconColor,
          onTap: onComment,
        ),
        // Retwizz
        _ToolbarItem(
          icon: Icons.repeat,
          count: retwizzCount,
          color: isRetwizzed ? Colors.green : iconColor,
          onTap: onRetwizz,
        ),
        // Quote
        _ToolbarItem(
          icon: Icons.format_quote,
          count: quoteCount,
          color: iconColor,
          onTap: onQuote,
        ),
        // Like
        _ToolbarItem(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          count: likeCount,
          color: isLiked ? Colors.red : iconColor,
          onTap: onLike,
        ),
        // Bookmark
        GestureDetector(
          onTap: onBookmark,
          child: Icon(
            isBookmarked
                ? Icons.bookmark
                : Icons.bookmark_border,
            size: 24,
            color:
                isBookmarked
                    ? const Color(0xFF1DA1F2)
                    : iconColor,
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
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              _formatCount(count),
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ],
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
