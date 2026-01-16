import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../core/utils/number_formatter.dart';

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
    'Đăng lại',
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
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
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
                          Icons.search,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        // TODO: Search functionality
                      },
                    ),
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
                        // TODO: Navigate to edit profile
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
                          ? Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '@$username',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      themeData
                                          .colorScheme
                                          .onSurface,
                                ),
                              ),
                              Text(
                                '0 bài đăng',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeData
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Name và Verification Badge
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
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Username
                                  Text(
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
                            bio,
                            style:
                                themeData.textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 12),
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
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: themeData
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
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
                            ),
                            const SizedBox(width: 16),
                            _buildStatItem(
                              context,
                              count: followersCount,
                              label: 'Người theo dõi',
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
                _buildRetwizzTab(context),
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
  }) {
    final themeData = Theme.of(context);
    return Row(
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
    );
  }

  // Tab Contents
  Widget _buildTwizzTab(BuildContext context) {
    return _buildEmptyTab(
      context,
      icon: Icons.article_outlined,
      title: 'Chưa có bài viết',
      subtitle: 'Bài viết của bạn sẽ hiển thị ở đây',
    );
  }

  Widget _buildRetwizzTab(BuildContext context) {
    return _buildEmptyTab(
      context,
      icon: Icons.repeat,
      title: 'Chưa có đăng lại',
      subtitle: 'Bài viết bạn đăng lại sẽ hiển thị ở đây',
    );
  }

  Widget _buildQuoteTwizzTab(BuildContext context) {
    return _buildEmptyTab(
      context,
      icon: Icons.format_quote,
      title: 'Chưa có trích dẫn',
      subtitle: 'Bài viết bạn trích dẫn sẽ hiển thị ở đây',
    );
  }

  Widget _buildLikedTab(BuildContext context) {
    return _buildEmptyTab(
      context,
      icon: Icons.favorite_outline,
      title: 'Chưa có bài viết đã thích',
      subtitle: 'Bài viết bạn thích sẽ hiển thị ở đây',
    );
  }

  Widget _buildBookmarksTab(BuildContext context) {
    return _buildEmptyTab(
      context,
      icon: Icons.bookmark_outline,
      title: 'Chưa có dấu trang',
      subtitle: 'Bài viết bạn lưu sẽ hiển thị ở đây',
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
