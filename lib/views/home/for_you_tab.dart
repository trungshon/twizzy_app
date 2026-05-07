import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twizzy_app/widgets/twizz/twizz_list.dart';
import '../../viewmodels/recommendations/recommendations_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';
import '../twizz/twizz_detail_screen.dart';

/// For You Tab Content
///
/// Tab hiển thị nội dung đề xuất cá nhân hoá cho người dùng
class ForYouTab extends StatefulWidget {
  const ForYouTab({super.key});

  @override
  State<ForYouTab> createState() => ForYouTabState();
}

class ForYouTabState extends State<ForYouTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<RecommendationsViewModel>();
      if (viewModel.twizzs.isEmpty) {
        viewModel.loadRecommendations();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to top (được gọi từ HomeContent khi tap lại tab Đề xuất)
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

    return Consumer<RecommendationsViewModel>(
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
        if (viewModel.error != null && viewModel.twizzs.isEmpty) {
          return _buildErrorState(context, viewModel);
        }

        final authViewModel = context.watch<AuthViewModel>();
        final currentUserId = authViewModel.currentUser?.id;

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
              arguments: TwizzDetailScreenArgs(twizzId: twizz.id),
            );
          },
          onUserTap: (twizz) {
            final user = twizz.user;
            if (user == null) return;
            if (user.id == currentUserId) {
              Navigator.pushNamed(context, RouteNames.myProfile);
            } else if (user.username != null && user.username!.isNotEmpty) {
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
            Icons.explore_outlined,
            size: 64,
            color: themeData.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài viết đề xuất',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Hãy tương tác với một vài bài viết để nhận được gợi ý phù hợp',
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurface.withValues(alpha: 0.6),
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
    RecommendationsViewModel viewModel,
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
            viewModel.error ?? 'Không thể tải bài viết đề xuất',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => viewModel.loadRecommendations(refresh: true),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
