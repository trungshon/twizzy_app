import 'package:flutter/material.dart';
import '../../services/local_storage/storage_service.dart';

/// Theme View Model
///
/// Quản lý trạng thái theme (Sáng, Tối, Hệ thống)
class ThemeViewModel extends ChangeNotifier {
  final StorageService _storageService;
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeViewModel(this._storageService) {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  /// Load theme mode từ storage
  Future<void> _loadThemeMode() async {
    final savedTheme = await _storageService.read(_themeKey);
    if (savedTheme != null) {
      if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  /// Cập nhật theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    String modeString = 'system';
    if (mode == ThemeMode.light) {
      modeString = 'light';
    } else if (mode == ThemeMode.dark) {
      modeString = 'dark';
    }

    await _storageService.write(_themeKey, modeString);
    notifyListeners();
  }
}
