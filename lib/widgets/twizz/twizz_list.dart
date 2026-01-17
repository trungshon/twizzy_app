import 'package:flutter/material.dart';
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
  final Function(Twizz)? onTwizzTap;
  final Function(Twizz)? onUserTap;
  final Function(Twizz)? onLike;
  final Function(Twizz)? onComment;
  final Function(Twizz)? onRetwizz;
  final Function(Twizz)? onBookmark;
  final Widget? emptyWidget;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;

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
    this.onRetwizz,
    this.onBookmark,
    this.emptyWidget,
    this.scrollController,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Empty state
    if (twizzs.isEmpty && !isLoading) {
      return emptyWidget ?? _buildDefaultEmpty(context);
    }

    // List with refresh
    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: _buildList(context),
      );
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
          onLoadMore!();
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: padding,
        itemCount:
            twizzs.length + (isLoading || hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at bottom
          if (index == twizzs.length) {
            return _buildLoadingIndicator(context);
          }

          final twizz = twizzs[index];
          return TwizzItem(
            twizz: twizz,
            onTap:
                onTwizzTap != null
                    ? () => onTwizzTap!(twizz)
                    : null,
            onUserTap:
                onUserTap != null
                    ? () => onUserTap!(twizz)
                    : null,
            onLike: onLike != null ? () => onLike!(twizz) : null,
            onComment:
                onComment != null
                    ? () => onComment!(twizz)
                    : null,
            onRetwizz:
                onRetwizz != null
                    ? () => onRetwizz!(twizz)
                    : null,
            onBookmark:
                onBookmark != null
                    ? () => onBookmark!(twizz)
                    : null,
          );
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
  final Function(Twizz)? onTwizzTap;
  final Function(Twizz)? onUserTap;
  final Function(Twizz)? onLike;
  final Function(Twizz)? onComment;
  final Function(Twizz)? onRetwizz;
  final Function(Twizz)? onBookmark;
  final Widget? emptyWidget;

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
    this.onRetwizz,
    this.onBookmark,
    this.emptyWidget,
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Loading indicator at bottom
          if (index == twizzs.length) {
            return _buildLoadingIndicator(context);
          }

          final twizz = twizzs[index];
          return TwizzItem(
            twizz: twizz,
            onTap:
                onTwizzTap != null
                    ? () => onTwizzTap!(twizz)
                    : null,
            onUserTap:
                onUserTap != null
                    ? () => onUserTap!(twizz)
                    : null,
            onLike: onLike != null ? () => onLike!(twizz) : null,
            onComment:
                onComment != null
                    ? () => onComment!(twizz)
                    : null,
            onRetwizz:
                onRetwizz != null
                    ? () => onRetwizz!(twizz)
                    : null,
            onBookmark:
                onBookmark != null
                    ? () => onBookmark!(twizz)
                    : null,
          );
        },
        childCount:
            twizzs.length + (isLoading || hasMore ? 1 : 0),
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
