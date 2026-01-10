# Theme

Thư mục này chứa **Theme Configuration** cho ứng dụng Twizzy.

## Mục đích
- Định nghĩa Light và Dark theme
- Theme tự động theo theme của thiết bị
- Logo dùng chung cho cả light và dark theme

## Cấu trúc

### `app_colors.dart`
Định nghĩa màu sắc cho Light và Dark theme:
- **Light Theme**: Nền trắng, chữ đen
- **Dark Theme**: Nền đen, chữ trắng
- **Common Colors**: Accent, error, success (dùng chung)

### `app_theme.dart`
Định nghĩa `ThemeData` cho cả Light và Dark theme:
- `AppTheme.lightTheme` - Light theme
- `AppTheme.darkTheme` - Dark theme

## Sử dụng

### Trong main.dart
```dart
import 'core/theme/app_theme.dart';

MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // Tự động theo system theme
  // ...
)
```

### Sử dụng theme trong widgets
```dart
// Lấy màu từ theme
Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

// Sử dụng text theme
Text(
  'Hello',
  style: Theme.of(context).textTheme.headlineLarge,
)
```

### Sử dụng AppColors trực tiếp
```dart
import 'core/theme/app_colors.dart';

Container(
  color: AppColors.lightBackground,
  child: Text(
    'Text',
    style: TextStyle(color: AppColors.lightText),
  ),
)
```

## Logo

Logo được định nghĩa trong `core/constants/asset_paths.dart`:
- `AssetPaths.logo` - Logo có chữ (`logo.png`)
- `AssetPaths.logoImage` - Logo chỉ có hình (`logo_image.png`)

### Sử dụng logo
```dart
// Sử dụng trực tiếp
Image.asset(AssetPaths.logo)
Image.asset(AssetPaths.logoImage)

// Hoặc sử dụng widget AppLogo
import 'widgets/common/app_logo.dart';

AppLogo(showText: true)  // Logo có chữ
AppLogo(showText: false) // Logo chỉ có hình
AppLogo(
  showText: true,
  width: 100,
  height: 100,
)
```

## Theme Colors

### Light Theme
- Background: Trắng (#FFFFFF)
- Text: Đen (#000000)
- Surface: Trắng (#FFFFFF)
- Divider: Xám nhạt (#EFF3F4)
- Accent: Xanh (#1DA1F2)

### Dark Theme
- Background: Đen (#000000)
- Text: Trắng (#FFFFFF)
- Surface: Xám đen (#16181C)
- Divider: Xám đậm (#2F3336)
- Accent: Xanh (#1DA1F2)

## Lưu ý

1. **Theme tự động**: App tự động theo theme của thiết bị (`ThemeMode.system`)
2. **Logo dùng chung**: Logo không thay đổi giữa light và dark theme
3. **Material 3**: Theme sử dụng Material 3 design
4. **Consistent colors**: Sử dụng `AppColors` để đảm bảo màu sắc nhất quán
