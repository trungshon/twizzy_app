import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/profile/user_profile_viewmodel.dart';
import '../../services/auth_service/auth_service.dart';
import '../../services/twizz_service/twizz_service.dart';
import '../../services/like_service/like_service.dart';
import '../../services/bookmark_service/bookmark_service.dart';
import '../../services/twizz_service/twizz_sync_service.dart';
import '../../widgets/twizz/twizz_list.dart';
import '../../core/utils/number_formatter.dart';
import '../../models/twizz/twizz_models.dart';
import '../../routes/route_names.dart';
import 'follower_list_screen.dart';

/// User Profile Screen
///
/// Hiển thị thông tin profile của người dùng khác
class UserProfileScreen extends StatelessWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => UserProfileViewModel(
            context.read<AuthService>(),
            context.read<TwizzService>(),
            context.read<LikeService>(),
            context.read<BookmarkService>(),
            context.read<TwizzSyncService>(),
          ),
      child: _UserProfileView(username: username),
    );
  }
}

class _UserProfileView extends StatefulWidget {
  final String username;

  const _UserProfileView({required this.username});

  @override
  State<_UserProfileView> createState() =>
      _UserProfileViewState();
}

class _UserProfileViewState extends State<_UserProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showTitle = false;

  final List<String> _tabs = [
    'Bài viết',
    'Đăng lại',
    'Trích dẫn',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<UserProfileViewModel>();
      viewModel.loadProfile(widget.username);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final viewModel = context.read<UserProfileViewModel>();
      viewModel.loadTwizzs(
        tabIndex: _tabController.index,
        refresh: true,
      );
    }
  }

  void _onScroll() {
    final showTitle =
        _scrollController.offset > 150 - kToolbarHeight;
    if (showTitle != _showTitle) {
      setState(() {
        _showTitle = showTitle;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return '';
    return 'Tham gia tháng ${date.month} năm ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final authViewModel = context.watch<AuthViewModel>();
    final currentUserId = authViewModel.currentUser?.id;

    return Consumer<UserProfileViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingProfile &&
            viewModel.user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (viewModel.profileError != null &&
            viewModel.user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
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
                    viewModel.profileError!,
                    style: themeData.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () => viewModel.loadProfile(
                          widget.username,
                        ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = viewModel.user;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Không tìm thấy người dùng'),
            ),
          );
        }

        final name = user.name;
        final username = user.username ?? '';
        final bio = user.bio ?? '';
        final followersCount = user.followersCount ?? 0;
        final followingCount = user.followingCount ?? 0;
        final isVerified = user.verify == 'Verified';
        final joinDate = user.createdAt;
        final coverPhoto = user.coverPhoto;
        final avatar = user.avatar;
        final location = user.location;
        final website = user.website;

        return Scaffold(
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Custom SliverAppBar với cover photo
                SliverAppBar(
                  expandedHeight: 150,
                  pinned: true,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: AnimatedOpacity(
                    opacity: _showTitle ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      name,
                      style: themeData.textTheme.titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background:
                        coverPhoto != null
                            ? Image.network(
                              coverPhoto,
                              fit: BoxFit.cover,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return Container(
                                  color: const Color(0xFF5C7A7A),
                                );
                              },
                            )
                            : Container(
                              color: const Color(0xFF5C7A7A),
                            ),
                  ),
                ),

                // Profile Info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Avatar and Action Buttons Row
                        Row(
                          children: [
                            // Avatar
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      themeData
                                          .scaffoldBackgroundColor,
                                  width: 4,
                                ),
                              ),
                              child:
                                  avatar != null
                                      ? CircleAvatar(
                                        radius: 40,
                                        backgroundImage:
                                            NetworkImage(avatar),
                                        onBackgroundImageError:
                                            (e, s) {},
                                      )
                                      : CircleAvatar(
                                        radius: 40,
                                        backgroundColor:
                                            themeData
                                                .colorScheme
                                                .secondary,
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight:
                                                FontWeight.bold,
                                            color:
                                                themeData
                                                    .colorScheme
                                                    .onSecondary,
                                          ),
                                        ),
                                      ),
                            ),
                            const Spacer(),
                            // Action Buttons (Follow & Message)
                            if (currentUserId != user.id) ...[
                              // Message button
                              OutlinedButton(
                                onPressed: () {
                                  // TODO: Navigate to chat
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(
                                    12,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.mail_outline,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Follow/Unfollow button
                              ElevatedButton(
                                onPressed:
                                    viewModel.isLoadingFollow
                                        ? null
                                        : () =>
                                            viewModel
                                                .toggleFollow(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      viewModel.isFollowing
                                          ? themeData
                                              .colorScheme
                                              .surface
                                          : themeData
                                              .colorScheme
                                              .primary,
                                  foregroundColor:
                                      viewModel.isFollowing
                                          ? themeData
                                              .colorScheme
                                              .onSurface
                                          : themeData
                                              .colorScheme
                                              .onPrimary,
                                  side:
                                      viewModel.isFollowing
                                          ? BorderSide(
                                            color:
                                                themeData
                                                    .colorScheme
                                                    .outline,
                                          )
                                          : null,
                                ),
                                child:
                                    viewModel.isLoadingFollow
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child:
                                              CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                        )
                                        : Text(
                                          viewModel.isFollowing
                                              ? 'Đang theo dõi'
                                              : 'Theo dõi',
                                        ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Name and Username
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: themeData
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 20,
                                color: Color(0xFF1DA1F2),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          style: themeData.textTheme.bodyMedium
                              ?.copyWith(
                                color: themeData
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),

                        // Bio
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            bio,
                            style:
                                themeData.textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Location and Website
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            if (location != null &&
                                location.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: themeData
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    location,
                                    style: themeData
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: themeData
                                              .colorScheme
                                              .onSurface
                                              .withValues(
                                                alpha: 0.6,
                                              ),
                                        ),
                                  ),
                                ],
                              ),
                            if (website != null &&
                                website.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.link,
                                    size: 16,
                                    color: Color(0xFF1DA1F2),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    website,
                                    style: themeData
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(
                                            0xFF1DA1F2,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Join Date
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: themeData
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatJoinDate(joinDate),
                              style: themeData
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: themeData
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Followers và Following
                        Row(
                          children: [
                            _buildStatItem(
                              context,
                              count: followingCount,
                              label: 'Đang theo dõi',
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    RouteNames.followerList,
                                    arguments:
                                        FollowerListScreenArgs(
                                          userId: user.id,
                                          username: user.name,
                                          initialTab: 1,
                                        ),
                                  ).then((_) {
                                    if (context.mounted) {
                                      context
                                          .read<
                                            UserProfileViewModel
                                          >()
                                          .loadProfile(
                                            widget.username,
                                          );
                                    }
                                  }),
                            ),
                            const SizedBox(width: 16),
                            _buildStatItem(
                              context,
                              count: followersCount,
                              label: 'Người theo dõi',
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    RouteNames.followerList,
                                    arguments:
                                        FollowerListScreenArgs(
                                          userId: user.id,
                                          username: user.name,
                                          initialTab: 0,
                                        ),
                                  ).then((_) {
                                    if (context.mounted) {
                                      context
                                          .read<
                                            UserProfileViewModel
                                          >()
                                          .loadProfile(
                                            widget.username,
                                          );
                                    }
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // TabBar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor:
                          themeData.colorScheme.onSurface,
                      unselectedLabelColor: themeData
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: themeData.dividerColor
                          .withValues(alpha: 0.2),
                      tabs:
                          _tabs
                              .map((tab) => Tab(text: tab))
                              .toList(),
                    ),
                    backgroundColor:
                        themeData.scaffoldBackgroundColor,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildTwizzTab(context, currentUserId),
                _buildRetwizzTab(context, currentUserId),
                _buildQuoteTwizzTab(context, currentUserId),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required int count,
    required String label,
    VoidCallback? onTap,
  }) {
    final themeData = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            NumberFormatter.formatCount(count),
            style: themeData.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
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

  Widget _buildTwizzTab(
    BuildContext context,
    String? currentUserId,
  ) {
    return Consumer<UserProfileViewModel>(
      builder: (context, viewModel, child) {
        final twizzs = viewModel.getTwizzs(
          UserProfileViewModel.tabTwizz,
        );
        final isLoading = viewModel.isLoading(
          UserProfileViewModel.tabTwizz,
        );
        final isLoadingMore = viewModel.isLoadingMore(
          UserProfileViewModel.tabTwizz,
        );
        final hasMore = viewModel.hasMore(
          UserProfileViewModel.tabTwizz,
        );
        final error = viewModel.getError(
          UserProfileViewModel.tabTwizz,
        );

        // Load data if not loaded yet
        if (!viewModel.hasLoaded(
              UserProfileViewModel.tabTwizz,
            ) &&
            !isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.loadTwizzs(
              tabIndex: UserProfileViewModel.tabTwizz,
            );
          });
        }

        if (isLoading && twizzs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (error != null && twizzs.isEmpty) {
          return _buildErrorTab(context, error, () {
            viewModel.loadTwizzs(
              tabIndex: UserProfileViewModel.tabTwizz,
              refresh: true,
            );
          });
        }

        return TwizzList(
          twizzs: twizzs,
          isLoading: isLoadingMore,
          hasMore: hasMore,
          currentUserId: currentUserId,
          onLoadMore:
              () => viewModel.loadMore(
                tabIndex: UserProfileViewModel.tabTwizz,
              ),
          onRefresh:
              () => viewModel.refresh(
                tabIndex: UserProfileViewModel.tabTwizz,
              ),
          onLike:
              (twizz) => viewModel.toggleLike(
                twizz,
                UserProfileViewModel.tabTwizz,
              ),
          onBookmark:
              (twizz) => viewModel.toggleBookmark(
                twizz,
                UserProfileViewModel.tabTwizz,
              ),
          onRetwizz:
              (twizz) => _handleRetwizz(
                context,
                viewModel,
                twizz,
                UserProfileViewModel.tabTwizz,
              ),
          onDelete: (twizz) => viewModel.deleteTwizz(twizz),
          emptyWidget: _buildEmptyTab(
            context,
            icon: Icons.article_outlined,
            title: 'Chưa có bài viết',
            subtitle: 'Người dùng chưa có bài viết nào',
          ),
        );
      },
    );
  }

  Widget _buildRetwizzTab(
    BuildContext context,
    String? currentUserId,
  ) {
    return Consumer<UserProfileViewModel>(
      builder: (context, viewModel, child) {
        final twizzs = viewModel.getTwizzs(
          UserProfileViewModel.tabRetwizz,
        );
        final isLoading = viewModel.isLoading(
          UserProfileViewModel.tabRetwizz,
        );
        final isLoadingMore = viewModel.isLoadingMore(
          UserProfileViewModel.tabRetwizz,
        );
        final hasMore = viewModel.hasMore(
          UserProfileViewModel.tabRetwizz,
        );
        final error = viewModel.getError(
          UserProfileViewModel.tabRetwizz,
        );

        if (!viewModel.hasLoaded(
              UserProfileViewModel.tabRetwizz,
            ) &&
            !isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.loadTwizzs(
              tabIndex: UserProfileViewModel.tabRetwizz,
            );
          });
        }

        if (isLoading && twizzs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (error != null && twizzs.isEmpty) {
          return _buildErrorTab(context, error, () {
            viewModel.loadTwizzs(
              tabIndex: UserProfileViewModel.tabRetwizz,
              refresh: true,
            );
          });
        }

        return TwizzList(
          twizzs: twizzs,
          isLoading: isLoadingMore,
          hasMore: hasMore,
          currentUserId: currentUserId,
          onLoadMore:
              () => viewModel.loadMore(
                tabIndex: UserProfileViewModel.tabRetwizz,
              ),
          onRefresh:
              () => viewModel.refresh(
                tabIndex: UserProfileViewModel.tabRetwizz,
              ),
          onLike:
              (twizz) => viewModel.toggleLike(
                twizz,
                UserProfileViewModel.tabRetwizz,
              ),
          onBookmark:
              (twizz) => viewModel.toggleBookmark(
                twizz,
                UserProfileViewModel.tabRetwizz,
              ),
          onRetwizz:
              (twizz) => _handleRetwizz(
                context,
                viewModel,
                twizz,
                UserProfileViewModel.tabRetwizz,
              ),
          onDelete: (twizz) => viewModel.deleteTwizz(twizz),
          emptyWidget: _buildEmptyTab(
            context,
            icon: Icons.repeat,
            title: 'Chưa có đăng lại',
            subtitle: 'Người dùng chưa đăng lại bài viết nào',
          ),
        );
      },
    );
  }

  Widget _buildQuoteTwizzTab(
    BuildContext context,
    String? currentUserId,
  ) {
    return Consumer<UserProfileViewModel>(
      builder: (context, viewModel, child) {
        final twizzs = viewModel.getTwizzs(
          UserProfileViewModel.tabQuoteTwizz,
        );
        final isLoading = viewModel.isLoading(
          UserProfileViewModel.tabQuoteTwizz,
        );
        final isLoadingMore = viewModel.isLoadingMore(
          UserProfileViewModel.tabQuoteTwizz,
        );
        final hasMore = viewModel.hasMore(
          UserProfileViewModel.tabQuoteTwizz,
        );
        final error = viewModel.getError(
          UserProfileViewModel.tabQuoteTwizz,
        );

        if (!viewModel.hasLoaded(
              UserProfileViewModel.tabQuoteTwizz,
            ) &&
            !isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.loadTwizzs(
              tabIndex: UserProfileViewModel.tabQuoteTwizz,
            );
          });
        }

        if (isLoading && twizzs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (error != null && twizzs.isEmpty) {
          return _buildErrorTab(context, error, () {
            viewModel.loadTwizzs(
              tabIndex: UserProfileViewModel.tabQuoteTwizz,
              refresh: true,
            );
          });
        }

        return TwizzList(
          twizzs: twizzs,
          isLoading: isLoadingMore,
          hasMore: hasMore,
          currentUserId: currentUserId,
          onLoadMore:
              () => viewModel.loadMore(
                tabIndex: UserProfileViewModel.tabQuoteTwizz,
              ),
          onRefresh:
              () => viewModel.refresh(
                tabIndex: UserProfileViewModel.tabQuoteTwizz,
              ),
          onLike:
              (twizz) => viewModel.toggleLike(
                twizz,
                UserProfileViewModel.tabQuoteTwizz,
              ),
          onBookmark:
              (twizz) => viewModel.toggleBookmark(
                twizz,
                UserProfileViewModel.tabQuoteTwizz,
              ),
          onRetwizz:
              (twizz) => _handleRetwizz(
                context,
                viewModel,
                twizz,
                UserProfileViewModel.tabQuoteTwizz,
              ),
          onDelete: (twizz) => viewModel.deleteTwizz(twizz),
          emptyWidget: _buildEmptyTab(
            context,
            icon: Icons.format_quote,
            title: 'Chưa có trích dẫn',
            subtitle: 'Người dùng chưa trích dẫn bài viết nào',
          ),
        );
      },
    );
  }

  void _handleRetwizz(
    BuildContext context,
    UserProfileViewModel viewModel,
    Twizz twizz,
    int tabIndex,
  ) async {
    final targetTwizz = twizz.parentTwizz ?? twizz;
    if (targetTwizz.isRetwizzed) {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Hủy đăng lại?'),
              content: const Text(
                'Bạn có chắc chắn muốn hủy đăng lại bài viết này?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Hủy đăng lại'),
                ),
              ],
            ),
      );

      if (confirm == true) {
        await viewModel.unretwizz(twizz, tabIndex);
      }
    } else {
      await viewModel.retwizz(twizz, tabIndex);
    }
  }

  Widget _buildErrorTab(
    BuildContext context,
    String error,
    VoidCallback onRetry,
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
            error,
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final themeData = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: themeData.colorScheme.onSurface.withValues(
              alpha: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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

/// SliverPersistentHeaderDelegate cho TabBar
class _SliverAppBarDelegate
    extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverAppBarDelegate(
    this._tabBar, {
    required this.backgroundColor,
  });

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
