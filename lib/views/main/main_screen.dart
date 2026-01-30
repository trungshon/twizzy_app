import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/main/main_viewmodel.dart';
import '../../viewmodels/newsfeed/newsfeed_viewmodel.dart';
import '../home/home_content.dart';
import '../search/search_content.dart';
import '../notifications/notifications_content.dart';
import '../chat/chat_content.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
import '../../viewmodels/notification/notification_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../core/utils/verification_utils.dart';

/// Main Screen
///
/// Màn hình chính quản lý BottomNavigationBar và các màn hình con
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<HomeContentState> _homeContentKey =
      GlobalKey<HomeContentState>();

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    // Initialize screens with key for HomeContent
    _screens.addAll([
      HomeContent(key: _homeContentKey),
      const SearchContent(),
      const NotificationsContent(),
      const ChatContent(),
    ]);
    // Luôn load lại newsfeed khi vào app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<NewsFeedViewModel>();
      viewModel.loadNewsFeed(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final mainViewModel = context.watch<MainViewModel>();

    return Scaffold(
      body: IndexedStack(
        index: mainViewModel.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: themeData.copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: BottomNavigationBar(
          currentIndex: mainViewModel.currentIndex,
          onTap: (index) {
            // Check if user is trying to access messages
            if (index == 3) {
              final authViewModel =
                  context.read<AuthViewModel>();
              if (!authViewModel.isVerified) {
                VerificationUtils.showUnverifiedWarning(
                  context,
                  authViewModel.currentUser?.email,
                );
                return;
              }
            }

            // Nếu đang ở home và tap lại home thì scroll lên đầu
            if (index == 0 && mainViewModel.currentIndex == 0) {
              _homeContentKey.currentState?.scrollToTop();
            }
            mainViewModel.setIndex(index);
          },
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: themeData.colorScheme.primary,
          unselectedItemColor: themeData.colorScheme.onSurface
              .withValues(alpha: 0.4),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              label: 'Trang chủ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 28),
              label: 'Tìm kiếm',
            ),
            BottomNavigationBarItem(
              icon: Consumer<NotificationViewModel>(
                builder: (context, viewModel, child) {
                  final unreadCount = viewModel.unreadCount;
                  return Badge(
                    label: Text(
                      unreadCount > 99
                          ? '99+'
                          : unreadCount.toString(),
                    ),
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: themeData.colorScheme.error,
                    child: const Icon(
                      Icons.notifications_outlined,
                      size: 28,
                    ),
                  );
                },
              ),
              label: 'Thông báo',
            ),
            BottomNavigationBarItem(
              icon: Consumer<ChatViewModel>(
                builder: (context, chatViewModel, child) {
                  final totalUnread =
                      chatViewModel.totalUnreadCount;
                  return Badge(
                    label: Text(
                      totalUnread > 99
                          ? '99+'
                          : totalUnread.toString(),
                    ),
                    isLabelVisible: totalUnread > 0,
                    backgroundColor: themeData.colorScheme.error,
                    child: const Icon(
                      Icons.mail_outline,
                      size: 28,
                    ),
                  );
                },
              ),
              label: 'Tin nhắn',
            ),
          ],
        ),
      ),
    );
  }
}
