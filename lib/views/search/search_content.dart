import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../viewmodels/search/search_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/user/user_list_item.dart';
import '../../widgets/twizz/twizz_list.dart';
import '../../routes/route_names.dart';
import '../twizz/twizz_detail_screen.dart';

class SearchContent extends StatefulWidget {
  const SearchContent({super.key});

  @override
  State<SearchContent> createState() => _SearchContentState();
}

class _SearchContentState extends State<SearchContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController =
      TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(_onSearchChanged);

    // Clear search state when entering the search tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<SearchViewModel>(
        context,
        listen: false,
      );
      viewModel.clearSearch();
      _searchController.clear();
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final value = _searchController.text;
      final viewModel = Provider.of<SearchViewModel>(
        context,
        listen: false,
      );
      if (value != viewModel.query) {
        viewModel.search(value);
      }
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final viewModel = Provider.of<SearchViewModel>(
        context,
        listen: false,
      );
      final newTab = SearchTab.values[_tabController.index];
      viewModel.setTab(newTab);

      // Always refresh when switching tabs if query is not empty
      if (_searchController.text.trim().isNotEmpty) {
        viewModel.search(_searchController.text);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    final viewModel = Provider.of<SearchViewModel>(
      context,
      listen: false,
    );
    viewModel.search(value);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final viewModel = Provider.of<SearchViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUserId = authViewModel.currentUser?.id;

    // Sync search controller with viewmodel query if needed
    if (viewModel.query.isNotEmpty &&
        _searchController.text != viewModel.query) {
      _searchController.text = viewModel.query;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: themeData.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: _onSearch,
            decoration: InputDecoration(
              hintStyle: TextStyle(
                color: themeData.colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
              hintText: 'Tìm kiếm',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 2,
              ),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<bool>(
            icon: Icon(
              Icons.settings_outlined,
              color:
                  viewModel.isFollowOnly
                      ? themeData.colorScheme.primary
                      : null,
            ),
            onSelected: (value) {
              if (viewModel.isFollowOnly != value) {
                viewModel.toggleFollowOnly();
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: false,
                    child: Row(
                      children: [
                        if (!viewModel.isFollowOnly)
                          const Icon(Icons.check, size: 18),
                        const SizedBox(width: 8),
                        const Text('Tất cả'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: true,
                    child: Row(
                      children: [
                        if (viewModel.isFollowOnly)
                          const Icon(Icons.check, size: 18),
                        const SizedBox(width: 8),
                        const Text('Đang follow'),
                      ],
                    ),
                  ),
                ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabAlignment: TabAlignment.center,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Bài viết'),
            Tab(text: 'Người dùng'),
            Tab(text: 'Video'),
            Tab(text: 'Ảnh'),
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
          _buildTwizzsTab(
            viewModel,
            SearchTab.posts,
            currentUserId,
          ),
          _buildUsersTab(viewModel, currentUserId),
          _buildTwizzsTab(
            viewModel,
            SearchTab.videos,
            currentUserId,
          ),
          _buildTwizzsTab(
            viewModel,
            SearchTab.photos,
            currentUserId,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(
    SearchViewModel viewModel,
    String? currentUserId,
  ) {
    if (viewModel.isLoading(SearchTab.users) &&
        viewModel.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.users.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => viewModel.search(viewModel.query),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _buildEmptyState(
              'Không tìm thấy người dùng nào',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.search(viewModel.query),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200 &&
              viewModel.hasMore(SearchTab.users) &&
              !viewModel.isLoadingMore(SearchTab.users)) {
            viewModel.search(viewModel.query, isRefresh: false);
          }
          return false;
        },
        child: ListView.builder(
          itemCount:
              viewModel.users.length +
              (viewModel.isLoadingMore(SearchTab.users) ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == viewModel.users.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final user = viewModel.users[index];
            return UserListItem(
              user: user,
              isFollowing: user.isFollowing ?? false,
              onFollow:
                  user.id == currentUserId
                      ? null
                      : () => viewModel.followUser(user),
              onUnfollow:
                  user.id == currentUserId
                      ? null
                      : () => viewModel.unfollowUser(user),
              onTap: () => _navigateToProfile(user),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTwizzsTab(
    SearchViewModel viewModel,
    SearchTab tab,
    String? currentUserId,
  ) {
    final List<Twizz> list;
    if (tab == SearchTab.posts) {
      list = viewModel.posts;
    } else if (tab == SearchTab.videos) {
      list = viewModel.videos;
    } else {
      list = viewModel.photos;
    }

    if (viewModel.isLoading(tab) && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return TwizzList(
      twizzs: list,
      isLoading: viewModel.isLoadingMore(tab),
      hasMore: viewModel.hasMore(tab),
      currentUserId: currentUserId,
      onRefresh: () => viewModel.search(viewModel.query),
      onLoadMore:
          () => viewModel.search(
            viewModel.query,
            isRefresh: false,
          ),
      onLike: (t) => viewModel.toggleLike(t),
      onBookmark: (t) => viewModel.toggleBookmark(t),
      onComment:
          (t) => Navigator.pushNamed(
            context,
            RouteNames.twizzDetail,
            arguments: TwizzDetailScreenArgs(
              twizzId: t.id,
              focusComment: true,
            ),
          ),
      onQuote:
          (t) => Navigator.pushNamed(
            context,
            RouteNames.createTwizz,
            arguments: t,
          ),
      onDelete: (t) => viewModel.deleteTwizz(t),
      onTwizzTap:
          (t) => Navigator.pushNamed(
            context,
            RouteNames.twizzDetail,
            arguments: TwizzDetailScreenArgs(twizzId: t.id),
          ),
      onUserTap:
          (t) =>
              t.user != null
                  ? _navigateToProfile(t.user!)
                  : null,
      emptyWidget: _buildEmptyState(
        tab == SearchTab.posts
            ? 'Không tìm thấy bài viết nào'
            : tab == SearchTab.videos
            ? 'Không tìm thấy video nào'
            : 'Không tìm thấy ảnh nào',
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
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
