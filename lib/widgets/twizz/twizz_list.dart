import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../models/twizz/twizz_models.dart';
import 'twizz_item.dart';

/// TwizzList Widget
///
/// Widget hiển thị danh sách các bài twizz
class TwizzList extends StatelessWidget {
  final List<Twizz> twizzs;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;
  final void Function(Twizz)? onTwizzTap;
  final void Function(Twizz)? onUserTap;
  final void Function(Twizz)? onLike;
  final void Function(Twizz)? onComment;
  final void Function(Twizz)? onQuote;
  final void Function(Twizz)? onBookmark;
  final void Function(Twizz)? onDelete;
  final Widget? emptyWidget;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final String? currentUserId;
  final void Function(Twizz twizz, double fraction)?
  onVisibilityChanged;
  final Widget? endOfListWidget;

  const TwizzList({
    super.key,
    required this.twizzs,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onRefresh,
    this.onTwizzTap,
    this.onUserTap,
    this.onLike,
    this.onComment,
    this.onQuote,
    this.onBookmark,
    this.onDelete,
    this.emptyWidget,
    this.scrollController,
    this.padding,
    this.currentUserId,
    this.onVisibilityChanged,
    this.endOfListWidget,
  });

  @override
  Widget build(BuildContext context) {
    // List with refresh
    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child:
            twizzs.isEmpty && !isLoading
                ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).size.height * 0.7,
                    child:
                        emptyWidget ??
                        _buildDefaultEmpty(context),
                  ),
                )
                : _buildList(context),
      );
    }

    // Empty state without refresh
    if (twizzs.isEmpty && !isLoading) {
      return emptyWidget ?? _buildDefaultEmpty(context);
    }

    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            hasMore &&
            !isLoading &&
            onLoadMore != null) {
          Future.microtask(() => onLoadMore!());
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: (padding ?? EdgeInsets.zero).add(
          const EdgeInsets.only(bottom: 80),
        ),
        itemCount:
            twizzs.length +
            (isLoading || (!hasMore && endOfListWidget != null)
                ? 1
                : 0),
        itemBuilder: (context, index) {
          // Loading indicator at bottom
          if (index == twizzs.length) {
            if (isLoading) {
              return _buildLoadingIndicator(context);
            }
            if (!hasMore && endOfListWidget != null) {
              return endOfListWidget!;
            }
            return const SizedBox.shrink();
          }

          final twizz = twizzs[index];
          final currentAlgo = twizz.recommendationInfo?.algorithm;

          bool isHeaderOfSection = false;
          if (index == 0 && currentAlgo != null && currentAlgo.isNotEmpty) {
            isHeaderOfSection = true;
          } else if (index > 0 && currentAlgo != null && currentAlgo.isNotEmpty) {
            final prevAlgo = twizzs[index - 1].recommendationInfo?.algorithm;
            if (currentAlgo != prevAlgo) {
              isHeaderOfSection = true;
            }
          }

          Widget item = TwizzItem(
            key: ValueKey(twizz.id),
            twizz: twizz,
            currentUserId: currentUserId,
            onTap:
                onTwizzTap != null
                    ? () => onTwizzTap!(twizz)
                    : null,
            onUserTap:
                onUserTap != null
                    ? () => onUserTap!(twizz)
                    : null,
            onLike: onLike,
            onComment: onComment,
            onQuote: onQuote,
            onBookmark: onBookmark,
            onDelete: onDelete,
          );

          if (onVisibilityChanged != null) {
            item = VisibilityDetector(
              key: Key('twizz_list_${twizz.id}'),
              onVisibilityChanged: (info) {
                onVisibilityChanged!(
                  twizz,
                  info.visibleFraction,
                );
              },
              child: item,
            );
          }

          if (isHeaderOfSection) {
            item = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(context, currentAlgo!),
                item,
              ],
            );
          }

          return item;
        },
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final themeData = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              themeData.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultEmpty(BuildContext context) {
    final themeData = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: themeData.colorScheme.onSurface.withValues(
              alpha: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài viết',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bài viết sẽ hiển thị ở đây',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sliver version of TwizzList for use in CustomScrollView/NestedScrollView
class SliverTwizzList extends StatelessWidget {
  final List<Twizz> twizzs;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final void Function(Twizz)? onTwizzTap;
  final void Function(Twizz)? onUserTap;
  final void Function(Twizz)? onLike;
  final void Function(Twizz)? onComment;
  final void Function(Twizz)? onQuote;
  final void Function(Twizz)? onBookmark;
  final void Function(Twizz)? onDelete;
  final Widget? emptyWidget;
  final String? currentUserId;
  final void Function(Twizz twizz, double fraction)?
  onVisibilityChanged;
  final Widget? endOfListWidget;

  const SliverTwizzList({
    super.key,
    required this.twizzs,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onTwizzTap,
    this.onUserTap,
    this.onLike,
    this.onComment,
    this.onQuote,
    this.onBookmark,
    this.onDelete,
    this.emptyWidget,
    this.currentUserId,
    this.onVisibilityChanged,
    this.endOfListWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Empty state
    if (twizzs.isEmpty && !isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: emptyWidget ?? _buildDefaultEmpty(context),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Loading indicator at bottom
            if (index == twizzs.length) {
              if (isLoading) {
                return _buildLoadingIndicator(context);
              }
              if (!hasMore && endOfListWidget != null) {
                return endOfListWidget!;
              }
              return const SizedBox.shrink();
            }

            final twizz = twizzs[index];
            final currentAlgo = twizz.recommendationInfo?.algorithm;

            bool isHeaderOfSection = false;
            if (index == 0 && currentAlgo != null && currentAlgo.isNotEmpty) {
              isHeaderOfSection = true;
            } else if (index > 0 && currentAlgo != null && currentAlgo.isNotEmpty) {
              final prevAlgo = twizzs[index - 1].recommendationInfo?.algorithm;
              if (currentAlgo != prevAlgo) {
                isHeaderOfSection = true;
              }
            }

            Widget item = TwizzItem(
              key: ValueKey(twizz.id),
              twizz: twizz,
              currentUserId: currentUserId,
              onTap:
                  onTwizzTap != null
                      ? () => onTwizzTap!(twizz)
                      : null,
              onUserTap:
                  onUserTap != null
                      ? () => onUserTap!(twizz)
                      : null,
              onLike: onLike,
              onComment: onComment,
              onQuote: onQuote,
              onBookmark: onBookmark,
              onDelete: onDelete,
            );

            if (onVisibilityChanged != null) {
              item = VisibilityDetector(
                key: Key('sliver_twizz_${twizz.id}'),
                onVisibilityChanged: (info) {
                  onVisibilityChanged!(
                    twizz,
                    info.visibleFraction,
                  );
                },
                child: item,
              );
            }

            if (isHeaderOfSection) {
              item = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSectionHeader(context, currentAlgo!),
                  item,
                ],
              );
            }

            return item;
          },
          childCount:
              twizzs.length +
              (isLoading || hasMore || endOfListWidget != null
                  ? 1
                  : 0),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final themeData = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              themeData.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultEmpty(BuildContext context) {
    final themeData = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: themeData.colorScheme.onSurface.withValues(
              alpha: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài viết',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bài viết sẽ hiển thị ở đây',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to build a styled header for feed sections
Widget _buildSectionHeader(BuildContext context, String algorithm) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  String text = '';
  IconData icon = Icons.star;
  Color color = theme.colorScheme.primary;

  switch (algorithm) {
    case 'content':
      text = 'Có thể bạn thích';
      icon = Icons.auto_awesome_rounded;
      color = isDark ? Colors.purpleAccent : Colors.purple;
      break;
    case 'trending':
      text = 'Bài viết nổi bật';
      icon = Icons.local_fire_department_rounded;
      color = isDark ? Colors.orangeAccent : Colors.orange;
      break;
    case 'following':
      text = 'Từ những người bạn theo dõi';
      icon = Icons.people_outline_rounded;
      color = isDark ? Colors.greenAccent : Colors.green;
      break;
    default:
      return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.8),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: color.withValues(alpha: 0.2),
            thickness: 1,
          ),
        ),
      ],
    ),
  );
}
