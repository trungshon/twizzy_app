import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/app_logo.dart';
import '../../routes/route_names.dart';
import 'for_you_tab.dart';
import 'following_tab.dart';

/// Home Content
///
/// Nội dung màn hình home với TabBar
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<FollowingTabState> _followingTabKey =
      GlobalKey<FollowingTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load user info khi màn hình được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      if (authViewModel.currentUser == null) {
        authViewModel.getMe();
      }
    });
  }

  /// Scroll to top of newsfeed
  void scrollToTop() {
    _followingTabKey.currentState?.scrollToTop();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final isDarkMode = themeData.brightness == Brightness.dark;
    return Theme(
      data: themeData.copyWith(
        drawerTheme: DrawerThemeData(
          scrimColor: themeData.colorScheme.onSurface.withValues(
            alpha: 0.1,
          ),
        ),
      ),
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          leading: Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
              final user = authViewModel.currentUser;
              final name = user?.name ?? 'User';
              final avatar = user?.avatar;
              return Builder(
                builder:
                    (context) => GestureDetector(
                      onTap:
                          () =>
                              Scaffold.of(context).openDrawer(),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child:
                            avatar != null
                                ? CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(
                                    avatar,
                                  ),
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
                                        ? name[0].toUpperCase()
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
                    ),
              );
            },
          ),
          title: AppLogo(
            showText: false,
            isDarkMode: isDarkMode,
            width: 56,
            height: 56,
          ),
          centerTitle: true,
          // TabBar với 2 tabs
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Đề xuất'),
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
          children: [
            const ForYouTab(),
            FollowingTab(key: _followingTabKey),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'home_fab',
          onPressed: () {
            Navigator.pushNamed(context, RouteNames.createTwizz);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
