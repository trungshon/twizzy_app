import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/auth_service/auth_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';
import '../../viewmodels/twizz/twizz_interaction_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/twizz/twizz_item.dart';
import '../../widgets/user/user_list_item.dart';
import '../../models/auth/auth_models.dart';
import '../../routes/route_names.dart';
import './twizz_detail_screen.dart';

class TwizzInteractionScreenArgs {
  final String twizzId;
  final int initialTab;

  TwizzInteractionScreenArgs({
    required this.twizzId,
    this.initialTab = 0,
  });
}

class TwizzInteractionScreen extends StatefulWidget {
  final TwizzInteractionScreenArgs args;

  const TwizzInteractionScreen({super.key, required this.args});

  @override
  State<TwizzInteractionScreen> createState() =>
      _TwizzInteractionScreenState();
}

class _TwizzInteractionScreenState
    extends State<TwizzInteractionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TwizzInteractionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.args.initialTab,
    );
    _viewModel = TwizzInteractionViewModel(
      Provider.of<TwizzService>(context, listen: false),
      Provider.of<AuthService>(context, listen: false),
      Provider.of<LikeService>(context, listen: false),
      Provider.of<BookmarkService>(context, listen: false),
    );
    _loadInitialData();
  }

  void _loadInitialData() {
    _viewModel.loadQuotes(widget.args.twizzId, refresh: true);
    _viewModel.loadLikedByUsers(
      widget.args.twizzId,
      refresh: true,
    );
    _viewModel.loadBookmarkedByUsers(
      widget.args.twizzId,
      refresh: true,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final authViewModel = Provider.of<AuthViewModel>(
      context,
      listen: false,
    );
    final currentUserId = authViewModel.currentUser?.id;

    return ChangeNotifierProvider<
      TwizzInteractionViewModel
    >.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Tương tác bài viết',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Trích dẫn'),
              Tab(text: 'Đã thích'),
              Tab(text: 'Đã đánh dấu'),
            ],
            labelStyle: themeData.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            indicatorColor: themeData.colorScheme.primary,
            labelColor: themeData.colorScheme.onSurface,
            unselectedLabelColor: themeData.colorScheme.onSurface
                .withValues(alpha: 0.6),
            dividerColor: themeData.colorScheme.onSurface
                .withValues(alpha: 0.1),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildQuotesTab(currentUserId),
            _buildLikesTab(currentUserId),
            _buildBookmarksTab(currentUserId),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotesTab(String? currentUserId) {
    return Consumer<TwizzInteractionViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingQuotes &&
            viewModel.quotes.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (viewModel.quotesError != null &&
            viewModel.quotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(viewModel.quotesError!),
                ElevatedButton(
                  onPressed:
                      () => viewModel.loadQuotes(
                        widget.args.twizzId,
                        refresh: true,
                      ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (viewModel.quotes.isEmpty) {
          return const Center(
            child: Text('Chưa có trích dẫn nào'),
          );
        }

        return RefreshIndicator(
          onRefresh:
              () => viewModel.loadQuotes(
                widget.args.twizzId,
                refresh: true,
              ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent &&
                  !viewModel.isLoadingMoreQuotes &&
                  viewModel.hasMoreQuotes) {
                Future.microtask(
                  () =>
                      viewModel.loadQuotes(widget.args.twizzId),
                );
              }
              return false;
            },
            child: ListView.builder(
              itemCount:
                  viewModel.quotes.length +
                  (viewModel.isLoadingMoreQuotes ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == viewModel.quotes.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final twizz = viewModel.quotes[index];
                return TwizzItem(
                  twizz: twizz,
                  currentUserId: currentUserId,
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
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.twizzDetail,
                      arguments: TwizzDetailScreenArgs(
                        twizzId: twizz.id,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLikesTab(String? currentUserId) {
    return Consumer<TwizzInteractionViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingLikes &&
            viewModel.likedByUsers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (viewModel.likesError != null &&
            viewModel.likedByUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(viewModel.likesError!),
                ElevatedButton(
                  onPressed:
                      () => viewModel.loadLikedByUsers(
                        widget.args.twizzId,
                        refresh: true,
                      ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (viewModel.likedByUsers.isEmpty) {
          return const Center(
            child: Text('Chưa có ai thích bài viết này'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await viewModel.loadLikedByUsers(
              widget.args.twizzId,
              refresh: true,
            );
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent &&
                  !viewModel.isLoadingMoreLikes &&
                  viewModel.hasMoreLikes) {
                Future.microtask(
                  () => viewModel.loadLikedByUsers(
                    widget.args.twizzId,
                  ),
                );
              }
              return false;
            },
            child: ListView.builder(
              itemCount:
                  viewModel.likedByUsers.length +
                  (viewModel.isLoadingMoreLikes ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == viewModel.likedByUsers.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final user = viewModel.likedByUsers[index];
                final isCurrentUser = user.id == currentUserId;
                return UserListItem(
                  user: user,
                  isFollowing: user.isFollowing ?? false,
                  onFollow:
                      isCurrentUser
                          ? null
                          : () => viewModel.followUser(user),
                  onUnfollow:
                      isCurrentUser
                          ? null
                          : () => viewModel.unfollowUser(user),
                  onTap: () => _navigateToProfile(user),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookmarksTab(String? currentUserId) {
    return Consumer<TwizzInteractionViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingBookmarks &&
            viewModel.bookmarkedByUsers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (viewModel.bookmarksError != null &&
            viewModel.bookmarkedByUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(viewModel.bookmarksError!),
                ElevatedButton(
                  onPressed:
                      () => viewModel.loadBookmarkedByUsers(
                        widget.args.twizzId,
                        refresh: true,
                      ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (viewModel.bookmarkedByUsers.isEmpty) {
          return const Center(
            child: Text('Chưa có ai đánh dấu bài viết này'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await viewModel.loadBookmarkedByUsers(
              widget.args.twizzId,
              refresh: true,
            );
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent &&
                  !viewModel.isLoadingMoreBookmarks &&
                  viewModel.hasMoreBookmarks) {
                Future.microtask(
                  () => viewModel.loadBookmarkedByUsers(
                    widget.args.twizzId,
                  ),
                );
              }
              return false;
            },
            child: ListView.builder(
              itemCount:
                  viewModel.bookmarkedByUsers.length +
                  (viewModel.isLoadingMoreBookmarks ? 1 : 0),
              itemBuilder: (context, index) {
                if (index ==
                    viewModel.bookmarkedByUsers.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final user = viewModel.bookmarkedByUsers[index];
                final isCurrentUser = user.id == currentUserId;
                return UserListItem(
                  user: user,
                  isFollowing: user.isFollowing ?? false,
                  onFollow:
                      isCurrentUser
                          ? null
                          : () => viewModel.followUser(user),
                  onUnfollow:
                      isCurrentUser
                          ? null
                          : () => viewModel.unfollowUser(user),
                  onTap: () => _navigateToProfile(user),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _navigateToProfile(User user) {
    if (user.id ==
        Provider.of<AuthViewModel>(
          context,
          listen: false,
        ).currentUser?.id) {
      Navigator.pushNamed(context, RouteNames.myProfile);
    } else {
      Navigator.pushNamed(
        context,
        RouteNames.userProfile,
        arguments: user.username,
      );
    }
  }
}
