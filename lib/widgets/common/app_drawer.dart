import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twizzy_app/viewmodels/newsfeed/newsfeed_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';
import '../../core/utils/number_formatter.dart';

/// App Drawer
///
/// Drawer hiển thị thông tin user và menu
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // Drawer width: 80% của màn hình, tối đa 320px
    final drawerWidth = (screenWidth * 0.87).clamp(280.0, 350.0);
    return Drawer(
      width: drawerWidth,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(0),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header với avatar, tên, username
            Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {
                final user = authViewModel.currentUser;
                final name = user?.name ?? 'User';
                final username =
                    user?.username ?? user?.email ?? '';
                final email = user?.email ?? '';
                final avatar = user?.avatar;
                final followersCount = user?.followersCount ?? 0;
                final followingCount = user?.followingCount ?? 0;

                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 54,
                            height: 54,
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
                                          fontSize: 24,
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
                          // Tên và username
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: themeData
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
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
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Followers và Following count
                      Row(
                        children: [
                          // Following count
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  NumberFormatter.formatCount(
                                    followingCount,
                                  ),
                                  style: themeData
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Đang theo dõi',
                                  style: themeData
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.normal,
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
                          // Followers count
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  NumberFormatter.formatCount(
                                    followersCount,
                                  ),
                                  style: themeData
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Người theo dõi',
                                  style: themeData
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.normal,
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
                    ],
                  ),
                );
              },
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.person,
                    title: 'Hồ sơ',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(
                        context,
                      ).pushNamed(RouteNames.myProfile);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.favorite,
                    title: 'Đã thích',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to liked posts screen
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bookmark,
                    title: 'Dấu trang',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to bookmarks screen
                    },
                  ),

                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      final isLoading = authViewModel.isLoading;
                      return ListTile(
                        leading:
                            isLoading
                                ? SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<
                                          Color
                                        >(
                                          themeData
                                              .colorScheme
                                              .onSurface,
                                        ),
                                  ),
                                )
                                : Icon(
                                  Icons.logout,
                                  color:
                                      themeData
                                          .colorScheme
                                          .onSurface,
                                  size: 32,
                                ),
                        title: Text(
                          'Đăng xuất',
                          style: themeData
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color:
                                    themeData
                                        .colorScheme
                                        .onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        onTap:
                            isLoading
                                ? null
                                : () async {
                                  // Clear NewsFeedViewModel before logout
                                  final newsFeedViewModel =
                                      context
                                          .read<
                                            NewsFeedViewModel
                                          >();
                                  newsFeedViewModel.clear();
                                  // Logout
                                  await authViewModel.logout();
                                  if (context.mounted) {
                                    Navigator.of(
                                      context,
                                    ).pushNamedAndRemoveUntil(
                                      RouteNames.login,
                                      (route) => false,
                                    );
                                  }
                                },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final themeData = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: themeData.colorScheme.onSurface,
        size: 32,
      ),
      title: Text(
        title,
        style: themeData.textTheme.headlineSmall?.copyWith(
          color: themeData.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}
