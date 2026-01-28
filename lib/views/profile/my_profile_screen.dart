import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twizzy_app/widgets/twizz/twizz_list.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/profile/profile_viewmodel.dart';
import '../../core/utils/verification_utils.dart';
import '../../core/utils/number_formatter.dart';
import '../../routes/route_names.dart';
import 'follower_list_screen.dart';
import '../twizz/twizz_detail_screen.dart';

/// My Profile Screen
///
/// Hiển thị thông tin profile của người dùng hiện tại
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() =>
      _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showTitle = false;

  final List<String> _tabs = [
    'Bài viết',
    'Trích dẫn',
    'Đã thích',
    'Dấu trang',
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
      final authViewModel = context.read<AuthViewModel>();
      final profileViewModel = context.read<ProfileViewModel>();
      final userId = authViewModel.currentUser?.id;
      if (userId != null) {
        profileViewModel.loadTwizzs(
          userId: userId,
          tabIndex: ProfileViewModel.tabTwizz,
          refresh: true,
        );
      }
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final authViewModel = context.read<AuthViewModel>();
      final profileViewModel = context.read<ProfileViewModel>();
      final userId = authViewModel.currentUser?.id;
      if (userId != null) {
        profileViewModel.loadTwizzs(
          userId: userId,
          tabIndex: _tabController.index,
          refresh: true,
        );
      }
    }
  }

  void _onScroll() {
    // Hiện title khi scroll qua expandedHeight (150) - kToolbarHeight
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

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final user = authViewModel.currentUser;
        final name = user?.name ?? 'User';
        final username = user?.username ?? '';
        final email = user?.email ?? '';
        final bio = user?.bio ?? '';
        final followersCount = user?.followersCount ?? 0;
        final followingCount = user?.followingCount ?? 0;
        final isVerified = user?.verify == 'Verified';
        final joinDate = user?.createdAt;
        final coverPhoto = user?.coverPhoto;
        final avatar = user?.avatar;
        final location = user?.location;
        final website = user?.website;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: 'profile_fab',
            onPressed: () {
              Navigator.pushNamed(
                context,
                RouteNames.createTwizz,
              );
            },
            child: const Icon(Icons.add),
          ),
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
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: 0.5,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.editProfile,
                        ).then((updated) {
                          if (updated == true && mounted) {
                            // Refresh profile data
                            final authViewModel =
                                this.context
                                    .read<AuthViewModel>();
                            final profileViewModel =
                                this.context
                                    .read<ProfileViewModel>();
                            final userId =
                                authViewModel.currentUser?.id;

                            authViewModel.getMe();

                            // Reload current tab twizzs
                            if (userId != null) {
                              profileViewModel.loadTwizzs(
                                userId: userId,
                                tabIndex: _tabController.index,
                                refresh: true,
                              );
                            }
                          }
                        });
                      },
                    ),
                  ],
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
                  centerTitle: false,
                  forceElevated: _showTitle,
                  title:
                      _showTitle
                          ? Text(
                            '@$username',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  themeData
                                      .colorScheme
                                      .onSurface,
                            ),
                          )
                          : null,
                ),

                // Profile Info Section with Avatar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Row(
                          children: [
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
                                                .primary,
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
                                                    .onPrimary,
                                          ),
                                        ),
                                      ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Name và Verification Badge
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          style: themeData
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                              ),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                        ),
                                      ),
                                      if (isVerified) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF1DA1F2,
                                            ).withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                                  16,
                                                ),
                                          ),
                                          child: const Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.verified,
                                                size: 16,
                                                color: Color(
                                                  0xFF1DA1F2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else ...[
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () {
                                            VerificationUtils.showUnverifiedWarning(
                                              context,
                                              authViewModel
                                                  .currentUser
                                                  ?.email,
                                              message:
                                                  'Tài khoản của bạn chưa được xác nhận. Bạn có muốn xác nhận tài khoản không',
                                            );
                                          },
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                            decoration: BoxDecoration(
                                              color: themeData
                                                  .colorScheme
                                                  .error
                                                  .withValues(
                                                    alpha: 0.1,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    16,
                                                  ),
                                            ),
                                            child: Text(
                                              'Chưa xác nhận',
                                              style: themeData
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        themeData
                                                            .colorScheme
                                                            .error,
                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Username
                                  Text(
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    username.isNotEmpty
                                        ? '@$username'
                                        : email,
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
                            ),
                          ],
                        ),

                        // Bio
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            maxLines: 1,
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
                            // Location
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
                            // Website
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
                                          userId: user!.id,
                                          username: user.name,
                                          initialTab: 1,
                                        ),
                                  ).then((_) {
                                    if (context.mounted) {
                                      context
                                          .read<AuthViewModel>()
                                          .getMe();
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
                                          userId: user!.id,
                                          username: user.name,
                                          initialTab: 0,
                                        ),
                                  ).then((_) {
                                    if (context.mounted) {
                                      context
                                          .read<AuthViewModel>()
                                          .getMe();
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
                _buildTwizzTab(context),
                _buildQuoteTwizzTab(context),
                _buildLikedTab(context),
                _buildBookmarksTab(context),
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

  // Tab Contents - Using TwizzList widget
  Widget _buildTwizzTab(BuildContext context) {
    return Consumer2<ProfileViewModel, AuthViewModel>(
      builder: (
        context,
        profileViewModel,
        authViewModel,
        child,
      ) {
        final userId = authViewModel.currentUser?.id;
        if (userId == null) {
          return _buildEmptyTab(
            context,
            icon: Icons.article_outlined,
            title: 'Chưa có bài viết',
            subtitle: 'Bài viết của bạn sẽ hiển thị ở đây',
          );
        }

        final twizzs = profileViewModel.getTwizzs(
          ProfileViewModel.tabTwizz,
        );
        final isLoading = profileViewModel.isLoading(
          ProfileViewModel.tabTwizz,
        );
        final isLoadingMore = profileViewModel.isLoadingMore(
          ProfileViewModel.tabTwizz,
        );
        final hasMore = profileViewModel.hasMore(
          ProfileViewModel.tabTwizz,
        );
        final error = profileViewModel.getError(
          ProfileViewModel.tabTwizz,
        );

        if (isLoading && twizzs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (error != null && twizzs.isEmpty) {
          return _buildErrorTab(context, error, () {
            profileViewModel.loadTwizzs(
              userId: userId,
              tabIndex: ProfileViewModel.tabTwizz,
              refresh: true,
            );
          });
        }

        return TwizzList(
          twizzs: twizzs,
          isLoading: isLoadingMore,
          hasMore: hasMore,
          currentUserId: userId,
          onTwizzTap: (twizz) {
            Navigator.pushNamed(
              context,
              RouteNames.twizzDetail,
              arguments: TwizzDetailScreenArgs(twizz: twizz),
            );
          },
          onLoadMore:
              () => profileViewModel.loadMore(
                userId: userId,
                tabIndex: ProfileViewModel.tabTwizz,
              ),
          onRefresh:
              () => profileViewModel.refresh(
                userId: userId,
                tabIndex: ProfileViewModel.tabTwizz,
              ),
          onLike:
              (twizz) => profileViewModel.toggleLike(
                twizz,
                ProfileViewModel.tabTwizz,
              ),
          onBookmark:
              (twizz) => profileViewModel.toggleBookmark(
                twizz,
                ProfileViewModel.tabTwizz,
              ),
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
          onDelete:
              (twizz) => profileViewModel.deleteTwizz(twizz),
          emptyWidget: _buildEmptyTab(
            context,
            icon: Icons.article_outlined,
            title: 'Chưa có bài viết',
            subtitle: 'Bài viết của bạn sẽ hiển thị ở đây',
          ),
        );
      },
    );
  }

  Widget _buildQuoteTwizzTab(BuildContext context) {
    return Consumer2<ProfileViewModel, AuthViewModel>(
      builder: (
        context,
        profileViewModel,
        authViewModel,
        child,
      ) {
        final userId = authViewModel.currentUser?.id;
        if (userId == null) {
          return _buildEmptyTab(
            context,
            icon: Icons.format_quote,
            title: 'Chưa có trích dẫn',
            subtitle: 'Bài viết bạn trích dẫn sẽ hiển thị ở đây',
          );
        }

        final twizzs = profileViewModel.getTwizzs(
          ProfileViewModel.tabQuoteTwizz,
        );
        final isLoading = profileViewModel.isLoading(
          ProfileViewModel.tabQuoteTwizz,
        );
        final isLoadingMore = profileViewModel.isLoadingMore(
          ProfileViewModel.tabQuoteTwizz,
        );
        final hasMore = profileViewModel.hasMore(
          ProfileViewModel.tabQuoteTwizz,
        );
        final error = profileViewModel.getError(
          ProfileViewModel.tabQuoteTwizz,
        );

        if (isLoading && twizzs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (error != null && twizzs.isEmpty) {
          return _buildErrorTab(context, error, () {
            profileViewModel.loadTwizzs(
              userId: userId,
              tabIndex: ProfileViewModel.tabQuoteTwizz,
              refresh: true,
            );
          });
        }

        return TwizzList(
          twizzs: twizzs,
          isLoading: isLoadingMore,
          hasMore: hasMore,
          currentUserId: userId,
          onTwizzTap: (twizz) {
            Navigator.pushNamed(
              context,
              RouteNames.twizzDetail,
              arguments: TwizzDetailScreenArgs(twizz: twizz),
            );
          },
          onLoadMore:
              () => profileViewModel.loadMore(
                userId: userId,
                tabIndex: ProfileViewModel.tabQuoteTwizz,
              ),
          onRefresh:
              () => profileViewModel.refresh(
                userId: userId,
                tabIndex: ProfileViewModel.tabQuoteTwizz,
              ),
          onLike:
              (twizz) => profileViewModel.toggleLike(
                twizz,
                ProfileViewModel.tabQuoteTwizz,
              ),
          onBookmark:
              (twizz) => profileViewModel.toggleBookmark(
                twizz,
                ProfileViewModel.tabQuoteTwizz,
              ),
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
          onDelete:
              (twizz) => profileViewModel.deleteTwizz(twizz),
          emptyWidget: _buildEmptyTab(
            context,
            icon: Icons.format_quote,
            title: 'Chưa có trích dẫn',
            subtitle: 'Bài viết bạn trích dẫn sẽ hiển thị ở đây',
          ),
        );
      },
    );
  }

  Widget _buildLikedTab(BuildContext context) {
    return Consumer2<ProfileViewModel, AuthViewModel>(
      builder: (
        context,
        profileViewModel,
        authViewModel,
        child,
      ) {
        final userId = authViewModel.currentUser?.id;
        if (userId == null) {
          return _buildEmptyTab(
            context,
            icon: Icons.favorite_outline,
            title: 'Chưa có bài viết đã thích',
            subtitle: 'Bài viết bạn thích sẽ hiển thị ở đây',
          );
        }

        final twizzs = profileViewModel.getTwizzs(
          ProfileViewModel.tabLiked,
        );
        final isLoading = profileViewModel.isLoading(
          ProfileViewModel.tabLiked,
        );
        final isLoadingMore = profileViewModel.isLoadingMore(
          ProfileViewModel.tabLiked,
        );
        final hasMore = profileViewModel.hasMore(
          ProfileViewModel.tabLiked,
        );
        final error = profileViewModel.getError(
          ProfileViewModel.tabLiked,
        );

        if (isLoading && twizzs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (error != null && twizzs.isEmpty) {
          return _buildErrorTab(context, error, () {
            profileViewModel.loadTwizzs(
              userId: userId,
              tabIndex: ProfileViewModel.tabLiked,
              refresh: true,
            );
          });
        }

        return TwizzList(
          twizzs: twizzs,
          isLoading: isLoadingMore,
          hasMore: hasMore,
          currentUserId: userId,
          onTwizzTap: (twizz) {
            Navigator.pushNamed(
              context,
              RouteNames.twizzDetail,
              arguments: TwizzDetailScreenArgs(twizz: twizz),
            );
          },
          onLoadMore:
              () => profileViewModel.loadMore(
                userId: userId,
                tabIndex: ProfileViewModel.tabLiked,
              ),
          onRefresh:
              () => profileViewModel.refresh(
                userId: userId,
                tabIndex: ProfileViewModel.tabLiked,
              ),
          onLike:
              (twizz) => profileViewModel.toggleLike(
                twizz,
                ProfileViewModel.tabLiked,
              ),
          onBookmark:
              (twizz) => profileViewModel.toggleBookmark(
                twizz,
                ProfileViewModel.tabLiked,
              ),
          onQuote: (twizz) {
            Navigator.pushNamed(
              context,
              RouteNames.createTwizz,
              arguments: twizz,
            );
          },
          onDelete:
              (twizz) => profileViewModel.deleteTwizz(twizz),
          emptyWidget: _buildEmptyTab(
            context,
            icon: Icons.favorite_outline,
            title: 'Chưa có bài viết đã thích',
            subtitle: 'Bài viết bạn thích sẽ hiển thị ở đây',
          ),
        );
      },
    );
  }

  Widget _buildBookmarksTab(BuildContext context) {
    return Consumer2<ProfileViewModel, AuthViewModel>(
      builder: (
        context,
        profileViewModel,
        authViewModel,
        child,
      ) {
        final userId = authViewModel.currentUser?.id;
        if (userId == null) {
          return _buildEmptyTab(
            context,
            icon: Icons.bookmark_outline,
            title: 'Chưa có dấu trang',
            subtitle: 'Bài viết bạn lưu sẽ hiển thị ở đây',
          );
        }

        final twizzs = profileViewModel.getTwizzs(
          ProfileViewModel.tabBookmarked,
        );
        final isLoading = profileViewModel.isLoading(
          ProfileViewModel.tabBookmarked,
        );
        final isLoadingMore = profileViewModel.isLoadingMore(
          ProfileViewModel.tabBookmarked,
        );
        final hasMore = profileViewModel.hasMore(
          ProfileViewModel.tabBookmarked,
        );
        final error = profileViewModel.getError(
          ProfileViewModel.tabBookmarked,
        );

        if (isLoading && twizzs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (error != null && twizzs.isEmpty) {
          return _buildErrorTab(context, error, () {
            profileViewModel.loadTwizzs(
              userId: userId,
              tabIndex: ProfileViewModel.tabBookmarked,
              refresh: true,
            );
          });
        }

        return TwizzList(
          twizzs: twizzs,
          isLoading: isLoadingMore,
          hasMore: hasMore,
          currentUserId: userId,
          onTwizzTap: (twizz) {
            Navigator.pushNamed(
              context,
              RouteNames.twizzDetail,
              arguments: TwizzDetailScreenArgs(twizz: twizz),
            );
          },
          onLoadMore:
              () => profileViewModel.loadMore(
                userId: userId,
                tabIndex: ProfileViewModel.tabBookmarked,
              ),
          onRefresh:
              () => profileViewModel.refresh(
                userId: userId,
                tabIndex: ProfileViewModel.tabBookmarked,
              ),
          onLike:
              (twizz) => profileViewModel.toggleLike(
                twizz,
                ProfileViewModel.tabBookmarked,
              ),
          onBookmark:
              (twizz) => profileViewModel.toggleBookmark(
                twizz,
                ProfileViewModel.tabBookmarked,
              ),
          onQuote: (twizz) {
            Navigator.pushNamed(
              context,
              RouteNames.createTwizz,
              arguments: twizz,
            );
          },
          onDelete:
              (twizz) => profileViewModel.deleteTwizz(twizz),
          emptyWidget: _buildEmptyTab(
            context,
            icon: Icons.bookmark_outline,
            title: 'Chưa có dấu trang',
            subtitle: 'Bài viết bạn lưu sẽ hiển thị ở đây',
          ),
        );
      },
    );
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
