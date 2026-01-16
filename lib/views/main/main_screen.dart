import 'package:flutter/material.dart';
import '../home/home_content.dart';
import '../search/search_content.dart';
import '../notifications/notifications_content.dart';
import '../messages/messages_content.dart';

/// Main Screen
///
/// Màn hình chính quản lý BottomNavigationBar và các màn hình con
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeContent(),
    SearchContent(),
    NotificationsContent(),
    MessagesContent(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: themeData.copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: themeData.colorScheme.primary,
          unselectedItemColor: themeData.colorScheme.onSurface
              .withValues(alpha: 0.4),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 28),
              label: 'Tìm kiếm',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined, size: 28),
              label: 'Thông báo',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.chat_bubble_outline_outlined,
                size: 28,
              ),
              label: 'Tin nhắn',
            ),
          ],
        ),
      ),
    );
  }
}
