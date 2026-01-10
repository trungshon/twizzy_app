# Core

Thư mục này chứa các **Core Components** - các thành phần cốt lõi của ứng dụng.

## Mục đích
- Chứa constants, theme, utils, và config
- Các thành phần được sử dụng xuyên suốt ứng dụng

## Cấu trúc

### `constants/`
- `api_constants.dart` - API URLs, base URL, endpoints
- `app_constants.dart` - App-wide constants (app name, version, etc.)
- `storage_keys.dart` - Keys cho FlutterSecureStorage
- `asset_paths.dart` - Paths cho assets (images, icons, fonts)

### `theme/`
- `app_theme.dart` - Theme configuration (ThemeData)
- `app_colors.dart` - Color palette
- `text_styles.dart` - Text styles (headline, body, caption, etc.)

### `utils/`
- `validators.dart` - Form validators (email, password, etc.)
- `formatters.dart` - Data formatters (date, currency, etc.)
- `helpers.dart` - Helper functions (utilities)

### `config/`
- `app_config.dart` - App configuration (environment, API URLs, etc.)

## Ví dụ

```dart
// core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:3000';
  static const String loginEndpoint = '/users/login';
  static const String registerEndpoint = '/users/register';
}

// core/constants/storage_keys.dart
class StorageKeys {
  // FlutterSecureStorage keys
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
}

// core/constants/asset_paths.dart
class AssetPaths {
  static const String logo = 'assets/images/logo.png';
  static const String logoDark = 'assets/images/logo_dark.png';
  static const String placeholderAvatar = 'assets/images/placeholder_avatar.png';
}

// Sử dụng trong code:
Image.asset(AssetPaths.logo)

// core/theme/app_colors.dart
class AppColors {
  static const Color primary = Color(0xFF6200EE);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
}

// core/utils/validators.dart
class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
```

## Lưu ý

### Storage Keys
- Sử dụng FlutterSecureStorage cho sensitive data (tokens, passwords)
- Định nghĩa tất cả keys trong `storage_keys.dart` để tránh hardcode
- Sử dụng constants thay vì string literals

### Constants
- Constants nên là `static const`
- Nhóm các constants liên quan vào cùng một class

### Theme
- Theme nên được định nghĩa một lần và sử dụng trong MaterialApp
- Sử dụng `Theme.of(context)` để access theme trong widgets

### Utils
- Utils nên là pure functions (không có side effects)
- Có thể test dễ dàng
- Tổ chức theo chức năng (validators, formatters, helpers)
