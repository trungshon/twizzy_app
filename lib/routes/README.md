# Routes

Thư mục này chứa **Navigation & Routing** - quản lý điều hướng giữa các màn hình.

## Mục đích
- Định nghĩa các routes của ứng dụng
- Quản lý navigation giữa các màn hình
- Xử lý deep linking và navigation guards

## Cấu trúc
- `app_router.dart` - Định nghĩa routes và navigation logic
- `route_names.dart` - Tên các routes (constants)

## Ví dụ

```dart
// routes/route_names.dart
class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
}

// routes/app_router.dart
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => NotFoundScreen());
    }
  }
}
```

## Lưu ý
- Có thể sử dụng `go_router` package cho routing phức tạp hơn
- Xử lý authentication guards (redirect to login nếu chưa đăng nhập)
- Support deep linking
