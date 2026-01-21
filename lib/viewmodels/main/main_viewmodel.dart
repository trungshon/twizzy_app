import 'package:flutter/foundation.dart';

/// Main View Model
///
/// Quản lý trạng thái chung của ứng dụng, bao gồm index của BottomNavigationBar
class MainViewModel extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void goToSearch() {
    setIndex(1);
  }

  void goToHome() {
    setIndex(0);
  }

  void goToNotifications() {
    setIndex(2);
  }

  void goToMessages() {
    setIndex(3);
  }
}
