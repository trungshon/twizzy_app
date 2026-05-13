import 'dart:ui';
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
          emptyWidget: viewModel.globalTotal > 0
              ? _buildCaughtUpCard(context, viewModel)
              : _buildEmptyState(context),
          endOfListWidget: viewModel.globalTotal > 0
              ? _buildCaughtUpCard(context, viewModel)
              : _buildEmptyState(context),
          currentUserId: currentUserId,
          onVisibilityChanged: (twizz, fraction) {
            viewModel.reportVisibility(twizz.id, fraction);
          },
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
        );
      },
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
              'Các bài viết đề xuất sẽ hiển thị ở đây khi hệ thống có dữ liệu.',
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

  /// Build "Caught up" card with Glassmorphism
  Widget _buildCaughtUpCard(
    BuildContext context,
    RecommendationsViewModel viewModel,
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
                    'Bạn đã bắt kịp tất cả nội dung đề xuất dành cho bạn hiện có trên hệ thống.',
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
                              : () => viewModel.resetAllViews(),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
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
