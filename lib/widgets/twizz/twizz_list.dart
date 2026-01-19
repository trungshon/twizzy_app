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
            twizzs.length + (isLoading || hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at bottom
          if (index == twizzs.length) {
            return _buildLoadingIndicator(context);
          }

          final twizz = twizzs[index];
          return TwizzItem(
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
              return _buildLoadingIndicator(context);
            }

            final twizz = twizzs[index];
            return TwizzItem(
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
          },
          childCount:
              twizzs.length + (isLoading || hasMore ? 1 : 0),
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
