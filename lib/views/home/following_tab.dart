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
          onTwizzTap: (twizz) {
            Navigator.pushNamed(
              context,
              RouteNames.twizzDetail,
              arguments: TwizzDetailScreenArgs(twizz: twizz),
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
                twizz: twizz,
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
          emptyWidget: _buildEmptyState(context),
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
}
