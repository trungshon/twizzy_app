import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twizzy_app/widgets/twizz/twizz_list.dart';
import '../../viewmodels/newsfeed/newsfeed_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';
import '../twizz/twizz_detail_screen.dart';

/// Following Tab Content
///
/// Tab hiển thị nội dung từ những người đang theo dõi
class FollowingTab extends StatefulWidget {
  const FollowingTab({super.key});

  @override
  State<FollowingTab> createState() => FollowingTabState();
}

class FollowingTabState extends State<FollowingTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load newsfeed on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<NewsFeedViewModel>();
      if (viewModel.twizzs.isEmpty) {
        viewModel.loadNewsFeed();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to top
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Consumer<NewsFeedViewModel>(
      builder: (context, viewModel, child) {
        // Loading state
        if (viewModel.isLoading && viewModel.twizzs.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                themeData.colorScheme.primary,
              ),
            ),
          );
        }

        // Error state
        if (viewModel.error != null &&
            viewModel.twizzs.isEmpty) {
          return _buildErrorState(context, viewModel);
        }

        final authViewModel = context.watch<AuthViewModel>();
        final currentUserId = authViewModel.currentUser?.id;

        // Twizz list
        return TwizzList(
          twizzs: viewModel.twizzs,
          isLoading: viewModel.isLoadingMore,
          hasMore: viewModel.hasMore,
          onLoadMore: viewModel.loadMore,
          onRefresh: viewModel.refresh,
          scrollController: _scrollController,
          currentUserId: currentUserId,
          onVisibilityChanged: (twizz, fraction) {
            viewModel.reportVisibility(twizz.id, fraction);
          },

          endOfListWidget: _buildCaughtUpCard(
            context,
            viewModel,
          ),
          onTwizzTap: (twizz) {
            Navigator.pushNamed(
              context,
              RouteNames.twizzDetail,
              arguments: TwizzDetailScreenArgs(
                twizzId: twizz.id,
              ),
            );
          },
          onUserTap: (twizz) {
            // Navigate to user profile or my profile
            final user = twizz.user;
            if (user == null) return;

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
          },
          onLike: (twizz) {
            viewModel.toggleLike(twizz);
          },
          onComment: (twizz) {
            Navigator.pushNamed(
              context,
              RouteNames.twizzDetail,
              arguments: TwizzDetailScreenArgs(
                twizzId: twizz.id,
                focusComment: true,
              ),
            );
          },

          onQuote: (twizz) {
            Navigator.pushNamed(
              context,
              RouteNames.createTwizz,
              arguments: twizz,
            );
          },
          onBookmark: (twizz) {
            viewModel.toggleBookmark(twizz);
          },
          onDelete: (twizz) {
            viewModel.deleteTwizz(twizz);
          },
          emptyWidget:
              (authViewModel.currentUser?.followingCount ?? 0) >
                      0
                  ? (viewModel.globalTotal > 0
                      ? _buildCaughtUpCard(context, viewModel)
                      : _buildEmptyState(context))
                  : _buildEmptyState(context),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final themeData = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Nội dung từ những người bạn đang theo dõi sẽ hiển thị ở đây',
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    NewsFeedViewModel viewModel,
  ) {
    final themeData = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: themeData.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.error ?? 'Không thể tải bài viết',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                () => viewModel.loadNewsFeed(refresh: true),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  /// Build "Caught up" card with Glassmorphism
  Widget _buildCaughtUpCard(
    BuildContext context,
    NewsFeedViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.1),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.02),
                    (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.secondary,
                    size: 60,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Đã xem hết bài viết!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bạn đã xem hết tất cả bài viết mới từ những người đang theo dõi trong 30 ngày qua.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          viewModel.isLoading
                              ? null
                              : () =>
                                  viewModel
                                      .resetFollowingViews(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.primary,
                        foregroundColor:
                            theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                      child:
                          viewModel.isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<
                                        Color
                                      >(Colors.white),
                                ),
                              )
                              : const Text(
                                'Xem lại các bài đã xem',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
