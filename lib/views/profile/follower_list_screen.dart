import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile/follower_list_viewmodel.dart';
import '../../services/auth_service/auth_service.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/user/user_list_item.dart';
import '../../models/auth/auth_models.dart';
import '../../routes/route_names.dart';

class FollowerListScreenArgs {
  final String userId;
  final String username; // Display name
  final int initialTab;

  FollowerListScreenArgs({
    required this.userId,
    required this.username,
    this.initialTab = 0,
  });
}

class FollowerListScreen extends StatefulWidget {
  final FollowerListScreenArgs args;

  const FollowerListScreen({super.key, required this.args});

  @override
  State<FollowerListScreen> createState() =>
      _FollowerListScreenState();
}

class _FollowerListScreenState extends State<FollowerListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FollowerListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.args.initialTab,
    );
    _viewModel = FollowerListViewModel(
      Provider.of<AuthService>(context, listen: false),
    );
    _loadInitialData();
  }

  void _loadInitialData() {
    // Initial load for both or just the selected one?
    // Let's load the selected one first, then others lazily or immediately?
    // User request says "display list". loading both is fine.
    _viewModel.loadFollowers(widget.args.userId);
    _viewModel.loadFollowing(widget.args.userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return ChangeNotifierProvider<FollowerListViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.args.username,
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Người theo dõi'),
              Tab(text: 'Đang theo dõi'),
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
          children: [_buildFollowersTab(), _buildFollowingTab()],
        ),
      ),
    );
  }

  Widget _buildFollowersTab() {
    return Consumer<FollowerListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingFollowers &&
            viewModel.followers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (viewModel.followersError != null &&
            viewModel.followers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(viewModel.followersError!),
                ElevatedButton(
                  onPressed:
                      () => viewModel.loadFollowers(
                        widget.args.userId,
                        refresh: true,
                      ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (viewModel.followers.isEmpty) {
          return const Center(
            child: Text('Chưa có người theo dõi nào'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await viewModel.loadFollowers(
              widget.args.userId,
              refresh: true,
            );
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent &&
                  !viewModel.isLoadingMoreFollowers &&
                  viewModel.hasMoreFollowers) {
                viewModel.loadFollowers(widget.args.userId);
              }
              return false;
            },
            child: ListView.builder(
              itemCount:
                  viewModel.followers.length +
                  (viewModel.isLoadingMoreFollowers ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == viewModel.followers.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final user = viewModel.followers[index];
                return UserListItem(
                  user: user,
                  isFollowing: user.isFollowing ?? false,
                  onFollow: () => viewModel.followUser(user),
                  onUnfollow: () => viewModel.unfollowUser(user),
                  onTap: () => _navigateToProfile(user),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    return Consumer<FollowerListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingFollowing &&
            viewModel.following.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (viewModel.followingError != null &&
            viewModel.following.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(viewModel.followingError!),
                ElevatedButton(
                  onPressed:
                      () => viewModel.loadFollowing(
                        widget.args.userId,
                        refresh: true,
                      ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (viewModel.following.isEmpty) {
          return const Center(child: Text('Chưa theo dõi ai'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await viewModel.loadFollowing(
              widget.args.userId,
              refresh: true,
            );
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent &&
                  !viewModel.isLoadingMoreFollowing &&
                  viewModel.hasMoreFollowing) {
                viewModel.loadFollowing(widget.args.userId);
              }
              return false;
            },
            child: ListView.builder(
              itemCount:
                  viewModel.following.length +
                  (viewModel.isLoadingMoreFollowing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == viewModel.following.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final user = viewModel.following[index];
                return UserListItem(
                  user: user,
                  isFollowing: user.isFollowing ?? false,
                  onFollow: () => viewModel.followUser(user),
                  onUnfollow: () => viewModel.unfollowUser(user),
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
        arguments:
            user.username, // UserProfileScreen expects username string
      );
    }
  }
}
